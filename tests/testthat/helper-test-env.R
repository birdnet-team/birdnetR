# Global testing environment helpers

#' Determine if we're in a full testing environment where we can run integration tests
#'
#' @return Logical indicating if we can run integration tests
is_full_test_env <- function() {
  # The explicit environment variable comes first: probing for the birdnet
  # module starts Python (and, under R CMD check, builds the managed
  # environment), which must not happen unless integration tests are wanted.
  run_integration_tests <- isTRUE(as.logical(Sys.getenv(
    "BIRDNETR_RUN_INTEGRATION_TESTS",
    "false"
  )))
  if (!run_integration_tests) {
    message("\u2717 Full integration testing environment not available")
    message(
      "  Missing requirements:\n",
      "    - BIRDNETR_RUN_INTEGRATION_TESTS environment variable not set to TRUE"
    )
    return(FALSE)
  }

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

  # Determine if we can run full tests
  can_run_full_tests <- isTRUE(has_birdnet && has_internet)

  # Create appropriate status message
  if (can_run_full_tests) {
    message("\u2713 Full integration testing environment detected")
  } else {
    message("\u2717 Full integration testing environment not available")

    # List the specific reasons for disabled tests
    reasons <- character()
    if (!has_birdnet) {
      reasons <- c(reasons, "BirdNET Python module not found")
    }
    if (!has_internet) {
      reasons <- c(reasons, "Internet connection not available")
    }

    message(
      "  Missing requirements:",
      paste0("\n    - ", reasons, collapse = "")
    )

    # Also show the detailed status
    message("  Environment status:")
    message(sprintf("    %s", birdnet_message))
    message(sprintf("    %s", internet_message))
  }

  return(can_run_full_tests)
}
