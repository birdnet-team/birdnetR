# Place functions in this file that are directly related to implementing the functionality of the `birdnet` Python package.



# Import the necessary Python modules layzily
py_birdnet_models <- NULL
py_birdnet_utils <- NULL
py_pathlib <- NULL
py_builtins <- NULL


#' Initialize birdnetR Package
#'
#' This function is executed when the birdnetR package is loaded. It sets up the Python environment using the `reticulate` package, ensuring that the necessary Python dependencies are available. The function configures the Python virtual environment named `r-birdnet` and imports the required Python modules, including `birdnet.models` and `pathlib`.
#'
#' @param libname The name of the library currently being loaded.
#' @param pkgname The name of the package currently being loaded.
#' @param ... Additional arguments passed to the function.
#' @noRd
.onLoad <- function(libname, pkgname, ...) {
  reticulate::configure_environment(pkgname)
  reticulate::use_virtualenv("r-birdnet", required = FALSE)

  # use superassignment to update global reference to the python packages
  py_birdnet_models <<-
    reticulate::import("birdnet.models", delay_load = TRUE)
  py_birdnet_utils <<-
    reticulate::import("birdnet.utils", delay_load = TRUE)
  py_pathlib <<- reticulate::import("pathlib", delay_load = TRUE)
  # Import Python built-in functions and types
  py_builtins <<- import_builtins(delay_load = TRUE)
}



#' Get Available Languages for BirdNET Model
#'
#' Retrieve the available languages supported by the BirdNET model.
#'
#' @return A sorted character vector containing the available language codes.
#' @examples
#'   available_languages()
#' @export
available_languages <- function() {
  if (is.null(py_birdnet_models)) {
    stop("The birdnet.models module has not been loaded. Ensure the Python environment is configured correctly.")
  }
  sort(py_builtins$list(py_birdnet_models$model_v2m4$AVAILABLE_LANGUAGES))
}


#' Initialize the BirdNET Model
#'
#' This function initializes the BirdNET model (v2.4).
#'
#' @param tflite_num_threads integer. The number of threads to use for TensorFlow Lite operations. If NULL (default), the default threading behavior will be used.
#'  Will be coerced to an integer if possible.
#' @param language  A character string specifying the language code to use for the model's text processing. The language must be one of the available languages supported by the BirdNET model.
#' @note The `language` parameter must be one of the available languages returned by `available_languages()`.
#' @seealso [available_languages()]
#' @return An instance of the BirdNET model.
#' @export
init_model <-
  function(tflite_num_threads = NULL,
           language = "en_us") {
    stopifnot(is.integer(tflite_num_threads) |
      is.null(tflite_num_threads))
    # Other Value Errors (e.g. unsupported language) are handled by the python package

    model <-
      py_birdnet_models$ModelV2M4(tflite_num_threads = tflite_num_threads, language = language)
    return(model)
  }


#' Get Path to BirdNET Labels File for a Specified Language
#'
#' This function retrieves the file path to the BirdNET labels file on your system corresponding to a specified language.
#' This file contains all class labels supported by the BirdNET model.
#'
#' @param language A character string specifying the language code for which the labels path is requested.
#'                 The language must be one of the available languages supported by the BirdNET model.
#' @return A character string representing the file path to the labels file for the specified language.
#' @examples
#'   get_labels_path("en_us")
#' @note The `language` parameter must be one of the available languages returned by `available_languages()`.
#' @seealso [available_languages()]
#' @export
get_labels_path <- function(language) {
  if (!(language %in% available_languages()))  {
    stop(paste("`language` must be one of", paste(available_languages(), collapse = ", ")))
  }

  birdnet_app_data <- py_birdnet_utils$get_birdnet_app_data_folder()
  downloader <- py_birdnet_models$model_v2m4$Downloader(birdnet_app_data)
  as.character(downloader$get_language_path(language))
}


#' Read species labels from a file
#'
#' This is a convenience function to read species labels from a file.
#'
#' @param species_file Path to species file.
#'
#' @return A vector with class labels e.g. c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
#' @export
#' @seealso [available_languages()] [get_labels_path()]
#' @examples
#' # Read a custom species file
#' get_species_from_file(system.file("extdata", "species_list.txt", package = "birdnetR"))
#'
#' # To access all class labels that are supported in your language,
#' # you can read in the respective label file
#' labels_path <- get_labels_path("fr")
#' species_list <- get_species_from_file(labels_path)
#' head(species_list)
get_species_from_file <- function(species_file) {
  species_file_path <- py_pathlib$Path(species_file)$expanduser()$resolve(TRUE)
  py_species_list <- py_birdnet_utils$get_species_from_file(species_file_path)
  py_species_list$items
}

#' Predict Species Within an Audio File
#'
#' This function predicts species within an audio file using the BirdNET model.
#'
#' @details
#' Applying a sigmoid activation function, (`apply_sigmoid=True`) scales the unbound class output of the linear classifier ("logit score") to the range `0-1`.
#' This confidence score is a unitless, numeric expression of BirdNET’s “confidence” in its prediction (but not the probability of species presence).
#' Sigmoid sensitivity < 1 leads to more higher and lower scoring predictions and a value > 1 leads to more intermediate-scoring predictions.
#'
#' For more information on BirdNET confidence scores, the sigmoid activation function and a suggested workflow on how to convert confidence scores to probabilities, see Wood & Kahl, 2024
#'
#' @references Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of BirdNET scores and other detector outputs. Journal of Ornithology. https://doi.org/10.1007/s10336-024-02144-5
#'
#' @param model BirdNETModel. An instance of the BirdNET model returned by [`init_model()`].
#' @param audio_file character. The path to the audio file.
#' @param min_confidence numeric. Minimum confidence threshold for predictions.
#' @param batch_size integer. Number of audio samples to process in a batch.
#' @param use_bandpass logical. Whether to apply a bandpass filter.
#' @param bandpass_fmin,bandpass_fmax numeric. Minimum/Maximum frequency for the bandpass filter (in Hz). Ignored if `use_bandpass` is False.
#' @param apply_sigmoid logical. Whether to apply a sigmoid function to the model output.
#' @param sigmoid_sensitivity numeric. Sensitivity parameter for the sigmoid function. Must be in the interval 0.5 - 1.5. Ignored if `apply_sigmoid` is False.
#' @param filter_species NULL, a character vector of length greater than 0 or a list where each element is a single non-empty character string. Used to filter the predictions. If NULL, no filtering is applied. See [`get_species_from_file()`] for more details.
#' @param file_splitting_duration_s numeric. Duration in seconds for splitting the audio file into smaller segments for processing.
#' @param keep_empty logical. Whether to include empty intervals in the output.
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`.
#'   Each row represents a single prediction.
#' @seealso [`init_model()`] [`get_species_from_file()`]
#' @export
predict_species <- function(model,
                            audio_file = system.file("extdata", "soundscape.wav", package = "birdnetR"),
                            min_confidence = 0.1,
                            batch_size = 1L,
                            use_bandpass = TRUE,
                            bandpass_fmin = 0L,
                            bandpass_fmax = 15000L,
                            apply_sigmoid = TRUE,
                            sigmoid_sensitivity = 1,
                            filter_species = NULL,
                            file_splitting_duration_s = 600,
                            keep_empty = TRUE) {
  # Check argument types. This ist mostly in order to return better error messages
  stopifnot(inherits(model, "birdnet.models.model_v2m4.ModelV2M4"))
  stopifnot(is.character(audio_file))
  stopifnot(is.numeric(min_confidence))
  stopifnot(is.integer(batch_size))
  stopifnot(is.logical(use_bandpass))
  stopifnot(is.integer(bandpass_fmin))
  stopifnot(is.integer(bandpass_fmax))
  stopifnot(is.logical(apply_sigmoid))
  stopifnot(is.numeric(sigmoid_sensitivity))
  stopifnot(is.numeric(file_splitting_duration_s))
  stopifnot(is.logical(keep_empty))
  if (!is.null(filter_species)) {
    stopifnot(
      "`filter_species` must be NULL, a character vector of length greater than 0 or a list where each element is a single non-empty character string." =
        is_valid_species_list(filter_species)
    )

    # if not NULL, convert filter_species to a python set
    # Wrap single character strings in a list if necessary, otherwise `set` splits the string into individual characters
    if (is.character(filter_species) && length(filter_species) == 1) {
      filter_species <- list(filter_species)
    }
    filter_species <- py_builtins$set(filter_species)
  }

  # Main function logic
  audio_file <- py_pathlib$Path(audio_file)$expanduser()$resolve(TRUE)

  predictions <- model$predict_species_within_audio_file(
    audio_file,
    min_confidence = min_confidence,
    batch_size = batch_size,
    use_bandpass = use_bandpass,
    bandpass_fmin = bandpass_fmin,
    bandpass_fmax = bandpass_fmax,
    apply_sigmoid = apply_sigmoid,
    sigmoid_sensitivity = sigmoid_sensitivity,
    filter_species = filter_species,
    file_splitting_duration_s = file_splitting_duration_s
  )
  predictions_to_df(predictions, keep_empty = keep_empty)
}

#' Predict species for a given location and time
#'
#' Uses the BirdNET Species Range Model to estimate the presence of bird species at a specified location and time of year.
#'
#' @details
#' The BirdNET Species Range Model leverages eBird checklist frequency data to estimate the probability of bird species occurrences based on latitude, longitude, and time of year.
#' It integrates actual observations and expert-curated data, making it adaptable to regions with varying levels of data availability.
#' The model employs circular embeddings and a classifier to predict species presence and migration patterns, achieving higher accuracy in data-rich regions and lower accuracy in underrepresented areas like parts of Africa and Asia.
#' For more details, you can view the full discussion here:
#' https://github.com/kahst/BirdNET-Analyzer/discussions/234
#'
#' @param model BirdNETModel. An instance of the BirdNET model returned by [`init_model()`].
#' @param latitude numeric. The latitude of the location for species prediction. Must be in the interval \[-90.0, 90.0\].
#' @param longitude numeric. The longitude of the location for species prediction. Must be in the interval \[-180.0, 180.0\].
#' @param week integer. The week of the year for which to predict species. Must be in the interval \[1, 48\] if specified. If NULL, predictions are not limited to a specific week.
#' @param min_confidence numeric. Minimum confidence threshold for predictions to be considered valid. Must be in the interval \[0, 1.0).
#'
#' @return A data frame with columns: `label`, `confidence`. Each row represents a predicted species, with the `confidence` indicating the likelihood of the species being present at the specified location and time.
#' @export
#'
#' @examples
#' # Predict species in Chemnitz, Germany, that are present all year round
#' model <- init_model(language = "de")
#' predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231)
predict_species_at_location_and_time <- function(model,
                                                 latitude,
                                                 longitude,
                                                 week = NULL,
                                                 min_confidence = 0.03) {

  stopifnot(inherits(model, "birdnet.models.model_v2m4.ModelV2M4"))

  predictions <- model$predict_species_at_location_and_time(latitude,
    longitude,
    week = week,
    min_confidence = min_confidence
  )
  data.frame(
    label = names(predictions),
    confidence = unlist(predictions),
    row.names = NULL
  )
}
