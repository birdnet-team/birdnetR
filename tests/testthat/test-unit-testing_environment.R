test_that("Can detect proper testing environment", {
  # Basic test that the is_full_test_env function works
  expect_type(is_full_test_env(), "logical")

  # Output helpful message about test environment
  message(sprintf(
    "Testing environment status: %s",
    if (is_full_test_env()) {
      "FULL INTEGRATION TESTS ENABLED"
    } else {
      "LIMITED TESTS ONLY"
    }
  ))
})

test_that("is_full_test_env() does not start Python while integration tests are disabled", {
  withr::local_envvar(BIRDNETR_RUN_INTEGRATION_TESTS = NA)
  testthat::local_mocked_bindings(
    py_module_available = function(...) stop("must not be called"),
    py_available = function(...) stop("must not be called"),
    .package = "reticulate"
  )
  expect_false(suppressMessages(is_full_test_env()))
})
