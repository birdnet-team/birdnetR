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


#' Predict species with a BirdNET model
#'
#' `birdnet_predict()` runs a loaded model. What it predicts depends on the model:
#' * acoustic models (BirdNET, Perch, custom classifiers) identify species in
#'   audio files, see [birdnet_predict.birdnet_model_acoustic()];
#' * geo models predict which species occur at a location and week of the year,
#'   see [birdnet_predict.birdnet_model_geo()].
#'
#' @param model A BirdNET model object, see [birdnet_load()].
#' @param ... Arguments for the model-specific method.
#' @return An S3 prediction object; convert it with [as.data.frame()] or save
#'   it with [birdnet_write()].
#' @seealso [birdnet_list_models()]
#' @export
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- birdnet_predict(model, files = audio_file)
#' as.data.frame(predictions)
#'
#' geo <- birdnet_load(type = "geo")
#' as.data.frame(birdnet_predict(geo, latitude = 50.83, longitude = 12.92, week = 18L))
#' }
birdnet_predict <- function(model, ...) {
  UseMethod("birdnet_predict")
}


#' Predict species from audio files using a BirdNET acoustic model
#'
#' Identifies species in audio files with an acoustic model (BirdNET+ V3.0,
#' BirdNET V2.4, Perch v2 or a custom classifier).
#'
#' @details
#' ### Confidence scores
#' With `apply_sigmoid = NULL` (default) each model uses its own default:
#' BirdNET models and custom classifiers return sigmoid scores between 0 and 1,
#' Perch v2 returns raw model outputs (logits). A score reflects how certain the
#' model is. It is not the probability that the species is present.
#'
#' `sigmoid_sensitivity` shifts the scores: values above 1 raise them, values
#' below 1 lower them (the logits are shifted by
#' `10 * (sigmoid_sensitivity - 1)` before the sigmoid). It has no effect with
#' `apply_sigmoid = FALSE`.
#'
#' For guidelines on BirdNET scores and on converting them to probabilities, see Wood & Kahl (2024).
#'
#' @references Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of BirdNET scores and other detector outputs. Journal of Ornithology. https://doi.org/10.1007/s10336-024-02144-5
#'
#' @param model A BirdNET model object of class `birdnet_model_acoustic`, see [birdnet_load()], [birdnet_load_perch()] and [birdnet_load_custom()].
#' @param files A character vector of one or more file paths to audio
#'   files. The resulting data frame (via [as.data.frame()]) has an `input`
#'   column that names the source file of each row.
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#' @param min_confidence_custom A named list where each element is a single numeric value to set custom minimum confidence thresholds for specific species. A custom threshold will override the default one.
#' @param top_k An integer specifying the number of top predictions to return for each segment if above minimum confidence threshold. `NULL` returns every species above the threshold.
#' @param overlap A numeric value specifying the overlap duration in seconds between consecutive segments. Must be smaller than the segment length (3 s for BirdNET V2.4; see `segment_size_s` for V3.0).
#' @param apply_sigmoid A logical value indicating whether to apply a sigmoid function to the confidence scores. If `NULL` (default), the model's own default is used.
#' @param sigmoid_sensitivity A numeric value that shifts the sigmoid scores, see Details. Must be in the interval \[0.5, 1.5\]. If `NULL` (default), the model's own default (1.0) is used.
#' @param apply_softmax A logical value. If `TRUE`, scores become a softmax over the model's logits (e.g. for Perch v2). Not supported by models that apply the sigmoid inside the model (BirdNET+ V3.0, Raven exports). If `NULL` (default), the model's own default (`FALSE`) is used.
#' @param segment_size_s A numeric value: length of the analyzed segments in seconds (BirdNET+ V3.0 only; it accepts variable-length input). If `NULL` (default), the model's own default is used.
#' @param device A character string, `"CPU"` or `"GPU"` (or a vector of devices). If `NULL` (default), the CPU is used. See [birdnet_use_gpu()].
#' @param bandpass_fmin,bandpass_fmax An integer value to set minimum and maximum frequencies for the bandpass filter (in Hz).
#' @param species_list A character vector or list of species names to filter the predictions. If `NULL`, all species are considered.
#' @param progress A character string specifying the type of progress reporting. Options are `"minimal"`, `"progress"`, or `"benchmark"`.
#' @param n_producers An integer specifying the number of processes that read and prepare audio batches. Must be >= 1. If `NULL` (default), the default of the `birdnet` Python package is used.
#' @param n_workers An integer specifying the number of worker processes for parallel inference. Each worker loads its own copy of the model. If `NULL` (default), `birdnet` chooses based on available CPU cores and memory; with a GPU `device`, one worker per device.
#' @param batch_size An integer specifying the number of audio segments evaluated per inference call. Must be >= 1. The BirdNET+ V3.0 `"pb"` and `"tf"` models only accept 1; use `n_workers` for parallelism there. If `NULL` (default), the default of the `birdnet` Python package (1) is used.
#' @param prefetch_ratio An integer specifying how many batches to decode ahead of processing. Must be >= 0. If `NULL` (default), the default of the `birdnet` Python package is used.
#' @param speed A numeric value for the resampling multiplier to accommodate different recording speeds. Must be in the interval \[0.01, 100\]. If `NULL` (default), the default of the `birdnet` Python package is used.
#' @param half_precision A logical value indicating whether to store the model's outputs as float16 (inference itself runs at the model's precision). If `NULL` (default), the default of the `birdnet` Python package is used.
#' @param max_audio_duration_min A numeric value specifying the longest single input in minutes. Must be > 0. If `NULL` (default), no limit is applied.
#' @param ... Not used. Passing any other argument is an error.
#'
#' @return An S3 object of class `birdnet_prediction_acoustic` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET acoustic model
#' model <- birdnet_load()
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- birdnet_predict(model, files = audio_file)
#' # convert predictions to a data frame
#' as.data.frame(predictions)
#' }
#'
birdnet_predict.birdnet_model_acoustic <- function(
  model,
  files,
  min_confidence = 0.1,
  min_confidence_custom = NULL,
  top_k = 5L,
  overlap = 0,
  apply_sigmoid = NULL,
  sigmoid_sensitivity = NULL,
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
  apply_softmax = NULL,
  segment_size_s = NULL,
  device = NULL,
  ...
) {
  check_dots_empty(...)
  progress <- match.arg(progress)
  files <- check_files(files)

  check_arg(is_scalar_number(min_confidence), "min_confidence", "a number")
  check_arg(
    is.null(top_k) || is_scalar_integer(top_k),
    "top_k", "a whole number or `NULL`"
  )
  check_arg(
    is.null(apply_sigmoid) || is_scalar_logical(apply_sigmoid),
    "apply_sigmoid", "`TRUE`, `FALSE` or `NULL`"
  )
  check_arg(
    is.null(apply_softmax) || is_scalar_logical(apply_softmax),
    "apply_softmax", "`TRUE`, `FALSE` or `NULL`"
  )
  check_arg(
    is.null(sigmoid_sensitivity) ||
      (is_scalar_number(sigmoid_sensitivity) && sigmoid_sensitivity > 0),
    "sigmoid_sensitivity", "a number above 0 or `NULL`"
  )
  check_arg(
    is.null(min_confidence_custom) ||
      is_valid_min_confidence_list(min_confidence_custom),
    "min_confidence_custom", "`NULL` or a named list with one number per species"
  )
  check_arg(
    is.null(species_list) || is_valid_species_list(species_list),
    "species_list", "`NULL`, a character vector or a list of strings"
  )
  shared <- inference_kwargs(
    overlap, bandpass_fmin, bandpass_fmax, progress,
    n_producers, n_workers, batch_size, prefetch_ratio, speed, half_precision,
    max_audio_duration_min, segment_size_s, device
  )

  if (!is.null(min_confidence_custom)) {
    min_confidence_custom <- py_builtins$dict(min_confidence_custom)
  }
  if (!is.null(species_list)) {
    species_list <- py_builtins$set(as.list(species_list))
  }

  # NULLs in this list reach Python as None (top_k = NULL: no cap); the
  # optional ones are dropped so that Python uses its own defaults.
  kwargs <- c(
    list(
      top_k = if (!is.null(top_k)) as.integer(top_k),
      default_confidence_threshold = min_confidence,
      custom_confidence_thresholds = min_confidence_custom,
      custom_species_list = species_list
    ),
    compact_nulls(list(
      apply_sigmoid = apply_sigmoid,
      sigmoid_sensitivity = sigmoid_sensitivity,
      apply_softmax = apply_softmax
    )),
    shared
  )

  py_predictions <- do.call(model$py_model$predict, c(list(files), kwargs))

  # Construct the prediction class
  construct_prediction_class(py_predictions, type = "acoustic")
}


#' Predict species using a BirdNET geo model
#'
#' Predicts which species occur at a location and week of the year with a
#' BirdNET geo model.
#'
#' @param model A BirdNET model object of class `birdnet_model_geo`, see [birdnet_load()].
#' @param latitude A numeric value representing the latitude of the location.
#' @param longitude A numeric value representing the longitude of the location.
#' @param week An integer value representing the week of the year (1-48). If `NULL` (default), predicts for the whole year.
#' @param year_round_aggregation `"max"` or `"average"`: how weekly scores are combined when `week = NULL`. If `NULL` (default), the model's own default (`"max"`) is used.
#' @param device A character string, `"CPU"` or `"GPU"`. If `NULL` (default), the CPU is used.
#' @param min_confidence A numeric value to set the minimum confidence threshold for predictions.
#' @param half_precision A logical value indicating whether to store the model's outputs as float16 (inference itself runs at the model's precision). If `NULL` (default), the default of the `birdnet` Python package is used.
#' @param ... Not used. Passing any other argument is an error.
#'
#' @return An S3 object of class `birdnet_prediction_geo` and `birdnet_prediction` containing the prediction results.
#' @export
#' @examples
#' \dontrun{
#' # Load a BirdNET geo model
#' model <- birdnet_load(type = "geo")
#' # Predict species for a specific location and week
#' predictions <- birdnet_predict(model, latitude = 50.8334, longitude = 12.9231, week = 18L)
#' # Convert predictions to a data frame
#' as.data.frame(predictions)
#' }
#'
birdnet_predict.birdnet_model_geo <- function(
  model,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03,
  half_precision = NULL,
  year_round_aggregation = NULL,
  device = NULL,
  ...
) {
  check_dots_empty(...)
  check_arg(is_scalar_number(latitude), "latitude", "a number")
  check_arg(is_scalar_number(longitude), "longitude", "a number")
  check_arg(
    is.null(week) || is_scalar_integer(week),
    "week", "a whole number or `NULL`"
  )
  check_arg(is_scalar_number(min_confidence), "min_confidence", "a number")
  check_arg(
    is.null(half_precision) || is_scalar_logical(half_precision),
    "half_precision", "`TRUE`, `FALSE` or `NULL`"
  )
  if (!is.null(year_round_aggregation)) {
    year_round_aggregation <- match.arg(year_round_aggregation, c("max", "average"))
  }
  check_arg(
    is.null(device) || is_valid_device(device),
    "device", "\"CPU\", \"GPU\" or `NULL`"
  )

  # Coerce integer-like doubles to true R integers so reticulate
  # forwards them as Python int (not float).
  if (!is.null(week)) week <- as.integer(week)

  # Build optional kwargs - NULLs are omitted so Python uses its own defaults
  optional_kwargs <- compact_nulls(list(
    half_precision = half_precision,
    year_round_aggregation = year_round_aggregation,
    device = device
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
#' @param x A BirdNET prediction object (as returned by [birdnet_predict()]).
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
#' model <- birdnet_load()
#' # Predict species from audio files
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' predictions <- birdnet_predict(model, files = audio_file)
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
    stop("No prediction results available.", call. = FALSE)
  }

  # Convert via structured array -> dict (bypasses pandas entirely)
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
    stop("No prediction results available.", call. = FALSE)
  }

  # Geo predictions: pass sort_by = NULL so Python does not sort
  dict_data <- get_df_helper()$predictions_to_dict(py_result, sort_by = NULL)
  as.data.frame(dict_data, stringsAsFactors = FALSE)
}


# Lazily loaded Python helper for structured array -> dict conversion.
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
