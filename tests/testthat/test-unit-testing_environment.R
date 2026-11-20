test_that("integration tests are off unless the environment variable says so", {
  withr::local_envvar(BIRDNETR_RUN_INTEGRATION_TESTS = NA)
  expect_false(is_full_test_env())
  withr::local_envvar(BIRDNETR_RUN_INTEGRATION_TESTS = "true")
  expect_true(is_full_test_env())
})
