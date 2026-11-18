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
#' package. By default this is a bounded range (e.g. `"birdnet>=1.4,<2"`).
#'
#' If the environment variable `BIRDNETR_BIRDNET_VERSION` is set to a valid
#' exact pin (e.g. `"==1.4.0"`), that pin is used instead. Invalid values
#' produce a warning and fall back to the default range.
#'
#' @return A single character string suitable for `reticulate::py_require()`.
#' @noRd
.birdnet_py_spec <- function() {
  default_spec <- "birdnet>=1.4,<2"

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
      "Expected a simple exact pin like '==1.4.0'. ",
      "Falling back to default: '",
      default_spec,
      "'.",
      call. = FALSE
    )
    return(default_spec)
  }

  paste0("birdnet", override)
}


#' Declare an optional birdnet extra (e.g. TensorFlow) on demand
#'
#' Before Python starts, adds `birdnet[<extra>]` with the same version spec as
#' the base requirement, so upstream's platform pins apply. Once Python runs,
#' reticulate only accepts new package names (an extra on `birdnet` counts as
#' a change), so the extra's own package is declared instead and reticulate
#' layers it on top of the running environment (spec section 8.1).
#'
#' @param extra One of `"tf"`, `"pt"`; `"and-cuda"` only before Python starts.
#' @return `invisible(NULL)`
#' @noRd
require_birdnet_extra <- function(extra) {
  if (!reticulate::py_available()) {
    reticulate::py_require(
      sub("^birdnet", paste0("birdnet[", extra, "]"), .birdnet_py_spec())
    )
  } else if (extra == "tf" && is_intel_mac()) {
    # birdnet[tf] also pins pyarrow<26 here, which can't change once Python runs
    stop(
      "On Intel Macs, TensorFlow must be added before Python starts. ",
      "Restart R and make this load your first birdnetR call.",
      call. = FALSE
    )
  } else {
    # mirrors birdnet[tf] / birdnet[pt] in birdnet 1.4
    reticulate::py_require(c(tf = "tensorflow>=2.8.0", pt = "torch>=2.0.0")[[extra]])
  }
  invisible(NULL)
}


#' @noRd
is_intel_mac <- function() {
  p <- platform()
  p[["sysname"]] == "Darwin" && p[["machine"]] == "x86_64"
}


#' Use reticulate's managed environment unless the user chose their own Python
#' @noRd
use_managed_python <- function() {
  if (!nzchar(Sys.getenv("RETICULATE_PYTHON"))) {
    Sys.setenv(RETICULATE_PYTHON = "managed")
  }
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

  # use reticulate's self-managed, ephemeral virtual environment unless the
  # user pointed RETICULATE_PYTHON at their own Python
  use_managed_python()

  # Versions of Python and BirdNET; numpy is automatically installed by `reticulate`.
  # The default spec uses a bounded range (>=1.4,<2) so that upstream
  # bugfix releases are picked up without a CRAN re-submission.
  # Set BIRDNETR_BIRDNET_VERSION (e.g. "==1.4.0") to override.
  # Python stays below 3.14: extras such as birdnet[tf] may be added after
  # Python has started and must resolve on the same interpreter.
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
