#' BirdNET for R
#'
#' `birdnetR` is a wrapper around the python package `birdnet`.
#'
#' @import reticulate
#'
#' @docType package
#' @keywords internal
#' @name birdnetR
#' @aliases birdnetR
"_PACKAGE"

## usethis namespace: start
#' @importFrom reticulate py_require import
## usethis namespace: end

# Import the necessary Python modules layzily in .onLoad
py_birdnet <- NULL
py_birdnet_globals <- NULL
py_builtins <- NULL


#' Build the birdnet Python package requirement spec for py_require()
#'
#' Returns a pip-compatible version specifier string for the birdnet Python
#' package. By default this is a bounded range (e.g. `"birdnet>=0.2.16,<0.3"`).
#'
#' If the environment variable `BIRDNETR_BIRDNET_VERSION` is set to a valid
#' exact pin (e.g. `"==0.2.16"`), that pin is used instead. Invalid values
#' produce a warning and fall back to the default range.
#'
#' @return A single character string suitable for `reticulate::py_require()`.
#' @noRd
.birdnet_py_spec <- function() {
  default_spec <- "birdnet>=0.2.16,<0.3"

  override <- trimws(Sys.getenv("BIRDNETR_BIRDNET_VERSION", unset = ""))
  if (nchar(override) == 0L) {
    return(default_spec)
  }

  # Accept only a simple exact pin like "==X.Y.Z"
  if (!grepl("^==[0-9]+\\.[0-9]+\\.[0-9]+$", override)) {
    warning(
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION='",
      override,
      "'. ",
      "Expected a simple exact pin like '==0.2.16'. ",
      "Falling back to default: '",
      default_spec,
      "'.",
      call. = FALSE
    )
    return(default_spec)
  }

  paste0("birdnet", override)
}


#' Initialize birdnetR Package
#'
#' Sets up the Python environment and imports required modules when the birdnetR package is loaded.
#'
#' @param libname Name of the library being loaded.
#' @param pkgname Name of the package being loaded.
#' @param ... Additional arguments.
#' @noRd
.onLoad <- function(libname, pkgname, ...) {
  # set the KERAS_HOME environment variable (dont't write to user home)
  Sys.setenv(KERAS_HOME = tools::R_user_dir("birdnetR", "config"))

  # force reticulate to use an self-managed, ephemeral virtual environment
  Sys.setenv(RETICULATE_PYTHON = "managed")

  # Versions of Python and BirdNET; numpy is automatically installed by `reticulate`.
  # The default spec uses a bounded range (>=0.2.16,<0.3) so that upstream
  # bugfix releases are picked up without a CRAN re-submission.
  # Set BIRDNETR_BIRDNET_VERSION (e.g. "==0.2.16") to override.
  reticulate::py_require(
    .birdnet_py_spec(),
    python_version = ">=3.11,<3.14"
  )

  # Use superassignment to update global reference to the Python packages
  py_birdnet <<- reticulate::import("birdnet", delay_load = TRUE)
  py_birdnet_globals <<- reticulate::import(
    "birdnet.globals",
    delay_load = TRUE
  )
  py_builtins <<- reticulate::import_builtins(delay_load = TRUE)
}
