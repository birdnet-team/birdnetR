#' Save BirdNET prediction results to file
#'
#' Save prediction results to disk in various formats (e.g., CSV, parquet, npz)
#' using the underlying Python object. Supported formats are: 'csv', 'parquet', 'npz'.
#'
#' @param x A BirdNET prediction object (as returned by \code{predict()}).
#' @param file Output file path.
#' @param format Output file format, one of \code{"csv"}, \code{"parquet"}, \code{"npz"}.
#' @param ... Additional arguments passed to the underlying Python method.
#' @return Invisibly returns the output file path.
#' @examples
#' \dontrun{
#' save_birdnet(pred, "results.csv", format = "csv")
#' save_birdnet(pred, "results.parquet", format = "parquet")
#' }
#' @export
#' @rdname save_birdnet
save_birdnet <- function(x, file, format = c("csv", "parquet", "npz"), ...) {
  format <- match.arg(format)
  UseMethod("save_birdnet")
}

#' @rdname save_birdnet
#' @method save_birdnet birdnet_prediction_v2_4
#' @export
save_birdnet.birdnet_prediction_v2_4 <- function(
  x,
  file,
  format = c("csv", "parquet", "npz"),
  ...
) {
  format <- match.arg(format)
  py_result <- x$py_result
  if (format == "csv") {
    py_result$to_csv(file, ...)
  } else if (format == "parquet") {
    py_result$to_parquet(file, ...)
  } else if (format == "npz") {
    py_result$save(file, ...)
  } else {
    stop("Unsupported format: ", format)
  }
  invisible(file)
}
