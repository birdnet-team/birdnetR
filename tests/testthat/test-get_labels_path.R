library(testthat)

tflite_model <- birdnet_model_tflite(version = "v2.4")
protobuf_model <- birdnet_model_protobuf(version = "v2.4")


test_that("get_labels_path returns correct path for valid language", {
  path <- get_labels_path(model = tflite_model, language = "en_us")
  expect_true(basename(path) == "en_us.txt")
  expect_true(file.exists(path))

  path <- get_labels_path(model = protobuf_model, language = "en_us")
  expect_true(basename(path) == "en_us.txt")
  expect_true(file.exists(path))
})

test_that("get_labels_path returns correct path for invalid language", {
  expect_error(get_labels_path(model = tflite_model, language = "blonk"))
  expect_error(get_labels_path(model = protobuf_model, language = "blonk"))
})


test_that("get_labels_path throws an error for character input", {
  expect_error(get_labels_path("invalid_language"))
})

test_that("get_labels_path handles edge cases like empty string or NULL", {
  expect_error(get_labels_path(""))
  expect_error(get_labels_path(NULL))
})

# Missing test for get_labels_path with custom model
