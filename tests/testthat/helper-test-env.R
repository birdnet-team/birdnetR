# Global testing environment helpers

#' Determine if we're in a full testing environment where we can run integration tests
#'
#' @return Logical indicating if we can run integration tests
is_full_test_env <- function() {
  # birdnet installed
  has_birdnet <- reticulate::py_module_available("birdnet")
  birdnet_message <- if (has_birdnet) {
    "BirdNET: Available"
  } else {
    "BirdNET: Not available"
  }

  # Check if we have internet connection
  has_internet <- curl::has_internet()
  internet_message <- if (has_internet) {
    "Internet: Connected"
  } else {
    "Internet: Not connected"
  }

  # Check if we have the explicit environment variable set
  run_integration_tests <- isTRUE(as.logical(Sys.getenv(
    "BIRDNETR_RUN_INTEGRATION_TESTS",
    "false"
  )))
  integration_message <- if (run_integration_tests) {
    "Integration tests: Enabled"
  } else {
    "Integration tests: Disabled"
  }

  # Determine if we can run full tests
  can_run_full_tests <- isTRUE(
    has_birdnet && has_internet && run_integration_tests
  )

  # Create appropriate status message
  if (can_run_full_tests) {
    message("✓ Full integration testing environment detected")
  } else {
    message("✗ Full integration testing environment not available")

    # List the specific reasons for disabled tests
    reasons <- character()
    if (!has_birdnet) {
      reasons <- c(reasons, "BirdNET Python module not found")
    }
    if (!has_internet) {
      reasons <- c(reasons, "Internet connection not available")
    }
    if (!run_integration_tests) {
      reasons <- c(
        reasons,
        "BIRDNETR_RUN_INTEGRATION_TESTS environment variable not set to TRUE"
      )
    }

    if (length(reasons) > 0) {
      message(
        "  Missing requirements:",
        paste0("\n    - ", reasons, collapse = "")
      )
    }

    # Also show the detailed status
    message("  Environment status:")
    message(sprintf("    %s", birdnet_message))
    message(sprintf("    %s", internet_message))
    message(sprintf("    %s", integration_message))
  }

  return(can_run_full_tests)
}
