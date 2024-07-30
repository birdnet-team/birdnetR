# Place functions in this file that are directly related to implementing the functionality of the `birdnet` Python package.



# Import the necessary Python modules layzily
py_birdnet <- NULL
py_pathlib <- NULL


#' Initialize BirdNET-R Package
#'
#' This function is executed when the BirdNET-R package is loaded. It sets up the Python environment using the `reticulate` package, ensuring that the necessary Python dependencies are available. The function configures the Python virtual environment named `r-birdnet` and imports the required Python modules, including `birdnet.models` and `pathlib`.
#'
#' @param libname The name of the library currently being loaded.
#' @param pkgname The name of the package currently being loaded.
#' @param ... Additional arguments passed to the function.
#' @noRd
.onLoad <- function(libname, pkgname, ...) {
  reticulate::configure_environment(pkgname)
  reticulate::use_virtualenv("r-birdnet", required = FALSE)

  # use superassignment to update global reference to the python packages
  py_birdnet <<-
    reticulate::import("birdnet.models", delay_load = TRUE)
  py_pathlib <<- reticulate::import("pathlib", delay_load = TRUE)
}


#' Initialize the BirdNET Model
#'
#' This function initializes the BirdNET model (v2.4).
#'
#' @param tflite_num_threads integer. The number of threads to use for TensorFlow Lite operations. If NULL (default), the default threading behavior will be used.
#'  Will be coerced to an integer if possible.
#' @param language  The language to use for the model's text processing. Must be one of the following available languages:
#' "en_us", "en_uk", "sv", "da", "hu", "th", "pt", "fr", "cs", "af", "uk", "it", "ja", "sl", "pl", "ko", "es", "de", "tr", "ru", "no", "sk", "ar", "fi", "ro", "nl", "zh".
#'
#' @return An instance of the BirdNET model.
#' @export
init_model <-
  function(tflite_num_threads = NULL,
           language = "en_us") {
    stopifnot(is.integer(tflite_num_threads))
    # Other Value Errors (e.g. unsupported language) are handled by the python package

    model <-
      py_birdnet$ModelV2M4(tflite_num_threads = tflite_num_threads, language = language)
    return(model)
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
#' @param bandpass_fmin,bandpass_fmax numeric. Minimum/Maximumfrequency for the bandpass filter (in Hz). Ignored if `use_bandpass` is False.
#' @param apply_sigmoid logical. Whether to apply a sigmoid function to the model output.
#' @param sigmoid_sensitivity numeric. Sensitivity parameter for the sigmoid function. Must be in the interval 0.5 - 1.5. Ignored if `apply_sigmoid` is False.
#' @param filter_species character or NULL. A set of species to filter the predictions. If NULL, no filtering is applied.
#' @param file_splitting_duration_s numeric. Duration in seconds for splitting the audio file into smaller segments for processing.
#' @param keep_empty logical. Whether to include empty intervals in the output.
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`.
#'   Each row represents a single prediction.
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
  # Check argument types
  stopifnot(inherits(model, "birdnet.models.model_v2m4.ModelV2M4"))
  stopifnot(is.character(audio_file))
  stopifnot(is.numeric(min_confidence))
  stopifnot(is.integer(batch_size))
  stopifnot(is.logical(use_bandpass))
  stopifnot(is.integer(bandpass_fmin))
  stopifnot(is.integer(bandpass_fmax))
  stopifnot(is.logical(apply_sigmoid))
  stopifnot(is.numeric(sigmoid_sensitivity))
  stopifnot(is.null(filter_species) || is.character(filter_species))
  stopifnot(is.numeric(file_splitting_duration_s))
  stopifnot(is.logical(keep_empty))

  # Main function logic
  audio_file <- py_pathlib$Path(normalizePath(audio_file))
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
