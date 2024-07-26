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
#' @return A list of predictions.
#' @export
predict_species <- function(model, audio_path = system.file("extdata", "soundscape.wav", package = "birdnetR")) {
  path <- py_pathlib$Path(audio_path)
  predictions <- model$predict_species_within_audio_file(path)
  return(predictions)
}

#' Get Top Prediction within a Time Interval
#'
#' This function retrieves the most probable prediction within a specified time interval.
#'
#' @param predictions A list of predictions from the BirdNET model.
#' @param start_time The start time of the interval.
#' @param end_time The end time of the interval.
#' @return A list containing the top prediction and its confidence.
#' @export
get_top_prediction <- function(predictions, start_time, end_time) {
  interval <- reticulate::tuple(start_time, end_time)
  interval_str <- sprintf("(%.1f, %.1f)", start_time, end_time)

  # Ensure the interval exists in the names of predictions
  if (!interval_str %in% names(predictions)) {
    stop("Interval not found in predictions")
  }

  prediction <- predictions[[interval_str]]
  top_prediction <- list(prediction = names(prediction)[1], confidence = unname(prediction)[1])
  return(top_prediction)
}
