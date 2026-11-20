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
#' @param model A BirdNET model object of class `birdnet_model_acoustic`, see
#'   [birdnet_load()], [birdnet_load_perch()] and [birdnet_load_custom()].
#' @param files A character vector of one or more file paths to audio
#'   files. The resulting data frame (via [as.data.frame()]) has an `input`
#'   column that names the source file of each row.
#' @param overlap A numeric value specifying the overlap duration in
#'   seconds between consecutive segments. Must be smaller than the
#'   segment length (3 s for BirdNET V2.4; see `segment_size_s` for V3.0).
#' @param bandpass_fmin,bandpass_fmax An integer value to set minimum and
#'   maximum frequencies for the bandpass filter (in Hz).
#' @param progress A character string specifying the type of progress
#'   reporting. Options are `"minimal"`, `"progress"`, or
#'   `"benchmark"`.
#' @param n_producers An integer specifying the number of processes that
#'   read and prepare audio batches. Must be >= 1. If `NULL` (default), the
#'   default of the `birdnet` Python package is used.
#' @param n_workers An integer specifying the number of worker processes
#'   for parallel inference. Each worker loads its own copy of the model. If
#'   `NULL` (default), `birdnet` chooses based on available CPU cores and
#'   memory; with a GPU `device`, one worker per device.
#' @param batch_size An integer specifying the number of audio segments
#'   evaluated per inference call. Must be >= 1. The BirdNET+ V3.0 `"pb"`
#'   and `"tf"` models only accept 1; use `n_workers` for parallelism there.
#'   If `NULL` (default), the default of the `birdnet` Python package (1) is
#'   used.
#' @param prefetch_ratio An integer specifying how many batches to
#'   decode ahead of processing. Must be >= 0. If `NULL` (default),
#'   the default of the `birdnet` Python package is used.
#' @param speed A numeric value for the resampling multiplier to
#'   accommodate different recording speeds. Must be in the interval
#'   \[0.01, 100\]. If `NULL` (default), the default of the `birdnet`
#'   Python package is used.
#' @param half_precision A logical value indicating whether to store the
#'   model's outputs as float16 (inference itself runs at the model's
#'   precision). If `NULL` (default), the default of the `birdnet` Python
#'   package is used.
#' @param max_audio_duration_min A numeric value specifying the longest
#'   single input in minutes. Must be > 0. If `NULL` (default), no limit is
#'   applied.
#' @param segment_size_s A numeric value: length of the analyzed segments in
#'   seconds (BirdNET+ V3.0 only; it accepts variable-length input). If `NULL`
#'   (default), the model's own default is used.
#' @param device A character string, `"CPU"` or `"GPU"` (or a vector of
#'   devices). If `NULL` (default), the CPU is used. See [birdnet_use_gpu()].
#' @param ... Not used. Passing any other argument is an error.
#'
#' @return An S3 object of class `birdnet_encoding` containing the
#'   embeddings. Use [as.data.frame()] to convert to a data
#'   frame.
#' @seealso [as.data.frame.birdnet_encoding()], [birdnet_predict()]
#' @export
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' audio_file <- system.file("extdata", "soundscape.mp3",
#'   package = "birdnetR"
#' )
#' enc <- birdnet_encode(model, files = audio_file)
#' as.data.frame(enc)
#' }
birdnet_encode <- function(model, ...) {
  UseMethod("birdnet_encode")
}


#' @rdname birdnet_encode
#' @export
birdnet_encode.birdnet_model_acoustic <- function(
  model,
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
  segment_size_s = NULL,
  device = NULL,
  ...
) {
  check_dots_empty(...)
  progress <- match.arg(progress)
  files <- check_files(files)
  kwargs <- inference_kwargs(
    overlap, bandpass_fmin, bandpass_fmax, progress,
    n_producers, n_workers, batch_size, prefetch_ratio, speed, half_precision,
    max_audio_duration_min, segment_size_s, device
  )

  py_encodings <- do.call(model$py_model$encode, c(list(files), kwargs))

  construct_encoding_class(py_encodings)
}


#' Convert BirdNET embeddings to a data frame
#'
#' @description
#' Convert the embeddings from an acoustic model to a data frame.
#' Each row represents one audio segment. The `embedding` column is
#' returned as a list of numeric vectors (one per segment).
#'
#' @param x A BirdNET encoding object (as returned by [birdnet_encode()]).
#' @param row.names `NULL` or a character vector giving the row names
#'   for the data frame. Not used.
#' @param optional logical. Not used.
#' @param ... Additional arguments (ignored).
#'
#' @return A data frame containing the embeddings. Columns
#'   include `input`, `start_time`, `end_time`, and `embedding`
#'   (a list column of numeric vectors).
#' @export
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' audio_file <- system.file("extdata", "soundscape.mp3",
#'   package = "birdnetR"
#' )
#' enc <- birdnet_encode(model, files = audio_file)
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
    stop("No encoding results available.", call. = FALSE)
  }

  dict_data <- get_df_helper()$encodings_to_dict(py_result)

  # Separate embedding (list column) from scalar columns
  embedding_col <- dict_data[["embedding"]]
  scalar_data <- dict_data[names(dict_data) != "embedding"]
  df <- as.data.frame(scalar_data, stringsAsFactors = FALSE)
  df$embedding <- embedding_col
  df
}
