# Create a new encoding results object.
#
# Wraps a Python encoding results object in an S3 class hierarchy
# analogous to the prediction result classes.
#
# @param py_encodings A Python object representing BirdNET encoding results
# @return An S3 object of class `birdnet_encoding` containing the Python
#   encoding results object
# @noRd
construct_encoding_class <- function(py_encodings) {
  stopifnot(reticulate::is_py_object(py_encodings))

  structure(
    list(py_encodings = py_encodings),
    class = "birdnet_encoding"
  )
}


#' Encode audio files using a BirdNET acoustic model
#'
#' @description
#' Run the encoder stage of a BirdNET acoustic model to obtain embedding
#' vectors for each segment of the supplied audio files. This is useful for
#' downstream tasks such as clustering, dimensionality reduction, or
#' transfer-learning workflows that build on BirdNET embeddings.
#'
#' @param object A BirdNET model object of class `birdnet_model_acoustic`
#'   created with [load_birdnet()] or [load_perch()].
#' @param files A character vector of one or more file paths to audio
#'   files. When multiple files are provided the resulting data frame
#'   (via [as.data.frame()]) includes an `input` column identifying the
#'   source file for each row.
#' @param overlap A numeric value specifying the overlap duration in
#'   seconds between consecutive time intervals. Must be in the
#'   interval \[0.0, 3.0\].
#' @param bandpass_fmin,bandpass_fmax An integer value to set minimum and
#'   maximum frequencies for the bandpass filter (in Hz).
#' @param progress A character string specifying the type of progress
#'   reporting. Options are `"minimal"`, `"progress"`, or
#'   `"benchmark"`.
#' @param n_producers An integer specifying the number of threads for
#'   producing audio batches. Must be >= 1. If `NULL` (default), the
#'   Python backend default is used.
#' @param n_workers An integer specifying the number of backend workers
#'   for parallel inference. If `NULL` (default), the Python backend
#'   auto-detects based on available CPU cores.
#' @param batch_size An integer specifying the number of audio segments
#'   evaluated per inference call. Must be >= 1. If `NULL` (default),
#'   the Python backend default is used.
#' @param prefetch_ratio An integer specifying how many batches to
#'   decode ahead of processing. Must be >= 0. If `NULL` (default),
#'   the Python backend default is used.
#' @param speed A numeric value for the resampling multiplier to
#'   accommodate different recording speeds. Must be in the interval
#'   \[0.01, 100\]. If `NULL` (default), the Python backend default
#'   is used.
#' @param half_precision A logical value indicating whether to use
#'   float16 where supported for inference. If `NULL` (default), the
#'   Python backend default is used.
#' @param max_audio_duration_min A numeric value specifying the maximum
#'   total audio duration per call in minutes. Must be > 0. If `NULL`
#'   (default), no limit is applied.
#' @param ... Additional arguments passed to the generic (currently
#'   unused).
#'
#' @return An S3 object of class `birdnet_encoding` containing the
#'   encoding results. Use [as.data.frame()] to convert to a data
#'   frame.
#' @export
#' @examples
#' \dontrun{
#' model <- load_birdnet(type = "acoustic")
#' audio_file <- system.file("extdata", "soundscape.mp3",
#'   package = "birdnetR"
#' )
#' enc <- encode(model, files = audio_file)
#' as.data.frame(enc)
#' }
encode <- function(object, ...) {
  UseMethod("encode")
}


#' @rdname encode
#' @export
encode.birdnet_model_acoustic <- function(
  object,
  files,
  overlap = 0,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
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
  files <- unname(as.list(files))

  stopifnot(is_scalar_number(overlap))
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

  # Coerce integer-like doubles to true R integers
  bandpass_fmin <- as.integer(bandpass_fmin)
  bandpass_fmax <- as.integer(bandpass_fmax)
  if (!is.null(n_producers)) n_producers <- as.integer(n_producers)
  if (!is.null(n_workers)) n_workers <- as.integer(n_workers)
  if (!is.null(batch_size)) batch_size <- as.integer(batch_size)
  if (!is.null(prefetch_ratio)) prefetch_ratio <- as.integer(prefetch_ratio)

  # Build optional kwargs — NULLs are omitted so Python uses its defaults
  optional_kwargs <- compact_nulls(list(
    n_producers = n_producers,
    n_workers = n_workers,
    batch_size = batch_size,
    prefetch_ratio = prefetch_ratio,
    speed = speed,
    half_precision = half_precision,
    max_audio_duration_min = max_audio_duration_min
  ))

  required_kwargs <- list(
    overlap_duration_s = overlap,
    bandpass_fmin = bandpass_fmin,
    bandpass_fmax = bandpass_fmax,
    show_stats = progress
  )

  py_encodings <- do.call(
    model$py_model$encode,
    c(list(files), required_kwargs, optional_kwargs)
  )

  construct_encoding_class(py_encodings)
}


#' Convert BirdNET encoding results to a data frame
#'
#' @description
#' Convert encoding results from an acoustic model to a data frame.
#' Each row represents one audio segment. The `embedding` column is
#' returned as a list of numeric vectors (one per segment).
#'
#' @param x A BirdNET encoding object (as returned by [encode()]).
#' @param row.names `NULL` or a character vector giving the row names
#'   for the data frame. Not used.
#' @param optional logical. Not used.
#' @param ... Additional arguments (ignored).
#'
#' @return A data frame containing the encoding results. Columns
#'   include `input`, `start_time`, `end_time`, and `embedding`
#'   (a list column of numeric vectors).
#' @export
#' @examples
#' \dontrun{
#' model <- load_birdnet(type = "acoustic")
#' audio_file <- system.file("extdata", "soundscape.mp3",
#'   package = "birdnetR"
#' )
#' enc <- encode(model, files = audio_file)
#' df <- as.data.frame(enc)
#' # Access the first embedding vector
#' df$embedding[[1]]
#' }
as.data.frame.birdnet_encoding <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...
) {
  py_result <- x$py_encodings
  if (is.null(py_result)) {
    stop("No encoding results available.")
  }

  dict_data <- get_df_helper()$encodings_to_dict(py_result)

  # Separate embedding (list column) from scalar columns
  embedding_col <- dict_data[["embedding"]]
  scalar_data <- dict_data[names(dict_data) != "embedding"]
  df <- as.data.frame(scalar_data, stringsAsFactors = FALSE)
  df$embedding <- embedding_col
  df
}
