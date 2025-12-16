# Create a new prediction results object.
#'
#' This function creates a new prediction results object by wrapping a Python prediction results object and assigning
#' it a class and subclasses. The prediction results are created as an R object that can be interacted with
#' using R's S3 method dispatch.
#'
#' @param py_predictions A Python object representing the BirdNET prediction results
#' @param type Model type: "acoustic", "geo"
#' @return An S3 object of class `birdnet_prediction` containing the Python prediction results object
#'
#' @noRd
construct_prediction_class <- function(py_predictions, type) {
  stopifnot(reticulate::is_py_object(py_predictions)) # Ensure that the input is a valid Python object

  cl <- c(
    paste0("birdnet_prediction_", type),
    "birdnet_prediction"
  )

  structure(
    list(py_predictions = py_predictions),
    class = cl
  )
}


#' Predict species from audio files using a BirdNET acoustic model
#'
#' This function predicts species from audio files using a BirdNET acoustic model.
#'
#' #' @details
#' ### Sigmoid Activation
#' When `apply_sigmoid = TRUE`, the raw logit scores from the linear classifier are passed
#' through a sigmoid function, scaling them into the range \[0, 1\]. This unitless confidence
#' score reflects BirdNET’s certainty in its prediction (it is not a direct probability of species presence).
#' Adjusting the `sigmoid_sensitivity` parameter modifies the score distribution:
#' * Values **< 1** tend to produce more extreme scores (closer to 0 or 1).
#' * Values **> 1** result in scores that are more moderate (centered around intermediate values).
#'
#' For additional details on BirdNET confidence scores and guidelines for converting them to probabilities, see Wood & Kahl (2024).
#'
#' @references Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of BirdNET scores and other detector outputs. Journal of Ornithology. https://doi.org/10.1007/s10336-024-02144-5
#'
#' @param model A BirdNET model object of class `birdnet_model_acoustic` created with [load_model(type = "acoustic")].
#' @param files A character vector of file paths to audio files.
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#' @param min_confidence_custom A named list where each element is a single numeric value to set custom minimum confidence thresholds for specific species. A custom threshold will override the default one.
#' @param top_k An integer specifying the number of top predictions to return for each time interval if above minimum confidence threshold.
#' @param overlap A numeric value specifying the overlap duration in seconds between consecutive time intervals. Must be in the interval \[0.0, 3.0\].
#' @param apply_sigmoid A logical value indicating whether to apply a sigmoid function to the confidence scores.
#' @param sigmoid_sensitivity A numeric value that adjusts the sensitivity of the sigmoid function.  Must be in the interval \[0.5, 1.5\].
#' @param bandpass_fmin,bandpass_fmax A integer value to set minimum and maximum frequencies for the bandpass filter (in Hz).
#' @param species_list A character vector or list of species names to filter the predictions. If `NULL`, all species are considered.
#' @param progress A character string specifying the type of progress reporting. Options are "minimal", "progress", or "benchmark".
#'
#' @return An S3 object of class `birdnet_prediction_acoustic` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET acoustic model
#' model <- load_model(type = "acoustic")
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- predict(model, files = audio_file)
#' # convert predictions to a data frame
#' as.data.frame(predictions)
#' }
#'
predict.birdnet_model_acoustic <- function(
  model,
  files,
  min_confidence = 0.1,
  min_confidence_custom = NULL,
  top_k = 5L,
  overlap = 0,
  apply_sigmoid = TRUE,
  sigmoid_sensitivity = 1,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
  species_list = NULL,
  progress = c("minimal", "progress", "benchmark")
) {
  progress <- match.arg(progress)

  # Check argument types for better error messages
  stopifnot(is.list(model))
  stopifnot(is.character(files) || is.list(files))
  stopifnot(is.numeric(min_confidence))
  stopifnot(is.integer(top_k))
  stopifnot(is.numeric(overlap))
  stopifnot(is.logical(apply_sigmoid))
  stopifnot(is.numeric(sigmoid_sensitivity))
  stopifnot(is.integer(bandpass_fmin))
  stopifnot(is.integer(bandpass_fmax))

  # Handle custom minimum confidence
  if (!is.null(min_confidence_custom)) {
    stopifnot(
      "`min_confidence_custom` must be NULL or a named list where each element is a single numeric value." = is_valid_min_confidence_list(
        min_confidence_custom
      )
    )
    min_confidence_custom <- py_builtins$dict(min_confidence_custom)
  }

  # Handle species filter
  if (!is.null(species_list)) {
    stopifnot(
      "`species_list` must be NULL, a character vector of length > 0, or a list of non-empty strings." = is_valid_species_list(
        species_list
      )
    )
    # Coerce to list if necessary
    if (is.character(species_list)) {
      species_list <- as.list(species_list)
    } else if (!is.list(species_list)) {
      stop("species_list must be a character vector or a list of strings")
    }
    species_list <- py_builtins$set(species_list)
  }

  py_predictions <- model$py_model$predict(
    files,
    top_k = top_k,
    overlap_duration_s = overlap,
    bandpass_fmin = bandpass_fmin,
    bandpass_fmax = bandpass_fmax,
    apply_sigmoid = apply_sigmoid,
    sigmoid_sensitivity = sigmoid_sensitivity,
    default_confidence_threshold = min_confidence,
    custom_confidence_thresholds = min_confidence_custom,
    custom_species_list = species_list,
    show_stats = progress
  )

  # Construct the prediction class
  construct_prediction_class(py_predictions, type = "acoustic")
}


#' Predict species using a BirdNET geo model
#'
#' This function predicts species occurence for a location and week of the year using a BirdNET geo model.
#'
#' @param model A BirdNET model object of class `birdnet_model_geo` created with [load_model(type = "geo")].
#' @param latitude A numeric value representing the latitude of the location.
#' @param longitude A numeric value representing the longitude of the location.
#' @param week An integer value representing the week of the year (1-52).
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#'
#' @return An S3 object of class `birdnet_prediction_geo` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET geo model
#' model <- load_model(type = "geo")
#' # Predict species for a specific location and week
#' predictions <- predict(model, latitude = 50.8334, longitude = 12.9231, week = 18L)
#' # Convert predictions to a data frame
#' as.data.frame(predictions)
#'}
#'
predict.birdnet_model_geo <- function(
  model,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.1
) {
  # Check argument types for better error messages
  stopifnot(is.list(model))
  stopifnot(is.numeric(latitude))
  stopifnot(is.numeric(longitude))
  stopifnot(is.integer(week) || is.null(week))
  stopifnot(is.numeric(min_confidence))

  # Call the Python predict method
  py_predictions <- model$py_model$predict(
    latitude,
    longitude,
    week = week,
    min_confidence = min_confidence
  )

  # Construct the prediction class
  construct_prediction_class(py_predictions, type = "geo")
}


#' Convert BirdNET prediction results to a data frame
#'
#' Convert predictions from a geo or acoustic model to a data frame.
#'
#' @param x A BirdNET prediction object (as returned by `predict()`).
#'
#' @return A data frame containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET acoustic model
#' model <- load_model(type = "acoustic")
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- predict(model, files = audio_file)
#' # Convert predictions to a data frame
#' as.data.frame(predictions)
#' }

as.data.frame.birdnet_prediction <- function(x) {
  py_result <- x$py_predictions
  if (is.null(py_result)) {
    stop("No prediction results available.")
  }

  # Convert the Python DataFrame to an R data frame
  df <- x$py_predictions$to_dataframe()

  # Ensure the data frame has the correct structure
  if (!is.data.frame(df)) {
    stop("The prediction results could not be converted to a data frame.")
  }

  return(df)
}
