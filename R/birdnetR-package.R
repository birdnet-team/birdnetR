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
py_birdnet_models <- NULL
py_birdnet_utils <- NULL
py_birdnet_audio_based_prediction <- NULL
py_birdnet_location_based_prediction <- NULL
py_birdnet_types <- NULL
py_pathlib <- NULL
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
    c(
      "numpy>=1.23.5,<2.0.0",
      "birdnet==0.1.7"
    ),
    python_version = ">=3.9,<3.12"
  )

  # Use superassignment to update global reference to the Python packages
  py_birdnet_models <<- reticulate::import("birdnet.models", delay_load = TRUE) # list(before_load = .check_birdnet_version()
  py_birdnet_utils <<- reticulate::import("birdnet.utils", delay_load = TRUE)
  py_birdnet_audio_based_prediction <<- reticulate::import("birdnet.audio_based_prediction", delay_load = TRUE)
  py_birdnet_location_based_prediction <<- reticulate::import("birdnet.location_based_prediction", delay_load = TRUE)
  py_birdnet_types <<- reticulate::import("birdnet.types", delay_load = TRUE)
  py_pathlib <<- reticulate::import("pathlib", delay_load = TRUE)
  py_builtins <<- reticulate::import_builtins(delay_load = TRUE)
}
