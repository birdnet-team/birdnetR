#' Check Arrow Package Availability
#'
#' This function checks if the Arrow package is installed and available in both R and Python.
#'
#' @return A named logical vector indicating availability in R and Python
#' @keywords internal
#' @noRd
.check_arrow <- function() {
  c(
    r = requireNamespace("arrow", quietly = TRUE),
    python = reticulate::py_module_available("pyarrow")
  )
}

#' Install Apache Arrow
#'
#' This helper function installs Apache Arrow for both R and Python.
#'
#' @return Invisible TRUE if successful, stops with error message if installation fails
#' @export
#' @examples
#' \dontrun{install_arrow()}
install_arrow <- function() {
  arrow_status <- .check_arrow()

  # Install R package if needed
  if (!arrow_status["r"]) {
    message("Installing R package 'arrow'...")
    utils::install.packages("arrow")
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("Failed to install R package 'arrow'. Please install it manually.",
        call. = FALSE
      )
    }
  }

  # Install Python package if needed
  if (!arrow_status["python"]) {
    message("Installing Python package 'pyarrow'...")
    tryCatch(
      {
        reticulate::py_require("pyarrow")
      },
      error = function(error) {
        stop("Failed to install Python package 'pyarrow'. Please install it manually.",
          call. = FALSE
        )
      }
    )
  }

  # Verify final status after a small delay to ensure modules are loaded
  Sys.sleep(1)
  arrow_status <- .check_arrow()
  if (!all(arrow_status)) {
    missing <- names(arrow_status)[!arrow_status]
    stop("Arrow installation failed for: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
