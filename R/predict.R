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
#' @details
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
#' @param object A BirdNET model object of class `birdnet_model_acoustic` created with [load_birdnet()].
#' @param files A character vector of one or more file paths to audio
#'   files. When multiple files are provided, the returned prediction
#'   object will contain results for all files; the resulting data frame
#'   (via [as.data.frame()]) includes an `input` column identifying the
#'   source file for each prediction row.
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#' @param min_confidence_custom A named list where each element is a single numeric value to set custom minimum confidence thresholds for specific species. A custom threshold will override the default one.
#' @param top_k An integer specifying the number of top predictions to return for each time interval if above minimum confidence threshold.
#' @param overlap A numeric value specifying the overlap duration in seconds between consecutive time intervals. Must be in the interval \[0.0, 3.0\].
#' @param apply_sigmoid A logical value indicating whether to apply a sigmoid function to the confidence scores.
#' @param sigmoid_sensitivity A numeric value that adjusts the sensitivity of the sigmoid function.  Must be in the interval \[0.5, 1.5\].
#' @param bandpass_fmin,bandpass_fmax A integer value to set minimum and maximum frequencies for the bandpass filter (in Hz).
#' @param species_list A character vector or list of species names to filter the predictions. If `NULL`, all species are considered.
#' @param progress A character string specifying the type of progress reporting. Options are "minimal", "progress", or "benchmark".
#' @param n_producers An integer specifying the number of threads for producing audio batches. Must be >= 1. If `NULL` (default), the Python backend default is used.
#' @param n_workers An integer specifying the number of backend workers for parallel inference. If `NULL` (default), the Python backend auto-detects based on available CPU cores.
#' @param batch_size An integer specifying the number of audio segments evaluated per inference call. Must be >= 1. If `NULL` (default), the Python backend default is used.
#' @param prefetch_ratio An integer specifying how many batches to decode ahead of processing. Must be >= 0. If `NULL` (default), the Python backend default is used.
#' @param speed A numeric value for the resampling multiplier to accommodate different recording speeds. Must be in the interval \[0.01, 100\]. If `NULL` (default), the Python backend default is used.
#' @param half_precision A logical value indicating whether to use float16 where supported for inference. If `NULL` (default), the Python backend default is used.
#' @param max_audio_duration_min A numeric value specifying the maximum total audio duration per call in minutes. Must be > 0. If `NULL` (default), no limit is applied.
#' @param ... Additional arguments passed to the generic (currently unused).
#'
#' @return An S3 object of class `birdnet_prediction_acoustic` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET acoustic model
#' model <- load_birdnet(type = "acoustic")
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- predict(model, files = audio_file)
#' # convert predictions to a data frame
#' as.data.frame(predictions)
#' }
#'
predict.birdnet_model_acoustic <- function(
  object,
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
  progress = c("minimal", "progress", "benchmark"),
  n_producers = NULL,
  n_workers = NULL,
  batch_size = NULL,
  prefetch_ratio = NULL,
  speed = NULL,
  half_precision = NULL,
  max_audio_duration_min = NULL,
  ...
) {
  model <- object
  progress <- match.arg(progress)

  # Check argument types for better error messages
  stopifnot(is.list(model))
  stopifnot(is.character(files) || is.list(files))

  # Validate that all files exist
  missing <- files[!file.exists(files)]
  if (length(missing) > 0L) {
    stop(
      "The following audio file(s) do not exist:\n",
      paste0("  - ", missing, collapse = "\n"),
      call. = FALSE
    )
  }

  # Coerce to unnamed list so reticulate passes a Python list[str]
  # to the positional-only `inp` parameter, regardless of vector length.
  files <- unname(as.list(files))

  stopifnot(is_scalar_number(min_confidence))
  stopifnot(is_scalar_integer(top_k))
  stopifnot(is_scalar_number(overlap))
  stopifnot(is_scalar_logical(apply_sigmoid))
  stopifnot(is_scalar_number(sigmoid_sensitivity))
  stopifnot(is_scalar_integer(bandpass_fmin))
  stopifnot(is_scalar_integer(bandpass_fmax))

  # Validate power-user params (only when non-NULL)
  if (!is.null(n_producers)) {
    stopifnot(is_scalar_integer(n_producers), n_producers >= 1L)
  }
  if (!is.null(n_workers)) {
    stopifnot(is_scalar_integer(n_workers), n_workers >= 1L)
  }
  if (!is.null(batch_size)) {
    stopifnot(is_scalar_integer(batch_size), batch_size >= 1L)
  }
  if (!is.null(prefetch_ratio)) {
    stopifnot(is_scalar_integer(prefetch_ratio), prefetch_ratio >= 0L)
  }
  if (!is.null(speed)) {
    stopifnot(is_scalar_number(speed), speed >= 0.01, speed <= 100)
  }
  if (!is.null(half_precision)) {
    stopifnot(is_scalar_logical(half_precision))
  }
  if (!is.null(max_audio_duration_min)) {
    stopifnot(
      is_scalar_number(max_audio_duration_min),
      max_audio_duration_min > 0
    )
  }

  # Coerce integer-like doubles to true R integers so reticulate
  # forwards them as Python int (not float).
  top_k <- as.integer(top_k)
  bandpass_fmin <- as.integer(bandpass_fmin)
  bandpass_fmax <- as.integer(bandpass_fmax)
  if (!is.null(n_producers))  n_producers  <- as.integer(n_producers)
  if (!is.null(n_workers))    n_workers    <- as.integer(n_workers)
  if (!is.null(batch_size))   batch_size   <- as.integer(batch_size)
  if (!is.null(prefetch_ratio)) prefetch_ratio <- as.integer(prefetch_ratio)

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

  # Build optional kwargs — NULLs are omitted so Python uses its own defaults
  optional_kwargs <- compact_nulls(list(
    n_producers = n_producers,
    n_workers = n_workers,
    batch_size = batch_size,
    prefetch_ratio = prefetch_ratio,
    speed = speed,
    half_precision = half_precision,
    max_audio_duration_min = max_audio_duration_min
  ))

  # Required kwargs always forwarded
  required_kwargs <- list(
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

  py_predictions <- do.call(
    model$py_model$predict,
    c(list(files), required_kwargs, optional_kwargs)
  )

  # Construct the prediction class
  construct_prediction_class(py_predictions, type = "acoustic")
}


#' Predict species using a BirdNET geo model
#'
#' This function predicts species occurence for a location and week of the year using a BirdNET geo model.
#'
#' @param object A BirdNET model object of class `birdnet_model_geo` created with [load_birdnet()].
#' @param latitude A numeric value representing the latitude of the location.
#' @param longitude A numeric value representing the longitude of the location.
#' @param week An integer value representing the week of the year (1-52).
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#' @param half_precision A logical value indicating whether to use float16 where supported for inference. If `NULL` (default), the Python backend default is used.
#' @param ... Additional arguments passed to the generic (currently unused).
#'
#' @return An S3 object of class `birdnet_prediction_geo` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET geo model
#' model <- load_birdnet(type = "geo")
#' # Predict species for a specific location and week
#' predictions <- predict(model, latitude = 50.8334, longitude = 12.9231, week = 18L)
#' # Convert predictions to a data frame
#' as.data.frame(predictions)
#'}
#'
predict.birdnet_model_geo <- function(
  object,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03,
  half_precision = NULL,
  ...
) {
  model <- object
  # Check argument types for better error messages
  stopifnot(is.list(model))
  stopifnot(is_scalar_number(latitude))
  stopifnot(is_scalar_number(longitude))
  stopifnot(is_scalar_integer(week) || is.null(week))
  stopifnot(is_scalar_number(min_confidence))
  if (!is.null(half_precision)) {
    stopifnot(is_scalar_logical(half_precision))
  }

  # Coerce integer-like doubles to true R integers so reticulate
  # forwards them as Python int (not float).
  if (!is.null(week)) week <- as.integer(week)

  # Build optional kwargs — NULLs are omitted so Python uses its own defaults
  optional_kwargs <- compact_nulls(list(
    half_precision = half_precision
  ))

  required_kwargs <- list(
    week = week,
    min_confidence = min_confidence
  )

  # Call the Python predict method
  py_predictions <- do.call(
    model$py_model$predict,
    c(list(latitude, longitude), required_kwargs, optional_kwargs)
  )

  # Construct the prediction class
  construct_prediction_class(py_predictions, type = "geo")
}


#' Convert BirdNET prediction results to a data frame
#'
#' Convert predictions from a geo or acoustic model to a data frame.
#'
#' @param x A BirdNET prediction object (as returned by `predict()`).
#' @param row.names `NULL` or a character vector giving the row names for the
#'   data frame. Not used.
#' @param optional logical. Not used.
#' @param ... Additional arguments (ignored).
#'
#' @return A data frame containing the prediction results.
#' @export
#' @rdname as.data.frame.birdnet_prediction
#' @examples
#' \dontrun{
#' # Load a BirdNET acoustic model
#' model <- load_birdnet(type = "acoustic")
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- predict(model, files = audio_file)
#' # Convert predictions to a data frame
#' as.data.frame(predictions)
#' }
as.data.frame.birdnet_prediction <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...
) {
  py_result <- x$py_predictions
  if (is.null(py_result)) {
    stop("No prediction results available.")
  }

  # Convert via structured array → dict (bypasses pandas entirely)
  dict_data <- get_df_helper()$predictions_to_dict(py_result)
  as.data.frame(dict_data, stringsAsFactors = FALSE)
}

#' @rdname as.data.frame.birdnet_prediction
#' @method as.data.frame birdnet_prediction_geo
#' @export
as.data.frame.birdnet_prediction_geo <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...
) {
  py_result <- x$py_predictions
  if (is.null(py_result)) {
    stop("No prediction results available.")
  }

  # Geo predictions: pass sort_by = NULL so Python does not sort
  dict_data <- get_df_helper()$predictions_to_dict(py_result, sort_by = NULL)
  as.data.frame(dict_data, stringsAsFactors = FALSE)
}


# Lazily loaded Python helper for structured array → dict conversion.
# Bypasses pandas entirely to avoid Arrow-backed StringDtype issues
# with reticulate.
.df_cache <- new.env(parent = emptyenv())

get_df_helper <- function() {
  if (is.null(.df_cache$py_df_utils)) {
    .df_cache$py_df_utils <- reticulate::import_from_path(
      "df_utils",
      system.file("python", package = "birdnetR")
    )
  }
  .df_cache$py_df_utils
}
