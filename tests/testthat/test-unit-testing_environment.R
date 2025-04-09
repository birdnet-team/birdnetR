test_that("Can detect proper testing environment", {
  # Basic test that the is_full_test_env function works
  expect_type(is_full_test_env(), "logical")
  
  # Output helpful message about test environment
  message(sprintf(
    "Testing environment status: %s",
    if (is_full_test_env()) "FULL INTEGRATION TESTS ENABLED" else "LIMITED TESTS ONLY"
  ))
})