#' Report Python and birdnet Version Information
#'
#' Returns the Python executable path, Python version, and installed
#' `birdnet` Python package version as a named list. Useful for
#' debugging environment issues.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{python_version}{Character string with the Python version
#'     (e.g. `"3.12.3"`), or `NA` if Python is not available.}
#'   \item{python_executable}{Character string with the path to the
#'     Python executable, or `NA` if Python is not available.}
#'   \item{birdnet_version}{Character string with the installed
#'     `birdnet` package version (e.g. `"0.2.16"`), or `NA` if the
#'     package is not installed.}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' birdnet_version()
#' }
birdnet_version <- function() {
  py_version <- NA_character_
  py_executable <- NA_character_
  bn_version <- NA_character_

  tryCatch(
    {
      cfg <- reticulate::py_config()
      py_version <- cfg$version
      py_executable <- cfg$python
    },
    error = \(e) {
      warning(
        "Could not determine Python version: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  tryCatch(
    {
      importlib <- reticulate::import("importlib.metadata", delay_load = FALSE)
      bn_version <- importlib$version("birdnet")
    },
    error = \(e) {
      warning(
        "Could not determine birdnet version: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  list(
    python_version = py_version,
    python_executable = py_executable,
    birdnet_version = bn_version
  )
}


#' Check if an Object is a Valid Species List
#'
#' This internal function checks if an object is either a character vector of length greater than 0
#' or a list where each element is a single non-empty character string.
#'
#' @param obj The object to check. This can be either a character vector or a list.
#' @return A logical value indicating whether the object is a valid species list:
#' \itemize{
#'   \item `TRUE` if the object is a character vector of length > 0 or a list with each element being a single character string.
#'   \item `FALSE` otherwise.
#' }
#' @noRd
#' @note This function is intended for internal use and may not be exported or accessible for external users.
#' @examples
#' is_valid_species_list(c("species1", "species2")) # TRUE
#' is_valid_species_list(list("species1", "species2")) # TRUE
#' is_valid_species_list(c(1, 2, 3)) # FALSE
#' is_valid_species_list(list(a = 1, b = 2)) # FALSE
#'
is_valid_species_list <- function(obj) {
  # Check if the object is a character vector of length > 0 and not a list
  is_vector <- is.vector(obj) &&
    length(obj) > 0 &&
    !is.list(obj) &&
    is.character(obj)

  # Check if the object is a non-empty list where each element is a single character string
  is_list_single_elements <- is.list(obj) &&
    length(obj) > 0 &&
    all(sapply(obj, function(x) {
      is.character(x) && length(x) == 1 && length(x) != 0
    }))

  # Return TRUE if either condition is met
  return(is_vector || is_list_single_elements)
}

#' Check if an Object is a Valid Minimum Confidence List
#' This internal function checks if an object is a named list where each element is a single numeric value.
#' @param obj The object to check.
#' @noRd
#' @return A logical value indicating whether the object is a valid minimum confidence list
#' @examples
#' is_valid_min_confidence_list(list(species1 = 0.5, species2 = 0.7)) # TRUE
#' is_valid_min_confidence_list(list(species1 = c(0.5, 0.7))) # FALSE
#' is_valid_min_confidence_list(list(species1 = "0.5")) # FALSE
#' is_valid_min_confidence_list(list()) # FALSE
#' is_valid_min_confidence_list(c(0.5, 0.7)) # FALSE
#' is_valid_min_confidence_list("species1") # FALSE
#' is_valid_min_confidence_list(NULL) # FALSE
#' is_valid_min_confidence_list(0.5) # FALSE
#' is_valid_min_confidence_list(NA) # FALSE

is_valid_min_confidence_list <- function(obj) {
  is_named_list <- is.list(obj) &&
    !is.null(names(obj)) &&
    length(obj) > 0 &&
    all(sapply(obj, function(x) is.numeric(x) && length(x) == 1))

  return(is_named_list)
}
