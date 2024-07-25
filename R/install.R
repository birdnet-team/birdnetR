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
  use_python_version("3.11", required = FALSE)

  if (new_env && virtualenv_exists(envname)) {
    virtualenv_remove(envname)
  }

  # Let the system automatically discover if the correct python version is installed
  # if not the user will be prompted with options to install a correct version
  reticulate::py_install(
    "birdnet==0.1.0",
    envname = envname,
    ...
  )
}
