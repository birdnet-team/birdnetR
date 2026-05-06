# Include package name in class

#> How to create a class
#> 1. Low-level constructor
#> 2. Validator (optional if simpel)
#> 3. helper for others to create a class (optional if for internal use only)
#>
#> Class Constructor
#> 1. should be called "new_myclass()"
#> 2. have one argument for the base object
library(reticulate)
library(birdnetR)
use_virtualenv("r-birdnet")

source("R/module_map.R")

py_birdnet_models <- reticulate::import("birdnet.models")
py_birdnet_audio_based_prediction <- reticulate::import("birdnet.audio_based_prediction", delay_load = TRUE)
py_builtins <- import_builtins(delay_load = TRUE)
py_pathlib <- reticulate::import("pathlib", delay_load = TRUE)
py_birdnet_types <- reticulate::import("birdnet.types", delay_load = TRUE)


predict_species_from_audio_file <- function(model, audio_file, ...) {
  UseMethod("predict_species_from_audio_file")
}

predict_species_from_audio_file.birdnet_model <- function(
    model,
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

  # Check argument types. Done mostly in order to return better error messages
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
  if (!is.null(filter_species)) {
    stopifnot(
      "`filter_species` must be NULL, a character vector of length greater than 0 or a list where each element is a single non-empty character string." =
        is_valid_species_list(filter_species)
    )

    # if not NULL, convert filter_species to a python set
    # Wrap single character strings in a list if necessary, otherwise `set` splits the string into individual characters
    if (is.character(filter_species) &&
        length(filter_species) == 1) {
      filter_species <- list(filter_species)
    }
    filter_species <- py_builtins$set(filter_species)
  }

  # convert path to a Python Path onject
  audio_file <- py_pathlib$Path(audio_file)$expanduser()$resolve(TRUE)

  # Main function logic
  predictions_gen <- py_birdnet_audio_based_prediction$predict_species_within_audio_file(
    audio_file,
    min_confidence = 0, # min_confidence,
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



