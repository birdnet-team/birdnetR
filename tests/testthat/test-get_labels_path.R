library(testthat)

test_that("get_labels_path returns correct path for valid language", {
  path <- get_labels_path("en_us")
  expect_true(file.exists(path))
})

test_that("get_labels_path throws an error for invalid language", {
  expect_error(get_labels_path("invalid_language"))
})

test_that("get_labels_path handles edge cases like empty string or NULL", {
  expect_error(get_labels_path(""))
  expect_error(get_labels_path(NULL))
})
