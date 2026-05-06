test_that("predict.birdnet_model_acoustic wraps result in correct class", {
  mock_py_predictions <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(predict = function(...) mock_py_predictions),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  result <- predict(model, files = "test.wav")
  expect_s3_class(
    result,
    c("birdnet_prediction_acoustic", "birdnet_prediction")
  )
  expect_false(is.null(result$py_predictions))
})

test_that("predict.birdnet_model_acoustic maps R arguments to Python names", {
  captured_args <- NULL
  mock_py_predictions <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(predict = function(...) {
        captured_args <<- list(...)
        mock_py_predictions
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  predict(model, files = "test.wav", min_confidence = 0.2, overlap = 1.5)

  # R `overlap` maps to Python `overlap_duration_s`
  expect_equal(captured_args$overlap_duration_s, 1.5)
  # R `min_confidence` maps to Python `default_confidence_threshold`
  expect_equal(captured_args$default_confidence_threshold, 0.2)
  # `files` is forwarded as the first positional arg
  expect_equal(captured_args[[1]], "test.wav")
})

test_that("predict.birdnet_model_geo wraps result in correct class", {
  mock_py_predictions <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(predict = function(...) mock_py_predictions),
      model_type = "geo",
      model_version = "2.4"
    ),
    class = c("birdnet_model_geo", "birdnet_model")
  )

  result <- predict(model, latitude = 50.8, longitude = 12.9)
  expect_s3_class(result, c("birdnet_prediction_geo", "birdnet_prediction"))
  expect_false(is.null(result$py_predictions))
})

test_that("predict.birdnet_model_geo forwards arguments to Python", {
  captured_args <- NULL
  mock_py_predictions <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(predict = function(...) {
        captured_args <<- list(...)
        mock_py_predictions
      }),
      model_type = "geo",
      model_version = "2.4"
    ),
    class = c("birdnet_model_geo", "birdnet_model")
  )

  predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    week = 18L,
    min_confidence = 0.05
  )
  expect_equal(captured_args[[1]], 50.8)
  expect_equal(captured_args[[2]], 12.9)
  expect_equal(captured_args$week, 18L)
  expect_equal(captured_args$min_confidence, 0.05)
})

test_that("as.data.frame converts prediction to data frame", {
  mock_df <- data.frame(
    species_name = "Blue Jay",
    confidence = 0.85,
    stringsAsFactors = FALSE
  )
  pred <- structure(
    list(py_predictions = list(to_dataframe = function(...) mock_df)),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  result <- as.data.frame(pred)
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 1)
  expect_equal(result$species_name, "Blue Jay")
})

test_that("as.data.frame errors when no predictions available", {
  pred <- structure(
    list(py_predictions = NULL),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  expect_error(as.data.frame(pred), "No prediction results available")
})
