#' Write BirdNET predictions or encodings to file
#'
#' Write prediction or encoding results to disk using the underlying Python
#' result object. The format can be inferred from the file extension or
#' specified explicitly.
#'
#' Supported formats by result type:
#' \itemize{
#'   \item \strong{Acoustic predictions}: CSV (\code{.csv}), Parquet (\code{.parquet}), NumPy (\code{.npz})
#'   \item \strong{Geo predictions}: CSV (\code{.csv}), NumPy (\code{.npz})
#'   \item \strong{Encodings}: CSV (\code{.csv}), Parquet (\code{.parquet}), NumPy (\code{.npz})
#' }
#'
#' @param x A prediction or encoding object (from [birdnet_predict()] or
#'   [birdnet_encode()]).
#' @param file Output file path.
#' @param format Output file format. If \code{NULL} (default), inferred from
#'   the file extension. Explicit values: \code{"csv"}, \code{"parquet"},
#'   \code{"npz"}.
#' @param ... Additional arguments passed to the underlying Python method.
#' @return Invisibly returns the output file path.
#' @examples
#' \dontrun{
#' birdnet_write(pred, "results.csv")
#' birdnet_write(pred, "results.parquet")
#' birdnet_write(pred, "results.npz")
#' birdnet_write(pred, "output.csv", format = "csv")
#' birdnet_write(enc, "embeddings.parquet")
#' }
#' @export
#' @rdname birdnet_write
birdnet_write <- function(x, file, format = NULL, ...) {
  UseMethod("birdnet_write")
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_prediction_geo
#' @export
birdnet_write.birdnet_prediction_geo <- function(
  x,
  file,
  format = NULL,
  ...
) {
  format <- resolve_save_format(file, format)
  if (format == "parquet") {
    stop(
      "Parquet format is not supported for geo predictions. Use 'csv' or 'npz'."
    )
  }
  birdnet_write.birdnet_prediction(x, file, format = format, ...)
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_prediction
#' @export
birdnet_write.birdnet_prediction <- function(
  x,
  file,
  format = NULL,
  ...
) {
  format <- resolve_save_format(file, format)
  py_result <- x$py_predictions
  if (is.null(py_result)) {
    stop("No prediction results available.")
  }
  write_py_result(py_result, file, format, ...)
}

#' @rdname birdnet_write
#' @method birdnet_write birdnet_encoding
#' @export
birdnet_write.birdnet_encoding <- function(
  x,
  file,
  format = NULL,
  ...
) {
  format <- resolve_save_format(file, format)
  py_result <- x$py_encodings
  if (is.null(py_result)) {
    stop("No encoding results available.")
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
  if (format == "csv") {
    py_result$to_csv(file, ...)
  } else if (format == "parquet") {
    py_result$to_parquet(file, ...)
  } else if (format == "npz") {
    py_result$save(file, ...)
  }
  invisible(file)
}


#' Infer save format from file extension or validate explicit format
#' @param file Output file path.
#' @param format Explicit format or NULL.
#' @return Validated format string.
#' @noRd
resolve_save_format <- function(file, format) {
  valid_formats <- c("csv", "parquet", "npz")
  if (is.null(format)) {
    ext <- tolower(tools::file_ext(file))
    ext_map <- c(csv = "csv", parquet = "parquet", npz = "npz")
    if (!(ext %in% names(ext_map))) {
      stop(
        "Cannot infer format from file extension '.",
        ext,
        "'. Use an unambiguous extension (.csv, .parquet, .npz)",
        " or specify `format` explicitly."
      )
    }
    format <- ext_map[[ext]]
  }
  if (!(format %in% valid_formats)) {
    stop(
      "Unsupported format: '",
      format,
      "'. Use one of: ",
      paste(valid_formats, collapse = ", "),
      "."
    )
  }
  format
}
