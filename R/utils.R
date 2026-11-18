#' Report the Python environment
#'
#' Summarises the Python environment birdnetR runs on: the Python version and
#' path, the installed `birdnet` Python package version, and which inference
#' runtimes are installed. Useful for debugging environment issues.
#'
#' The character fields and `runtimes` are `NA` (with a warning) when they
#' cannot be determined.
#'
#' @param x A `birdnet_sitrep` object, as returned by `birdnet_sitrep()`.
#' @param ... Ignored.
#' @return `birdnet_sitrep()` returns a list of class `birdnet_sitrep` with
#'   elements:
#' \describe{
#'   \item{python_version}{Character string with the Python version
#'     (e.g. `"3.12.3"`), or `NA` if Python is not available.}
#'   \item{python_executable}{Character string with the path to the
#'     Python executable, or `NA` if Python is not available.}
#'   \item{birdnet_version}{Character string with the installed
#'     `birdnet` package version (e.g. `"1.4.0"`), or `NA` if the
#'     package is not installed.}
#'   \item{runtimes}{Named logical vector, `TRUE` for each of
#'     `onnxruntime`, `ai_edge_litert`, `tensorflow` and `torch` that is
#'     installed (found by importlib, without importing it), `NA` if this
#'     could not be determined.}
#' }
#' `print()` returns `x`, invisibly.
#'
#' @export
#' @examples
#' \dontrun{
#' birdnet_sitrep()
#' }
birdnet_sitrep <- function() {
  py_version <- NA_character_
  py_executable <- NA_character_
  bn_version <- NA_character_

  tryCatch(
    {
      cfg <- reticulate::py_config()
      # version_string is e.g. "3.12.3 (main, ...) [GCC]"; cfg$version is only "3.12"
      py_version <- sub(" .*", "", cfg$version_string)
      py_executable <- cfg$python
    },
    error = \(e) {
      warning(
        "Could not determine Python version: ",
        conditionMessage(e),
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
        "Could not determine birdnet version: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  runtime_names <- c("onnxruntime", "ai_edge_litert", "tensorflow", "torch")
  runtimes <- structure(rep(NA, length(runtime_names)), names = runtime_names)

  # find_spec() looks the module up without importing it (tensorflow and torch
  # are slow to load); reticulate converts Python None to NULL.
  tryCatch(
    {
      util <- reticulate::import("importlib.util", delay_load = FALSE)
      runtimes[] <- vapply(
        runtime_names,
        function(m) !is.null(util$find_spec(m)),
        logical(1)
      )
    },
    error = \(e) {
      warning(
        "Could not determine installed runtimes: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  structure(
    list(
      python_version = py_version,
      python_executable = py_executable,
      birdnet_version = bn_version,
      runtimes = runtimes
    ),
    class = "birdnet_sitrep"
  )
}


#' @rdname birdnet_sitrep
#' @export
print.birdnet_sitrep <- function(x, ...) {
  available <- names(x$runtimes)[x$runtimes %in% TRUE]
  runtimes <- if (anyNA(x$runtimes)) {
    "NA"
  } else if (length(available)) {
    toString(available)
  } else {
    "none"
  }
  cat(
    "python_version: ", x$python_version, "\n",
    "python_executable: ", x$python_executable, "\n",
    "birdnet_version: ", x$birdnet_version, "\n",
    "runtimes: ", runtimes, "\n",
    sep = ""
  )
  invisible(x)
}


# Remove NULL elements from a list.
compact_nulls <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}


# Check whether an object is a single non-missing integer-valued number.
# Accepts both integer and whole-number double values (e.g. 5L or 5).
is_scalar_integer <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x) &&
    x == trunc(x)
}


# Check whether an object is a single non-missing numeric value.
is_scalar_number <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x)
}


# Check whether an object is a single non-missing logical value.
is_scalar_logical <- function(x) {
  is.logical(x) && length(x) == 1L && !is.na(x)
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


# A device spec for the Python backend: "CPU", "GPU", "GPU:1", or several.
is_valid_device <- function(x) {
  is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(x))
}
