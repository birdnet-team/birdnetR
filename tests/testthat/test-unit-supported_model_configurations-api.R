# Unit API contract tests for supported_model_configurations()
# These run without Python by mocking py_birdnet_globals.

test_that("supported_model_configurations() returns a data frame with expected columns", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_named(result, c("type", "version", "backend", "library", "precision"))
})

test_that("supported_model_configurations() includes both acoustic and geo types", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()

  expect_true("acoustic" %in% result$type)
  expect_true("geo" %in% result$type)
})

test_that("supported_model_configurations() prunes library for non-tf backends", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()

  pb_rows <- result[result$backend == "pb", ]
  expect_true(all(is.na(pb_rows$library)))

  tf_rows <- result[result$backend == "tf", ]
  expect_true(all(!is.na(tf_rows$library)))
})

test_that("supported_model_configurations() forces fp32 for pb backend and geo type", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()

  pb_rows <- result[result$backend == "pb", ]
  expect_true(all(pb_rows$precision == "fp32"))

  geo_rows <- result[result$type == "geo", ]
  expect_true(all(geo_rows$precision == "fp32"))
})

test_that("supported_model_configurations(compact = TRUE) returns compacted output", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations(compact = TRUE)
  full <- supported_model_configurations(compact = FALSE)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  # Compact version should have fewer or equal rows

  expect_true(nrow(result) <= nrow(full))
  # Collapsed columns should contain colon-separated values
  expect_named(result, c("type", "version", "backend", "precision", "library"))
})

test_that("supported_model_configurations() returns no duplicate rows", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = "2.4",
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()
  expect_equal(nrow(result), nrow(unique(result)))
})

test_that("supported_model_configurations() excludes acoustic version 2 even if present in globals", {
  mock_globals <- list(
    VALID_MODEL_TYPES = c("acoustic", "geo"),
    VALID_ACOUSTIC_MODEL_VERSIONS = c("2", "2.4"),
    VALID_GEO_MODEL_VERSIONS = "2.4",
    VALID_MODEL_BACKENDS = c("tf", "pb"),
    VALID_LIBRARY_TYPES = c("litert", "tflite"),
    VALID_MODEL_PRECISIONS = c("int8", "fp16", "fp32"),
    MODEL_PRECISION_FP32 = "fp32"
  )

  testthat::local_mocked_bindings(
    py_birdnet_globals = mock_globals,
    .package = "birdnetR"
  )

  result <- supported_model_configurations()

  acoustic_rows <- result[result$type == "acoustic", ]
  expect_false("2" %in% acoustic_rows$version)
  expect_true("2.4" %in% acoustic_rows$version)
})
