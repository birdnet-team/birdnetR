# Helper functions for testing
mock_for_install_tests <- function() {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) TRUE,
    .package = "birdnetR"
  )

  testthat::local_mocked_bindings(
    py_module_available = function(...) TRUE,
    .package = "reticulate"
  )
}

test_that(".check_arrow correctly detects arrow availability", {
  # Mock both R and Python arrow are available
  testthat::local_mocked_bindings(
    requireNamespace = function(...) TRUE,
    .package = "base"
  )

  testthat::local_mocked_bindings(
    py_module_available = function(...) TRUE,
    .package = "reticulate"
  )

  # Test when both R and Python arrow are available
  result <- .check_arrow()
  expect_length(result, 2)
  expect_true(result["r"])
  expect_true(result["python"])

  # Test when R arrow is not available
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )

  result <- .check_arrow()
  expect_false(result["r"])
  expect_true(result["python"])

  # Test when Python arrow is not available
  testthat::local_mocked_bindings(
    py_module_available = function(...) FALSE,
    .package = "reticulate"
  )

  result <- .check_arrow()
  expect_false(result["r"])
  expect_false(result["python"])
})

test_that(".required_birdnet_version returns a valid version string", {
  version <- .required_birdnet_version()
  expect_type(version, "character")
  expect_length(version, 1)
  # Should match semver format (e.g., "0.1.7")
  expect_match(version, "^\\d+\\.\\d+\\.\\d+$")
})

test_that(".suggested_python_version returns a valid version string", {
  version <- .suggested_python_version()
  expect_type(version, "character")
  expect_length(version, 1)
  # Should match major.minor format (e.g., "3.11")
  expect_match(version, "^\\d+\\.\\d+$")
})

test_that(".check_birdnet_version handles correct version case", {
  # Create a mock of py_list_packages that returns a data frame with the correct version
  testthat::local_mocked_bindings(
    py_list_packages = function() {
      data.frame(
        package = c("birdnet", "numpy"),
        version = c(.required_birdnet_version(), "1.23.5"),
        stringsAsFactors = FALSE
      )
    },
    .package = "reticulate"
  )

  # Should not produce any warnings when the version matches
  expect_silent(.check_birdnet_version())
})

test_that(".check_birdnet_version warns on version mismatch", {
  # Create a mock of py_list_packages that returns a data frame with an incorrect version
  testthat::local_mocked_bindings(
    py_list_packages = function() {
      data.frame(
        package = c("birdnet", "numpy"),
        version = c("0.0.1", "1.23.5"),
        stringsAsFactors = FALSE
      )
    },
    .package = "reticulate"
  )

  # Should produce a warning when versions don't match
  expect_warning(.check_birdnet_version(), "is required")
})

test_that(".check_birdnet_version handles missing birdnet", {
  # Create a mock of py_list_packages that returns a data frame without birdnet
  testthat::local_mocked_bindings(
    py_list_packages = function() {
      data.frame(
        package = c("numpy"),
        version = c("1.23.5"),
        stringsAsFactors = FALSE
      )
    },
    .package = "reticulate"
  )

  # Should produce a message when birdnet is not installed
  expect_message(.check_birdnet_version(), "No version of birdnet found")
})

test_that(".check_birdnet_version handles Python environment errors", {
  # Create a mock of py_list_packages that throws an error
  testthat::local_mocked_bindings(
    py_list_packages = function() stop("Python environment error"),
    .package = "reticulate"
  )

  # Should produce a message when Python environment is not available
  expect_message(.check_birdnet_version(), "No Python environment available")
})
