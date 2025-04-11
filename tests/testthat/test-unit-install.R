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
