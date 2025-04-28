test_that("new_birdnet_model creates proper S3 object", {
  # Mock the reticulate functions to allow our custom mock objects
  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  # Create a mock Python object using our helper
  mock_py_obj <- create_mock_py_object()

  # Test basic model creation
  model <- create_mock_model(version = "v2.4", language = "en_us", model_type = "tflite")
  expect_s3_class(model, c("birdnet_model_tflite", "birdnet_model"))
  expect_equal(model$language, "en_us")
  expect_equal(model$model_version, "v2.4") # Note: it's model_version, not version
})
