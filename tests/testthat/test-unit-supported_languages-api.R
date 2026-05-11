# Unit API contract tests for supported_languages()
# These run without Python by mocking py_birdnet_globals.

test_that("supported_languages() returns a character vector", {
  mock_globals <- list(
    VALID_MODEL_LANGUAGES = c("en_us", "de", "fr", "es")
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_languages()

  expect_type(result, "character")
  expect_true(length(result) > 0)
})

test_that("supported_languages() returns the exact values from Python globals", {
  expected <- c("en_us", "de", "fr", "es", "pt")

  mock_globals <- list(
    VALID_MODEL_LANGUAGES = expected
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_languages()
  expect_equal(result, expected)
})

test_that("supported_languages() takes no arguments", {
  expect_equal(length(formals(supported_languages)), 0)
})
