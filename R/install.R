#' Get the Required BirdNET Version
#'
#' This internal function returns the required version of the BirdNET Python package.
#' Update this function with the new required version when the package is updated.
#'
#' @return A string representing the required BirdNET version.
#' @keywords internal
.required_birdnet_version <- function() {
  "0.1.6"
}

#' Get the Suggested Python Version
#'
#' This internal function returns the suggested version of Python to be used with the BirdNET package.
#' Update this function with the new suggested version when necessary.
#'
#' @return A string representing the suggested Python version.
#' @keywords internal
.suggested_python_version <- function() {
  "3.11"
}

#' Check Arrow Package Availability
#'
#' This function checks if the Arrow package is installed and available in both R and Python.
#'
#' @return A named logical vector indicating availability in R and Python
#' @keywords internal
.check_arrow <- function() {
  c(
    r = requireNamespace("arrow", quietly = TRUE),
    python = reticulate::py_module_available("pyarrow")
  )
}

#' Check the Installed birdnet Version
#'
#' This internal function checks if birdnet Python is installed and if the version matches the requirement.
#' If it is not available or if the versions do not match, issue a warning with instructions to update the package.
#'
#' @keywords internal
#' @return None. This function is called for its side effect of stopping execution if the wrong version is installed.
.check_birdnet_version <- function() {
  available_py_packages <- tryCatch(
    {
      reticulate::py_list_packages()
    },
    error = function(error) {
      NULL
    }
  )

  if (is.null(available_py_packages)) {
    message("No Python environment available. To install, use `install_birdnet()`.")
    return()
  }

  installed_birdnet_version <- tryCatch(
    {
      # we need to set `package` to NULL, to bin it to a variable. Otherwise R CMD check will throw a note "No visible binding for global variable 'package' "
      package <- NULL
      subset(available_py_packages, package == "birdnet")$version
    },
    error = function(error) {
      NULL
    }
  )

  if (is.null(installed_birdnet_version) ||
    length(installed_birdnet_version) == 0) {
    message("No version of birdnet found. To install, use `install_birdnet()`.")
    return()
  }

  if (installed_birdnet_version != .required_birdnet_version()) {
    warning(
      sprintf(
        "BirdNET version %s is installed, but %s is required. To update, use `install_birdnet()`.",
        installed_birdnet_version,
        .required_birdnet_version()
      )
    )
  }
}

#' Install Apache Arrow
#'
#' This helper function installs Apache Arrow for both R and Python.
#'
#' @param envname Name of the virtual environment. Defaults to 'r-birdnet'.
#' @return Invisible TRUE if successful, stops with error message if installation fails
#' @export
#' @examplesIf interactive()
install_arrow <- function(envname = "r-birdnet") {
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
        reticulate::py_install("pyarrow", envname = envname)
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

#' Install BirdNET and its dependencies
#'
#' `install_birdnet()` installs the python package `birdnet` from PyPi into a virtual environment.
#'
#' @param ... Further arguments passed to `reticulate::py_install()`
#' @param method Installation method. Defaults to 'virtualenv' on macOS and Linux, and 'auto' on Windows. See `reticulate::py_install()` for more details.
#' @param envname Name of the virtual environment.
#' @param new_env If `TRUE`, any existing Python virtual environment specified by `envname` is deleted first.
#' @param include_arrow If `TRUE`, also installs the Apache Arrow for both R and Python for optimized data conversion. Arrow can be installed later using `install_arrow()`.
#'
#' @export
install_birdnet <- function(...,
                            method = NULL,
                            envname = "r-birdnet",
                            new_env = identical(envname, "r-birdnet"),
                            include_arrow = FALSE) {
  os <- Sys.info()[["sysname"]]
  method <- if (!is.null(method)) {
    method
  } else {
    switch(os,
      "Darwin" = "virtualenv",
      "Windows" = "auto",
      "Linux" = "virtualenv",
      stop("Unsupported operating system")
    )
  }

  # Try to use python 3.11. the request is taken as a hint only, and scanning for other versions will still proceed
  reticulate::use_python_version(.suggested_python_version(), required = FALSE)

  if (new_env && reticulate::virtualenv_exists(envname)) {
    reticulate::virtualenv_remove(envname)
  }

  # Let the system automatically discover if the correct python version is installed
  # if not the user will be prompted with options to install a correct version
  tryCatch(
    {
      reticulate::py_install("birdnet", envname = envname, method = method, ...)
    },
    error = function(error) { # error object contains details about what went wrong
      stop("Failed to install BirdNET. Error: ", error$message)
    }
  )

  # Install Arrow if requested
  if (include_arrow) {
    message("Installing Arrow packages...")
    tryCatch(
      {
        install_arrow(envname = envname)
      },
      error = function(error) {
        warning("Failed to install Arrow packages. This won't affect BirdNET functionality, but data conversion might be slower. Error: ", error$message)
      }
    )
  }

  if (os == "Darwin") {
    # Try to install Metal plugin for GPU support
    tryCatch(
      {
        reticulate::py_install("tensorflow-metal", envname = envname)
        message("Enabled GPU support.")
      },
      error = function(error) {
        message(
          "Failed to install Metal plugin for GPU support. Error: ",
          error$message
        )
      }
    )
  }

  message("BirdNET installed successfully!")
}
