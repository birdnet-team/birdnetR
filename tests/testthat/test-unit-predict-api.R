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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  result <- predict(model, files = tmp)
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

  # Use a real file so the existence check passes
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  predict(model, files = tmp, min_confidence = 0.2, overlap = 1.5)

  # R `overlap` maps to Python `overlap_duration_s`
  expect_equal(captured_args$overlap_duration_s, 1.5)
  # R `min_confidence` maps to Python `default_confidence_threshold`
  expect_equal(captured_args$default_confidence_threshold, 0.2)
  # `files` is forwarded as the first positional arg — must be a list
  expect_type(captured_args[[1]], "list")
  expect_equal(captured_args[[1]][[1]], tmp)
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

test_that("as.data.frame converts acoustic prediction to data frame", {
  mock_dict <- list(
    species_name = "Blue Jay",
    confidence = 0.85
  )

  mock_helper <- list(
    predictions_to_dict = function(py_predictions, ...) mock_dict
  )
  testthat::local_mocked_bindings(get_df_helper = function() mock_helper)

  pred <- structure(
    list(py_predictions = list()),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  result <- as.data.frame(pred)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$species_name, "Blue Jay")
})

test_that("as.data.frame converts geo prediction to data frame", {
  mock_dict <- list(
    species_name = c("Blue Jay", "House Sparrow"),
    confidence = c(0.85, 0.50)
  )

  captured_kwargs <- NULL
  mock_helper <- list(
    predictions_to_dict = function(py_predictions, ...) {
      captured_kwargs <<- list(...)
      mock_dict
    }
  )
  testthat::local_mocked_bindings(get_df_helper = function() mock_helper)

  pred <- structure(
    list(py_predictions = list()),
    class = c("birdnet_prediction_geo", "birdnet_prediction")
  )

  result <- as.data.frame(pred)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  # Verify sort_by = NULL was passed (not the Python default "species")
  expect_null(captured_kwargs$sort_by)
})

test_that("as.data.frame errors when no predictions available", {
  pred <- structure(
    list(py_predictions = NULL),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  expect_error(as.data.frame(pred), "No prediction results available")
})

test_that("predict.birdnet_model_acoustic forwards multi-file vector as list", {
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

  tmp1 <- withr::local_tempfile(fileext = ".wav")
  tmp2 <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp1)
  file.create(tmp2)

  predict(model, files = c(tmp1, tmp2))

  # First positional arg must be an R list (becomes Python list)
  expect_type(captured_args[[1]], "list")
  expect_length(captured_args[[1]], 2)
  expect_equal(captured_args[[1]][[1]], tmp1)
  expect_equal(captured_args[[1]][[2]], tmp2)
})

test_that("predict.birdnet_model_acoustic errors for missing files", {
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

  expect_error(
    predict(model, files = "nonexistent_file.wav"),
    "do not exist"
  )
})

test_that("predict.birdnet_model_acoustic strips names from files vector", {
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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  named_files <- c(my_file = tmp)

  predict(model, files = named_files)

  # Names must be stripped so reticulate doesn't interpret them as kwargs
  expect_null(names(captured_args[[1]]))
})

test_that("predict.birdnet_model_acoustic omits NULL power-user params from Python call", {
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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  # Call with all power-user params at NULL (default)
  predict(model, files = tmp)

  # Power-user params should NOT appear in captured args
  expect_false("n_producers" %in% names(captured_args))
  expect_false("n_workers" %in% names(captured_args))
  expect_false("batch_size" %in% names(captured_args))
  expect_false("prefetch_ratio" %in% names(captured_args))
  expect_false("speed" %in% names(captured_args))
  expect_false("half_precision" %in% names(captured_args))
  expect_false("max_audio_duration_min" %in% names(captured_args))

  # Required params should still be present
  expect_false(is.null(captured_args$top_k))
  expect_false(is.null(captured_args$apply_sigmoid))
})

test_that("predict.birdnet_model_acoustic forwards non-NULL power-user params", {
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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  predict(
    model,
    files = tmp,
    n_producers = 2L,
    n_workers = 4L,
    batch_size = 8L,
    prefetch_ratio = 2L,
    speed = 1.5,
    half_precision = TRUE,
    max_audio_duration_min = 30
  )

  expect_equal(captured_args$n_producers, 2L)
  expect_equal(captured_args$n_workers, 4L)
  expect_equal(captured_args$batch_size, 8L)
  expect_equal(captured_args$prefetch_ratio, 2L)
  expect_equal(captured_args$speed, 1.5)
  expect_true(captured_args$half_precision)
  expect_equal(captured_args$max_audio_duration_min, 30)
})

test_that("predict.birdnet_model_acoustic validates power-user params", {
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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  # n_producers must be integer >= 1

  expect_error(predict(model, files = tmp, n_producers = 0L))
  expect_error(predict(model, files = tmp, n_producers = 1.5))
  expect_error(predict(model, files = tmp, n_producers = c(1L, 2L)))
  expect_error(predict(model, files = tmp, n_producers = NA_integer_))

  # batch_size must be integer >= 1
  expect_error(predict(model, files = tmp, batch_size = 0L))
  expect_error(predict(model, files = tmp, batch_size = c(1L, 2L)))

  # prefetch_ratio must be integer >= 0
  expect_error(predict(model, files = tmp, prefetch_ratio = -1L))

  # speed must be numeric in [0.01, 100]
  expect_error(predict(model, files = tmp, speed = 0))
  expect_error(predict(model, files = tmp, speed = 101))
  expect_error(predict(model, files = tmp, speed = c(1, 2)))
  expect_error(predict(model, files = tmp, speed = NA_real_))

  # half_precision must be logical
  expect_error(predict(model, files = tmp, half_precision = 1L))
  expect_error(predict(model, files = tmp, half_precision = c(TRUE, FALSE)))
  expect_error(predict(model, files = tmp, half_precision = NA))

  # max_audio_duration_min must be > 0
  expect_error(predict(model, files = tmp, max_audio_duration_min = 0))
  expect_error(predict(model, files = tmp, max_audio_duration_min = -5))
})

test_that("predict.birdnet_model_geo uses min_confidence = 0.03 by default", {
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

  predict(model, latitude = 50.8, longitude = 12.9)
  expect_equal(captured_args$min_confidence, 0.03)
})

test_that("predict.birdnet_model_geo forwards half_precision when non-NULL", {
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

  # Default: half_precision should NOT be forwarded
  predict(model, latitude = 50.8, longitude = 12.9)
  expect_false("half_precision" %in% names(captured_args))

  # Explicit: half_precision should be forwarded
  predict(model, latitude = 50.8, longitude = 12.9, half_precision = TRUE)
  expect_true(captured_args$half_precision)
})

test_that("predict.birdnet_model_geo validates half_precision", {
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

  expect_error(predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = 1L
  ))
  expect_error(predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = c(TRUE, FALSE)
  ))
  expect_error(predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = NA
  ))
})

test_that("df_utils.predictions_to_dict converts structured array to R-friendly dict", {
  skip_if_not_installed("reticulate")
  skip_if(!reticulate::py_available(initialize = TRUE), "Python not available")

  # Build a numpy structured array matching birdnet's geo format
  mock_pred <- reticulate::py_run_string(
    "
import numpy as np

class MockGeoPred:
    def to_structured_array(self, **kwargs):
        dtype = [('species_name', '<U20'), ('confidence', np.float32)]
        arr = np.empty(2, dtype=dtype)
        arr['species_name'] = ['Blue Jay', 'House Sparrow']
        arr['confidence'] = [0.85, 0.50]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$predictions_to_dict(mock_pred$MockGeoPred())

  # Result should be a plain R list
  expect_type(result, "list")
  expect_named(result, c("species_name", "confidence"))

  # String column must be character vector of correct length
  expect_type(result$species_name, "character")
  expect_length(result$species_name, 2)
  expect_equal(result$species_name, c("Blue Jay", "House Sparrow"))

  # Numeric column
  expect_type(result$confidence, "double")
  expect_length(result$confidence, 2)
  expect_equal(as.numeric(result$confidence), c(0.85, 0.50), tolerance = 1e-4)

  # Must produce a valid data.frame
  df <- as.data.frame(result, stringsAsFactors = FALSE)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_true(all(sapply(df, length) == nrow(df)))
})

test_that("df_utils.predictions_to_dict handles multi-file object-dtype input column", {
  skip_if_not_installed("reticulate")
  skip_if(!reticulate::py_available(initialize = TRUE), "Python not available")

  # Build a structured array with object-dtype "input" column (as
  # AcousticFilePredictionResult produces) containing two distinct file paths
  mock_pred <- reticulate::py_run_string(
    "
import numpy as np

class MockMultiFilePred:
    def to_structured_array(self, **kwargs):
        dtype = [
            ('input', object),
            ('start_time', np.float32),
            ('end_time', np.float32),
            ('species_name', object),
            ('confidence', np.float32),
        ]
        arr = np.empty(3, dtype=dtype)
        arr['input'] = ['/path/a.wav', '/path/a.wav', '/path/b.wav']
        arr['start_time'] = [0.0, 3.0, 0.0]
        arr['end_time'] = [3.0, 6.0, 3.0]
        arr['species_name'] = ['Blue Jay', 'House Sparrow', 'Blue Jay']
        arr['confidence'] = [0.85, 0.50, 0.70]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$predictions_to_dict(mock_pred$MockMultiFilePred())

  # input column must be a plain character vector

  expect_type(result$input, "character")
  expect_length(result$input, 3)
  expect_equal(result$input, c("/path/a.wav", "/path/a.wav", "/path/b.wav"))

  # species_name column must also be character
  expect_type(result$species_name, "character")

  # should produce a valid data.frame
  df <- as.data.frame(result, stringsAsFactors = FALSE)
  expect_s3_class(df, "data.frame")

  expect_equal(nrow(df), 3)
  # Both files present
  expect_equal(sort(unique(df$input)), c("/path/a.wav", "/path/b.wav"))
})

# --- Regression: integer-like doubles must be coerced to R integer ----------

test_that("predict.birdnet_model_acoustic coerces integer-like doubles to integer", {
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

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  # Pass whole-number doubles (not L-suffixed) — the bug scenario
  predict(
    model,
    files = tmp,
    top_k = 1,
    bandpass_fmin = 100,
    bandpass_fmax = 14000,
    n_producers = 2,
    n_workers = 4,
    batch_size = 8,
    prefetch_ratio = 0
  )

  # All integer params must arrive as R integer, not double

  expect_type(captured_args$top_k, "integer")
  expect_type(captured_args$bandpass_fmin, "integer")
  expect_type(captured_args$bandpass_fmax, "integer")
  expect_type(captured_args$n_producers, "integer")
  expect_type(captured_args$n_workers, "integer")
  expect_type(captured_args$batch_size, "integer")
  expect_type(captured_args$prefetch_ratio, "integer")

  # Values must be preserved
  expect_equal(captured_args$top_k, 1L)
  expect_equal(captured_args$bandpass_fmin, 100L)
  expect_equal(captured_args$bandpass_fmax, 14000L)
  expect_equal(captured_args$n_producers, 2L)
})

test_that("predict.birdnet_model_geo coerces integer-like week to integer", {
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

  # Pass week as a double, not 18L
  predict(model, latitude = 50.8, longitude = 12.9, week = 18)

  expect_type(captured_args$week, "integer")
  expect_equal(captured_args$week, 18L)
})

test_that("predict.birdnet_model_geo leaves week as NULL when not provided", {
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

  predict(model, latitude = 50.8, longitude = 12.9)
  expect_null(captured_args$week)
})
