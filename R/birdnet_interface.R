# Place functions in this file that are directly related to implementing the functionality of the `birdnet` Python package.

# Import the necessary Python modules layzily in .onLoad
py_birdnet_models <- NULL
py_birdnet_utils <- NULL
py_birdnet_audio_based_prediction <- NULL
py_birdnet_location_based_prediction <- NULL
py_birdnet_types <- NULL
py_pathlib <- NULL
py_builtins <- NULL


#' Check the Installed birdnet Version
#'
#' This internal function checks if birdnet Python is installed and if the version matches the requirement.
#' If it is not available or if the versions do not match, issue a warning with instructions to update the package.
#'
#' @keywords internal
#' @return None. This function is called for its side effect of stopping execution if the wrong version is installed.
.check_birdnet_version <- function() {
  available_py_packages <- tryCatch(
    {
      reticulate::py_list_packages()
    },
    error = function() {
      NULL
    }
  )

  if (is.null(available_py_packages)) {
    message("No Python environment available. To install, use `install_birdnet()`.")
    return()
  }

  installed_birdnet_version <- tryCatch(
    {
      # we need to set `package` to NULL, to bin it to a variable. Otherwise R CMD check will throw a note "No visible binding for global variable 'package' "
      package <- NULL
      subset(available_py_packages, package == "birdnet")$version
    },
    error = function(e) {
      NULL
    }
  )

  if (is.null(installed_birdnet_version) ||
    length(installed_birdnet_version) == 0) {
    message("No version of birdnet found. To install, use `install_birdnet()`.")
    return()
  }

  if (installed_birdnet_version != .required_birdnet_version()) {
    warning(
      sprintf(
        "BirdNET version %s is installed, but %s is required. To update, use `install_birdnet()`.",
        installed_birdnet_version,
        .required_birdnet_version()
      )
    )
  }
}


#' Initialize birdnetR Package
#'
#' Sets up the Python environment and imports required modules when the birdnetR package is loaded.
#'
#' @param libname Name of the library being loaded.
#' @param pkgname Name of the package being loaded.
#' @param ... Additional arguments.
#' @noRd
.onLoad <- function(libname, pkgname, ...) {
  reticulate::configure_environment(pkgname)
  reticulate::use_virtualenv("r-birdnet", required = FALSE)

  # Use superassignment to update global reference to the Python packages
  py_birdnet_models <<- reticulate::import("birdnet.models",
    delay_load = list(before_load = function() .check_birdnet_version())
  )
  py_birdnet_utils <<- reticulate::import("birdnet.utils", delay_load = TRUE)
  py_birdnet_audio_based_prediction <<- reticulate::import("birdnet.audio_based_prediction", delay_load = TRUE)
  py_birdnet_location_based_prediction <<- reticulate::import("birdnet.location_based_prediction", delay_load = TRUE)
  py_birdnet_types <<- reticulate::import("birdnet.types", delay_load = TRUE)
  py_pathlib <<- reticulate::import("pathlib", delay_load = TRUE)
  py_builtins <<- reticulate::import_builtins(delay_load = TRUE)
}


#' Create a new BirdNET model object
#'
#' This function creates a new BirdNET model object by wrapping a Python model object and assigning
#' it a class and optional subclass. The model is created as an R object that can be interacted with
#' using R's S3 method dispatch.
#'
#' @param x A Python object representing the BirdNET model. This is typically a Python model
#' object created using the `reticulate` package.
#' @param ... Additional attributes to attach to the BirdNET model object.
#' @param subclass Character. An optional subclass name for the BirdNET model (e.g., "tflite_v2.4").
#' The subclass is combined with the base class `birdnet_model`.
#'
#' @return An S3 object of class `birdnet_model` (and any specified subclass) containing the Python model object
#' and any additional attributes passed in `...`.
#'
#' @keywords internal
#' @examplesIf interactive()
#' py_birdnet_models <- reticulate::import("birdnet.models")
#' tflite_model <- py_birdnet_models$v2m4$AudioModelV2M4TFLite()
#' birdnet_model <- new_birdnet_model(tflite_model, language = "en_us", version = "v2.4")
new_birdnet_model <- function(x, ..., subclass = character()) {
  stopifnot(reticulate::is_py_object(x)) # Ensure that the input is a valid Python object

  class_name <- "birdnet_model" # Base class name for all BirdNET models
  subclasse <- paste(class_name, subclass, sep = "_") # Create subclass by combining base class with user-provided subclass

  # Return an S3 object containing the Python model and additional attributes, with the specified class hierarchy
  structure(list("py_model" = x, ...), class = c(subclasse, "birdnet_model"))
}


#' Dynamically create a BirdNET model
#'
#' This function dynamically creates a BirdNET model based on the provided model name and version. It retrieves
#' the appropriate Python model constructor from the module map, evaluates the constructor, and returns a wrapped
#' BirdNET model object.
#'
#' @param model_name Character. The name of the model to create (e.g., "tflite", "protobuf").
#' @param version Character. The version of the model (e.g., "v2.4").
#' @param ... Additional arguments passed to the Python model constructor (e.g., `tflite_num_threads`, `language`).
#'
#' @return A BirdNET model object of class `birdnet_model` and its subclasses (e.g., "tflite_v2.4").
#' @keywords internal
#' @examplesIf interactive()
#' py_birdnet_models <- reticulate::import("birdnet.models")
#' birdnet_model <- model_factory("tflite", "v2.4", tflite_num_threads = 2, language = "en_us")
model_factory <- function(model_name, version, ...) {
  # Create module map using the specified version and base Python module
  module_map <- create_module_map(version, "py_birdnet_models")

  # Retrieve the model module path from the module map
  model_module <- get_element_from_module_map(module_map, "models", model_name)

  # Evaluate the Python model constructor dynamically
  model_constructor <- evaluate_python_path(model_module)

  # Try to create the Python model by passing additional arguments
  py_model <- tryCatch(
    model_constructor(...),
    error = function(e) {
      stop("Failed to initialize Python model: ", conditionMessage(e))
    }
  )

  # Create a subclass for the model: model_name_version is the specific subclass of model_name
  subclasses <- c(version, model_name)
  subclasses <- gsub(
    x = subclasses,
    pattern = "\\.",
    replacement = "_"
  )

  # Create and return the BirdNET model object with the subclasses
  # passing model_version adds a list element with the version of the model.
  new_birdnet_model(py_model,
    model_version = version,
    ...,
    subclass = subclasses
  )
}


#' @title Initialize a BirdNET Model
#'
#' @description
#'
#' The various function of the `birdnet_model_*` family are used to create and initialize diffent BirdNET models. Models will be downloaded if necessary.
#'
#' * [birdnet_model_tflite()]: creates a tflite-model used for species prediction from audio.
#' * [birdnet_model_custom()]: loads a custom model for species prediction from audio.
#' * [birdnet_model_protobuf()]: creates a protobuf model for species prediction from audio that can be run on the GPU (not yet implemented).
#' * [birdnet_model_meta()]: creates a meta model for species prediction from location and time.
#'
#'
#' @details
#' **Species Prediction from audio**
#'
#' Models created from [birdnet_model_tflite()], [birdnet_model_custom()], and [birdnet_model_protobuf()] can be used to predict species within an audio file using [predict_species_from_audio_file()]. \cr
#'
#' **Species prediction from location and time**
#'
#' The [birdnet_model_meta()] model can be used to predict species occurrence at a specific location and time of the year using [predict_species_at_location_and_time()].
#'
#' @param version character. The version of BirdNET to use (default is "v2.4", no other versions are currently supported).
#' @param language character. Specifies the language code to use for the model's text processing. The language must be one of the available languages supported by the BirdNET model.
#' @param tflite_num_threads integer. The number of threads to use for TensorFlow Lite operations. If NULL (default), the default threading behavior will be used.
#' Will be coerced to an integer if possible.
#'
#' @seealso [available_languages()] [predict_species_from_audio_file()] [predict_species_at_location_and_time()]
#' @return A BirdNET model object.
#' @examplesIf interactive()
#' # Create a TFLite BirdNET model with 2 threads and English (US) language
#' birdnet_model <- birdnet_model_tflite(version = "v2.4", language = "en_us", tflite_num_threads = 2)
#' @name birdnet_model_load
NULL
#> NULL

#' @rdname birdnet_model_load
#' @export
birdnet_model_tflite <- function(version = "v2.4",
                                 language = "en_us",
                                 tflite_num_threads = NULL) {
  # Validate tflite_num_threads: must be NULL or numeric (will be coerced to integer)
  if (!is.null(tflite_num_threads) && !is.numeric(tflite_num_threads)) {
    stop("tflite_num_threads must be a numeric value or NULL.")
  }

  # Coerce to integer if tflite_num_threads is provided and numeric
  tflite_num_threads <- if (!is.null(tflite_num_threads)) {
    as.integer(tflite_num_threads)
  } else {
    NULL
  }

  # Call the model factory to create and return the TFLite model
  model_factory(
    model_name = "tflite",
    version = version,
    tflite_num_threads = tflite_num_threads,
    language = language
  )
}

#' @rdname birdnet_model_load
#' @param classifier_folder character. Path to the folder containing the custom classifier.
#' @param classifier_name character. Name of the custom classifier.
#' @export
birdnet_model_custom <- function(version = "v2.4",
                                 classifier_folder,
                                 classifier_name,
                                 tflite_num_threads = NULL) {
  # Validate tflite_num_threads: must be NULL or numeric (will be coerced to integer)
  if (!is.null(tflite_num_threads) && !is.numeric(tflite_num_threads)) {
    stop("tflite_num_threads must be a numeric value or NULL.")
  }

  # Coerce to integer if tflite_num_threads is provided and numeric
  tflite_num_threads <- if (!is.null(tflite_num_threads)) {
    as.integer(tflite_num_threads)
  } else {
    NULL
  }

  # Call the model factory to create and return the Custom TFLite model
  model <- model_factory(
    model_name = "custom",
    version = version,
    py_pathlib$Path(classifier_folder),
    classifier_name,
    tflite_num_threads = tflite_num_threads
  )

  # Because classifier_folder and classifier_name need to be positional and cannot be named, we need to rename the
  # list elements
  names(model) <- c(
    "py_model",
    "model_version",
    "classifier_folder",
    "classifier_name",
    "tflite_num_threads"
  )
  model
}

#' @rdname birdnet_model_load
#' @export
birdnet_model_meta <- function(version = "v2.4",
                               language = "en_us",
                               tflite_num_threads = NULL) {
  # Validate tflite_num_threads: must be NULL or numeric (will be coerced to integer)
  if (!is.null(tflite_num_threads) && !is.numeric(tflite_num_threads)) {
    stop("tflite_num_threads must be a numeric value or NULL.")
  }

  # Coerce to integer if tflite_num_threads is provided and numeric
  tflite_num_threads <- if (!is.null(tflite_num_threads)) {
    as.integer(tflite_num_threads)
  } else {
    NULL
  }

  # Call the model factory to create and return the TFLite model
  model_factory(
    model_name = "meta",
    version = version,
    tflite_num_threads = tflite_num_threads,
    language = language
  )
}


#' @rdname birdnet_model_load
#' @param custom_device character. This parameter allows specifying a custom device on which computations should be performed. If `custom_device` is not specified (i.e., it has the default value None), the program will attempt to use a GPU (e.g., "/device:GPU:0") by default. If no GPU is available, it will fall back to using the CPU. By specifying a device string such as "/device:GPU:0" or "/device:CPU:0", the user can explicitly choose the device on which operations should be executed.
#' @note Currently, all models can only be executed on the CPU. GPU support is not yet available.
#' @export
birdnet_model_protobuf <- function(version = "v2.4",
                                   language = "en_us",
                                   custom_device = NULL) {
  # Call the model factory to create and return the Protobuf model
  model_factory(
    model_name = "protobuf",
    version = version,
    language = language,
    custom_device = custom_device
  )
}


#' Initialize the BirdNET Model (Deprecated)
#'
#' This function initializes the BirdNET model (v2.4). It is kept for backward compatibility and is deprecated.
#' Use [birdnet_model_tflite()] instead for model initialization.
#'
#' @param tflite_num_threads integer. The number of threads to use for TensorFlow Lite operations. If NULL (default), the default threading behavior will be used.
#'  Will be coerced to an integer if possible.
#' @param language Character string specifying the language code to use for the model's text processing. The language must be one of the available languages supported by the BirdNET model.
#' @note The `language` parameter must be one of the available languages returned by `available_languages()`.
#' @seealso [available_languages()] [birdnet_model_tflite()]
#' @return An instance of the BirdNET model.
#' @export
#' @note This function is kept for backward compatibility. Please use [birdnet_model_tflite()] instead.
init_model <- function(tflite_num_threads = NULL, language = "en_us") {
  .Deprecated("birdnet_model_tflite", package = "birdnetR")
  birdnet_model_tflite(
    version = "v2.4",
    language = language,
    tflite_num_threads = tflite_num_threads
  )
}



#' Get Available Languages for BirdNET Model
#'
#' Retrieve the available languages supported by a specific version of BirdNET.
#'
#' @param version character. The version of BirdNET to use (default is "v2.4", no other versions are currently supported).
#'
#' @return A sorted character vector containing the available language codes.
#' @examplesIf interactive()
#' available_languages("v2.4")
#' @export
available_languages <- function(version) {
  module_map <- create_module_map(version = version, "py_birdnet_models")
  available_languages_path <- get_element_from_module_map(module_map, "misc", "available_languages")
  py_object <- evaluate_python_path(available_languages_path)
  sort(py_builtins$list(py_object))
}


#' Get Path to a Labels File
#'
#' This function retrieves the file path to the BirdNET labels file on your system corresponding to a specified language.
#' This file contains all class labels supported by the BirdNET model.
#'
#'
#' @param model A BirdNET model object.
#' @param language character. Specifies the language code for which the labels path is returned.
#'                 The language must be one of the available languages supported by the BirdNET model.
#' @param ... Additional arguments passed to the method dispatch function.
#' @return A character string representing the file path to the labels file for the specified language.
#' @examplesIf interactive()
#' model <- birdnet_model_tflite(version = "v2.4")
#' labels_path(model, "fr")
#' @note The `language` parameter must be one of the available languages returned by `available_languages()`.
#' @seealso [available_languages()] [read_labels()]
#' @export
labels_path <- function(model, ...) {
  UseMethod("labels_path")
}

#' Helper function to retrieve the language path for a BirdNET model
#'
#' This function handles the common logic for retrieving the language path for a BirdNET model.
#' It validates the language, creates the necessary paths from the module map, and uses the appropriate
#' downloader to retrieve the path to the language file.
#'
#' @param model A BirdNET model object containing the version information.
#' @param language Character. The language code for which to retrieve the path (e.g., "en_us").
#' Must be one of the available languages for the given model version.
#' @param downloader_key Character. The key in the module map that specifies the downloader
#' to use (e.g., "downloader_tflite", "downloader_protobuf").
#' @param subfolder Character. The subfolder in which the language files are stored (e.g., "TFLite", "Protobuf").
#'
#' @return A character string representing the path to the language file.
#' @keywords internal
#' @examplesIf interactive()
#' model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
#' language_path <- get_language_path(model, "en_us", "downloader_tflite", "TFLite")
get_language_path <- function(model,
                              language,
                              downloader_key,
                              subfolder) {
  # Validate that the language is available for the given model version
  langs <- available_languages(model$model_version)

  if (!(language %in% langs)) {
    stop(paste("`language` must be one of", paste(langs, collapse = ", ")))
  }

  # Create module map and get the necessary paths
  module_map <- create_module_map(version = model$model_version, "py_birdnet_models")
  version_app_data_folder_path <- get_element_from_module_map(module_map, "misc", "version_app_data_folder")
  downloader <- get_element_from_module_map(module_map, "misc", downloader_key)

  # Evaluate the Python paths
  py_app_folder <- evaluate_python_path(version_app_data_folder_path)
  py_downloader <- evaluate_python_path(downloader)

  # Call the downloader with the specific subfolder and return the language path
  as.character(py_downloader(py_pathlib$Path(py_app_folder(), subfolder))$get_language_path(language))
}

#' @rdname labels_path
#' @description For a custom model, the path of the custom labels file is returned.
#' @export
#' @method labels_path birdnet_model_custom
labels_path.birdnet_model_custom <- function(model, ...) {
  file.path(
    model$classifier_folder,
    paste0(model$classifier_name, ".txt")
  )
}


#' @rdname labels_path
#' @export
#' @method labels_path birdnet_model_tflite
labels_path.birdnet_model_tflite <- function(model, language, ...) {
  get_language_path(model, language, "downloader_tflite", "TFLite")
}

#' @rdname labels_path
#' @export
#' @method labels_path birdnet_model_protobuf
labels_path.birdnet_model_protobuf <- function(model, language, ...) {
  get_language_path(model, language, "downloader_protobuf", "Protobuf")
}


#' Read species labels from a file
#'
#' This is a convenience function to read species labels from a file.
#'
#' @param species_file Path to species file.
#'
#' @return A vector with class labels e.g. c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
#' @export
#' @seealso [available_languages()] [labels_path()]
#' @examplesIf interactive()
#' # Read a custom species file
#' read_labels(system.file("extdata", "species_list.txt", package = "birdnetR"))
#'
#' # To access all class labels that are supported in your language,
#' # you can read in the respective label file
#' model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
#' labels_path <- labels_path(model, "fr")
#' species_list <- read_labels(labels_path)
#' head(species_list)
read_labels <- function(species_file) {
  species_file_path <- py_pathlib$Path(species_file)$expanduser()$resolve(TRUE)
  py_species_list <- py_birdnet_utils$get_species_from_file(species_file_path)
  py_species_list$items
}


#' Predict species within an audio file using a BirdNET model
#'
#' @description
#' Use a BirdNET model to predict species within an audio file. The model can be a TFLite model, a custom model, or a Protobuf model.
#'
#'
#' @details
#' Applying a sigmoid activation function (`apply_sigmoid=TRUE`) scales the unbound class output of the linear classifier ("logit score") to the range `0-1`.
#' This confidence score is a unitless, numeric expression of BirdNET’s “confidence” in its prediction (but not the probability of species presence).
#' Sigmoid sensitivity < 1 leads to more higher and lower scoring predictions, and a value > 1 leads to more intermediate-scoring predictions.
#'
#' For more information on BirdNET confidence scores, the sigmoid activation function, and a suggested workflow on how to convert confidence scores to probabilities, see Wood & Kahl, 2024.
#'
#' @references Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of BirdNET scores and other detector outputs. Journal of Ornithology. https://doi.org/10.1007/s10336-024-02144-5
#'
#' @param model A BirdNET model object. An instance of the BirdNET model (e.g., `birdnet_model_tflite`, `birdnet_model_protobuf`).
#' @param audio_file character. The path to the audio file.
#' @param min_confidence numeric. Minimum confidence threshold for predictions (default is 0.1).
#' @param batch_size integer. Number of audio samples to process in a batch (default is 1L).
#' @param chunk_overlap_s numeric. The overlap between audio chunks in seconds (default is 0). Must be in the interval \[0.0, 3.0\].
#' @param use_bandpass logical. Whether to apply a bandpass filter (default is TRUE).
#' @param bandpass_fmin,bandpass_fmax integer. Minimum and maximum frequencies for the bandpass filter (in Hz). Ignored if `use_bandpass` is FALSE (default is 0L to 15000L).
#' @param apply_sigmoid logical. Whether to apply a sigmoid function to the model output (default is TRUE).
#' @param sigmoid_sensitivity numeric. Sensitivity parameter for the sigmoid function (default is 1). Must be in the interval \[0.5, 1.5\]. Ignored if `apply_sigmoid` is FALSE.
#' @param filter_species NULL, a character vector of length greater than 0, or a list where each element is a single non-empty character string. Used to filter the predictions. If NULL (default), no filtering is applied.
#' @param keep_empty logical. Whether to include empty intervals in the output (default is TRUE).
#'
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`. Each row represents a single prediction.
#'
#' @seealso [`read_labels()`] for more details on species filtering.
#' @export
#' @seealso [`predict_species_from_audio_file.birdnet_model`]
#' @examplesIf interactive()
#' library(birdnetR)
#'
#' model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
#' predictions <- predict_species_from_audio_file(model, "path/to/audio.wav", min_confidence = 0.2)
predict_species_from_audio_file <- function(model,
                                            audio_file,
                                            min_confidence = 0.1,
                                            batch_size = 1L,
                                            chunk_overlap_s = 0,
                                            use_bandpass = TRUE,
                                            bandpass_fmin = 0L,
                                            bandpass_fmax = 15000L,
                                            apply_sigmoid = TRUE,
                                            sigmoid_sensitivity = 1,
                                            filter_species = NULL,
                                            keep_empty = TRUE) {
  UseMethod("predict_species_from_audio_file")
}

#' @rdname predict_species_from_audio_file
#' @method predict_species_from_audio_file birdnet_model
#' @export
predict_species_from_audio_file.birdnet_model <- function(model,
                                                          audio_file,
                                                          min_confidence = 0.1,
                                                          batch_size = 1L,
                                                          chunk_overlap_s = 0,
                                                          use_bandpass = TRUE,
                                                          bandpass_fmin = 0L,
                                                          bandpass_fmax = 15000L,
                                                          apply_sigmoid = TRUE,
                                                          sigmoid_sensitivity = 1,
                                                          filter_species = NULL,
                                                          keep_empty = TRUE) {
  # Check argument types for better error messages
  stopifnot(is.list(model))
  stopifnot(is.character(audio_file))
  stopifnot(is.numeric(min_confidence))
  stopifnot(is.integer(batch_size))
  stopifnot(is.logical(use_bandpass))
  stopifnot(is.integer(bandpass_fmin))
  stopifnot(is.integer(bandpass_fmax))
  stopifnot(is.logical(apply_sigmoid))
  stopifnot(is.numeric(sigmoid_sensitivity))
  stopifnot(is.logical(keep_empty))

  # Handle species filter
  if (!is.null(filter_species)) {
    stopifnot(
      "`filter_species` must be NULL, a character vector of length greater than 0 or a list where each element is a single non-empty character string." =
        is_valid_species_list(filter_species)
    )

    if (is.character(filter_species) && length(filter_species) == 1) {
      filter_species <- list(filter_species)
    }
    filter_species <- py_builtins$set(filter_species)
  }

  # Convert path to a Python Path object
  audio_file <- py_pathlib$Path(audio_file)$expanduser()$resolve(TRUE)

  # Main function logic
  predictions_gen <- py_birdnet_audio_based_prediction$predict_species_within_audio_file(
    audio_file,
    min_confidence = min_confidence,
    batch_size = batch_size,
    chunk_overlap_s = chunk_overlap_s,
    use_bandpass = use_bandpass,
    bandpass_fmin = bandpass_fmin,
    bandpass_fmax = bandpass_fmax,
    apply_sigmoid = apply_sigmoid,
    sigmoid_sensitivity = sigmoid_sensitivity,
    species_filter = filter_species,
    custom_model = model$py_model
  )

  predictions <- py_birdnet_types$SpeciesPredictions(predictions_gen)
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
#' @param model birdnet_model_meta. An instance of the BirdNET model returned by [`birdnet_model_meta()`].
#' @param latitude numeric. The latitude of the location for species prediction. Must be in the interval \[-90.0, 90.0\].
#' @param longitude numeric. The longitude of the location for species prediction. Must be in the interval \[-180.0, 180.0\].
#' @param week integer. The week of the year for which to predict species. Must be in the interval \[1, 48\] if specified. If NULL, predictions are not limited to a specific week.
#' @param min_confidence numeric. Minimum confidence threshold for predictions to be considered valid. Must be in the interval \[0, 1.0).
#'
#' @return A data frame with columns: `label`, `confidence`. Each row represents a predicted species, with the `confidence` indicating the likelihood of the species being present at the specified location and time.
#' @export
#' @examplesIf interactive()
#' # Predict species in Chemnitz, Germany, that are present all year round
#' model <- birdnet_model_meta(language = "de")
#' predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231)
predict_species_at_location_and_time <- function(model,
                                                 latitude,
                                                 longitude,
                                                 week = NULL,
                                                 min_confidence = 0.03) {
  UseMethod("predict_species_at_location_and_time")
}

#' @rdname predict_species_at_location_and_time
#' @export
#' @method predict_species_at_location_and_time birdnet_model_meta
predict_species_at_location_and_time.birdnet_model_meta <- function(model,
                                                                    latitude,
                                                                    longitude,
                                                                    week = NULL,
                                                                    min_confidence = 0.03) {
  stopifnot(is.list(model))
  stopifnot(inherits(model, "birdnet_model_meta"))

  predictions <- py_birdnet_location_based_prediction$predict_species_at_location_and_time(
    latitude,
    longitude,
    week = week,
    min_confidence = min_confidence,
    custom_model = model$py_model
  )

  data.frame(
    label = names(predictions),
    confidence = unlist(predictions),
    row.names = NULL
  )
}
