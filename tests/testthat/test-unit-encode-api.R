test_that("encode.birdnet_model_acoustic wraps result in correct class", {
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) mock_py_encodings),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  result <- encode(model, files = tmp)
  expect_s3_class(result, "birdnet_encoding")
  expect_false(is.null(result$py_encodings))
})

test_that("encode.birdnet_model_acoustic maps R arguments to Python names", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  encode(model, files = tmp, overlap = 1.5)

  # R `overlap` maps to Python `overlap_duration_s`
  expect_equal(captured_args$overlap_duration_s, 1.5)
  # `files` is forwarded as the first positional arg — must be a list
  expect_type(captured_args[[1]], "list")
  expect_equal(captured_args[[1]][[1]], tmp)
})

test_that("encode.birdnet_model_acoustic errors for missing files", {
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) mock_py_encodings),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  expect_error(
    encode(model, files = "nonexistent_file.wav"),
    "do not exist"
  )
})

test_that("encode.birdnet_model_acoustic forwards multi-file vector as list", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
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

  encode(model, files = c(tmp1, tmp2))

  expect_type(captured_args[[1]], "list")
  expect_length(captured_args[[1]], 2)
})

test_that("encode.birdnet_model_acoustic strips names from files vector", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  named_files <- c(my_file = tmp)

  encode(model, files = named_files)
  expect_null(names(captured_args[[1]]))
})

test_that("encode.birdnet_model_acoustic omits NULL power-user params", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  encode(model, files = tmp)

  expect_false("n_producers" %in% names(captured_args))
  expect_false("n_workers" %in% names(captured_args))
  expect_false("batch_size" %in% names(captured_args))
  expect_false("prefetch_ratio" %in% names(captured_args))
  expect_false("speed" %in% names(captured_args))
  expect_false("half_precision" %in% names(captured_args))
  expect_false("max_audio_duration_min" %in% names(captured_args))

  # Required params should still be present
  expect_false(is.null(captured_args$overlap_duration_s))
  expect_false(is.null(captured_args$bandpass_fmin))
})

test_that("encode.birdnet_model_acoustic forwards non-NULL power-user params", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  encode(
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

test_that("encode.birdnet_model_acoustic validates power-user params", {
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) mock_py_encodings),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  expect_error(encode(model, files = tmp, n_producers = 0L))
  expect_error(encode(model, files = tmp, batch_size = 0L))
  expect_error(encode(model, files = tmp, prefetch_ratio = -1L))
  expect_error(encode(model, files = tmp, speed = 0))
  expect_error(encode(model, files = tmp, speed = 101))
  expect_error(encode(model, files = tmp, half_precision = 1L))
  expect_error(encode(model, files = tmp, max_audio_duration_min = 0))
  expect_error(encode(model, files = tmp, max_audio_duration_min = -5))
})

test_that("encode.birdnet_model_acoustic coerces integer-like doubles", {
  captured_args <- NULL
  mock_py_encodings <- create_mock_py_object()

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  model <- structure(
    list(
      py_model = list(encode = function(...) {
        captured_args <<- list(...)
        mock_py_encodings
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  encode(
    model,
    files = tmp,
    bandpass_fmin = 100,
    bandpass_fmax = 14000,
    n_producers = 2,
    n_workers = 4,
    batch_size = 8,
    prefetch_ratio = 0
  )

  expect_type(captured_args$bandpass_fmin, "integer")
  expect_type(captured_args$bandpass_fmax, "integer")
  expect_type(captured_args$n_producers, "integer")
  expect_type(captured_args$n_workers, "integer")
  expect_type(captured_args$batch_size, "integer")
  expect_type(captured_args$prefetch_ratio, "integer")
})

test_that("as.data.frame converts encoding to data frame", {
  mock_dict <- list(
    input = c("/path/a.wav", "/path/a.wav"),
    start_time = c(0.0, 3.0),
    end_time = c(3.0, 6.0),
    embedding = list(c(0.1, 0.2, 0.3), c(0.4, 0.5, 0.6))
  )

  mock_helper <- list(
    encodings_to_dict = function(py_encodings) mock_dict
  )
  testthat::local_mocked_bindings(get_df_helper = function() mock_helper)

  enc <- structure(
    list(py_encodings = list()),
    class = "birdnet_encoding"
  )

  result <- as.data.frame(enc)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_named(result, c("input", "start_time", "end_time", "embedding"))
  # embedding column is a list
  expect_type(result$embedding, "list")
  expect_equal(result$embedding[[1]], c(0.1, 0.2, 0.3))
})

test_that("as.data.frame.birdnet_encoding errors when no results available", {
  enc <- structure(
    list(py_encodings = NULL),
    class = "birdnet_encoding"
  )

  expect_error(as.data.frame(enc), "No encoding results available")
})

test_that("df_utils.encodings_to_dict converts structured array to R-friendly dict", {
  skip_if_not_installed("reticulate")
  skip_if(!reticulate::py_available(initialize = TRUE), "Python not available")

  mock_enc <- reticulate::py_run_string(
    "
import numpy as np

class MockEncoding:
    def to_structured_array(self):
        emb_dim = 3
        dtype = [
            ('input', object),
            ('start_time', np.float32),
            ('end_time', np.float32),
            ('embedding', np.float32, emb_dim),
        ]
        arr = np.empty(2, dtype=dtype)
        arr['input'] = ['/path/a.wav', '/path/a.wav']
        arr['start_time'] = [0.0, 3.0]
        arr['end_time'] = [3.0, 6.0]
        arr['embedding'] = [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$encodings_to_dict(mock_enc$MockEncoding())

  expect_type(result, "list")
  expect_named(result, c("input", "start_time", "end_time", "embedding"))
  expect_type(result$input, "character")
  expect_length(result$input, 2)

  # embedding should be a list of numeric vectors
  expect_type(result$embedding, "list")
  expect_length(result$embedding, 2)
  expect_equal(
    as.numeric(result$embedding[[1]]),
    c(0.1, 0.2, 0.3),
    tolerance = 1e-4
  )

  # Must produce a valid data.frame
  scalar_data <- result[names(result) != "embedding"]
  df <- as.data.frame(scalar_data, stringsAsFactors = FALSE)
  df$embedding <- result$embedding
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
})
