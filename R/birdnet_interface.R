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
  py_birdnet <<- reticulate::import("birdnet.models", delay_load = TRUE)
  py_pathlib <<- reticulate::import("pathlib", delay_load = TRUE)
}


#' Initialize the BirdNET Model
#'
#' This function initializes the BirdNET model (v2.4).
#'
#' @return An instance of the BirdNET model.
#' @export
init_model <- function() {
  model <- py_birdnet$ModelV2M4()
  return(model)
}

#' Predict Species Within an Audio File
#'
#' This function predicts species within an audio file using the BirdNET model.
#'
#' @param model An instance of the BirdNET model.
#' @param audio_path The path to the audio file.
#' @param keep_empty A logical flag indicating whether to include empty elements (empty time intervals) as rows in the output
#'   data frame. If `TRUE`, empty elements are filled with `NA`. If `FALSE`, empty elements are excluded.
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`.
#'   Each row represents a single prediction.
#' @export
predict_species <- function(model, audio_path = system.file("extdata", "soundscape.wav", package = "birdnetR"), keep_empty = TRUE) {
  path <- py_pathlib$Path(normalizePath(audio_path))
  predictions <- model$predict_species_within_audio_file(path)
  predictions_to_df(predictions, keep_empty = keep_empty)
}
