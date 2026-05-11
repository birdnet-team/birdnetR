#' Write BirdNET prediction results to file
#'
#' Write prediction results to disk using the underlying Python result object.
#' The format can be inferred from the file extension or specified explicitly.
#'
#' Supported formats by prediction type:
#' \itemize{
#'   \item \strong{Acoustic predictions}: CSV (\code{.csv}), Parquet (\code{.parquet}), NumPy (\code{.npz})
#'   \item \strong{Geo predictions}: CSV (\code{.csv}), NumPy (\code{.npz})
#' }
#'
#' @param x A BirdNET prediction object (as returned by \code{predict()}).
#' @param file Output file path.
#' @param format Output file format. If \code{NULL} (default), inferred from
#'   the file extension. Explicit values: \code{"csv"}, \code{"parquet"},
#'   \code{"npz"}.
#' @param ... Additional arguments passed to the underlying Python method.
#' @return Invisibly returns the output file path.
#' @examples
#' \dontrun{
#' write_predictions(pred, "results.csv")
#' write_predictions(pred, "results.parquet")
#' write_predictions(pred, "results.npz")
#' write_predictions(pred, "output.csv", format = "csv")
#' }
#' @export
#' @rdname write_predictions
write_predictions <- function(x, file, format = NULL, ...) {
  UseMethod("write_predictions")
}

#' @rdname write_predictions
#' @method write_predictions birdnet_prediction_geo
#' @export
write_predictions.birdnet_prediction_geo <- function(
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
  write_predictions.birdnet_prediction(x, file, format = format, ...)
}

#' @rdname write_predictions
#' @method write_predictions birdnet_prediction
#' @export
write_predictions.birdnet_prediction <- function(
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
