#' Write BirdNET predictions or embeddings to a file
#'
#' Writes predictions or embeddings to disk straight from Python,
#' without converting them to an R data frame first. The file extension selects
#' the format.
#'
#' Supported formats by result type:
#' * **Acoustic predictions**: CSV (`.csv`), Parquet (`.parquet`), NumPy (`.npz`)
#' * **Geo predictions**: CSV (`.csv`), NumPy (`.npz`)
#' * **Embeddings**: CSV (`.csv`), Parquet (`.parquet`), NumPy (`.npz`)
#'
#' @param x A prediction or encoding object (from [birdnet_predict()] or
#'   [birdnet_encode()]).
#' @param file Output file path. It must end in `.csv`, `.parquet` or `.npz`
#'   (lower case); the extension selects the format.
#' @param ... Additional arguments passed to the underlying Python method.
#' @return Invisibly returns the output file path, with `~` expanded.
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#'
#' predictions <- birdnet_predict(model, files = audio_file)
#' birdnet_write(predictions, file.path(tempdir(), "results.csv"))
#' birdnet_write(predictions, file.path(tempdir(), "results.parquet"))
#'
#' embeddings <- birdnet_encode(model, files = audio_file)
#' birdnet_write(embeddings, file.path(tempdir(), "embeddings.npz"))
#' }
#' @export
#' @rdname birdnet_write
birdnet_write <- function(x, file, ...) {
  UseMethod("birdnet_write")
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_prediction_geo
#' @export
birdnet_write.birdnet_prediction_geo <- function(
  x,
  file,
  ...
) {
  if (resolve_save_format(file) == "parquet") {
    stop(
      "Parquet format is not supported for geo predictions. Use CSV or NPZ.",
      call. = FALSE
    )
  }
  birdnet_write.birdnet_prediction(x, file, ...)
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_prediction
#' @export
birdnet_write.birdnet_prediction <- function(
  x,
  file,
  ...
) {
  format <- resolve_save_format(file)
  py_result <- x$py_predictions
  if (is.null(py_result)) {
    stop("No prediction results available.", call. = FALSE)
  }
  write_py_result(py_result, file, format, ...)
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_encoding
#' @export
birdnet_write.birdnet_encoding <- function(
  x,
  file,
  ...
) {
  format <- resolve_save_format(file)
  py_result <- x$py_encodings
  if (is.null(py_result)) {
    stop("No encoding results available.", call. = FALSE)
  }
  write_py_result(py_result, file, format, ...)
}

#' Call the Python writer matching a validated format
#' @param py_result Python result object (predictions or encodings).
#' @param file Output file path.
#' @param format Validated format string from `resolve_save_format()`.
#' @param ... Passed to the Python method.
#' @return Invisibly returns `file`.
#' @noRd
write_py_result <- function(py_result, file, format, ...) {
  # Python does not expand `~`
  file <- path.expand(file)
  if (format == "csv") {
    py_result$to_csv(file, ...)
  } else if (format == "parquet") {
    py_result$to_parquet(file, ...)
  } else if (format == "npz") {
    py_result$save(file, ...)
  }
  invisible(file)
}


#' The save format, taken from the extension of `file`
#'
#' The Python writers refuse a file whose extension is not exactly their own
#' (`.csv`, `.parquet`, `.npz`), so R checks it first.
#' @param file Output file path.
#' @return The format: "csv", "parquet" or "npz".
#' @noRd
resolve_save_format <- function(file) {
  check_arg(is_string(file), "file", "a file path")
  ext <- tools::file_ext(file)
  if (!(ext %in% c("csv", "parquet", "npz"))) {
    stop(
      "`file` must end in `.csv`, `.parquet` or `.npz`, not \"",
      basename(file), "\".",
      call. = FALSE
    )
  }
  ext
}
