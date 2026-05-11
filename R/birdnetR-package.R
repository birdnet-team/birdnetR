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
  # To prevent conflicts, we specify a version range according to `birdnet`python.
  reticulate::py_require(
    "birdnet==0.2.15",
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
