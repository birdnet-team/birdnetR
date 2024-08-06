#' Get the Required BirdNET Version
#'
#' This internal function returns the required version of the BirdNET Python package.
#' Update this function with the new required version when the package is updated.
#'
#' @return A string representing the required BirdNET version.
#' @keywords internal
#'
#' @examples
#' .required_birdnet_version()
.required_birdnet_version <- function() {
  "0.1.1"
}

#' Get the Suggested Python Version
#'
#' This internal function returns the suggested version of Python to be used with the BirdNET package.
#' Update this function with the new suggested version when necessary.
#'
#' @return A string representing the suggested Python version.
#' @keywords internal
#'
#' @examples
#' .suggested_python_version()
.suggested_python_version <- function() {
  "3.11"
}

#' Install BirdNET and its dependencies
#'
#' `install_birdnet()` installs the python package `birdnet` from PyPi into a virtual environment.
#'
#'
#' @param ... Further arguments passed to `reticulate::py_install()`
#' @param envname Name of the virtual environment. Defaults to 'r-birdnet'.
#' @param new_env If `TRUE`, any existing Python virtual environment specified by `envname` is deleted first.
#'
#'
#' @export
install_birdnet <- function(
  ...,
  envname = "r-birdnet",
  new_env = identical(envname, "r-birdnet")
) {

  # Try to use python 3.11. the request is taken as a hint only, and scanning for other versions will still proceed
  reticulate::use_python_version(.suggested_python_version(), required = FALSE)

  if (new_env && reticulate::virtualenv_exists(envname)) {
    reticulate::virtualenv_remove(envname)
  }

  # Let the system automatically discover if the correct python version is installed
  # if not the user will be prompted with options to install a correct version
  reticulate::py_install(
    paste0("birdnet==", .required_birdnet_version()),
    envname = envname,
    ...
  )
}
#TODO check for version in virtualenv. In which functions?

