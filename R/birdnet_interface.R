library(reticulate)

# Import the necessary Python modules
py_birdnet <- import("birdnet.models")
py_pathlib <- import("pathlib")

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
predict_species <- function(model, audio_path = system.file("extdata", "soundscape.wav", package = "yourpackage")) {
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
  interval <- c(start_time, end_time)
  prediction <- predictions[[interval]]
  top_prediction <- list(prediction = names(prediction)[1], confidence = unname(prediction)[1])
  return(top_prediction)
}
