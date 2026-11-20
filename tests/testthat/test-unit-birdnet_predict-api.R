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

  result <- birdnet_predict(model, files = tmp)
  expect_equal(
    class(result),
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

  birdnet_predict(model, files = tmp, min_confidence = 0.2, overlap = 1.5)

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

  result <- birdnet_predict(model, latitude = 50.8, longitude = 12.9)
  expect_equal(class(result), c("birdnet_prediction_geo", "birdnet_prediction"))
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

  birdnet_predict(
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

  birdnet_predict(model, files = c(tmp1, tmp2))

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
    birdnet_predict(model, files = "nonexistent_file.wav"),
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

  birdnet_predict(model, files = named_files)

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
  birdnet_predict(model, files = tmp)

  # Power-user params should NOT appear in captured args
  expect_false("n_producers" %in% names(captured_args))
  expect_false("n_workers" %in% names(captured_args))
  expect_false("batch_size" %in% names(captured_args))
  expect_false("prefetch_ratio" %in% names(captured_args))
  expect_false("speed" %in% names(captured_args))
  expect_false("half_precision" %in% names(captured_args))
  expect_false("max_audio_duration_min" %in% names(captured_args))

  # Required params should still be present; apply_sigmoid now defaults to
  # the model's own setting and is omitted
  expect_false(is.null(captured_args$top_k))
  expect_null(captured_args$apply_sigmoid)

  # top_k = NULL is forwarded (as None), not dropped
  birdnet_predict(model, files = tmp, top_k = NULL)
  expect_true("top_k" %in% names(captured_args))
  expect_null(captured_args$top_k)
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

  birdnet_predict(
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

  expect_error(birdnet_predict(model, files = tmp, n_producers = 0L), "`n_producers` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, n_producers = 1.5), "`n_producers` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, n_producers = c(1L, 2L)), "`n_producers` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, n_producers = NA_integer_), "`n_producers` must be", fixed = TRUE)

  # batch_size must be integer >= 1
  expect_error(birdnet_predict(model, files = tmp, batch_size = 0L), "`batch_size` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, batch_size = c(1L, 2L)), "`batch_size` must be", fixed = TRUE)

  # prefetch_ratio must be integer >= 0
  expect_error(birdnet_predict(model, files = tmp, prefetch_ratio = -1L), "`prefetch_ratio` must be", fixed = TRUE)

  # speed must be numeric in [0.01, 100]
  expect_error(birdnet_predict(model, files = tmp, speed = 0), "`speed` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, speed = 101), "`speed` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, speed = c(1, 2)), "`speed` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, speed = NA_real_), "`speed` must be", fixed = TRUE)

  # half_precision must be logical
  expect_error(birdnet_predict(model, files = tmp, half_precision = 1L), "`half_precision` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, half_precision = c(TRUE, FALSE)), "`half_precision` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, half_precision = NA), "`half_precision` must be", fixed = TRUE)

  # max_audio_duration_min must be > 0
  expect_error(birdnet_predict(model, files = tmp, max_audio_duration_min = 0), "`max_audio_duration_min` must be", fixed = TRUE)
  expect_error(birdnet_predict(model, files = tmp, max_audio_duration_min = -5), "`max_audio_duration_min` must be", fixed = TRUE)
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

  birdnet_predict(model, latitude = 50.8, longitude = 12.9)
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
  birdnet_predict(model, latitude = 50.8, longitude = 12.9)
  expect_false("half_precision" %in% names(captured_args))

  # Explicit: half_precision should be forwarded
  birdnet_predict(model, latitude = 50.8, longitude = 12.9, half_precision = TRUE)
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

  expect_error(birdnet_predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = 1L
  ), "`half_precision` must be", fixed = TRUE)
  expect_error(birdnet_predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = c(TRUE, FALSE)
  ), "`half_precision` must be", fixed = TRUE)
  expect_error(birdnet_predict(
    model,
    latitude = 50.8,
    longitude = 12.9,
    half_precision = NA
  ), "`half_precision` must be", fixed = TRUE)
})

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
  birdnet_predict(
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
  birdnet_predict(model, latitude = 50.8, longitude = 12.9, week = 18)

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

  birdnet_predict(model, latitude = 50.8, longitude = 12.9)
  expect_null(captured_args$week)
})

# --- 1.0: model defaults, new arguments, removed predict() methods ----------

local_capturing_model <- function(type = c("acoustic", "geo"), env = parent.frame()) {
  type <- match.arg(type)
  cap <- new.env()
  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate",
    .env = env
  )
  model <- structure(
    list(
      py_model = list(predict = function(...) {
        cap$args <- list(...)
        create_mock_py_object()
      }),
      model_type = type,
      model_version = "3.0"
    ),
    class = c(paste0("birdnet_model_", type), "birdnet_model")
  )
  list(model = model, cap = cap)
}

test_that("apply_sigmoid and sigmoid_sensitivity are omitted when NULL (model default applies)", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  birdnet_predict(m$model, files = tmp)
  expect_false(any(
    c("apply_sigmoid", "sigmoid_sensitivity", "apply_softmax", "segment_size_s", "device") %in%
      names(m$cap$args)
  ))
})

test_that("new acoustic arguments are forwarded when set", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  birdnet_predict(
    m$model, files = tmp, apply_sigmoid = FALSE, sigmoid_sensitivity = 1.25,
    apply_softmax = TRUE, segment_size_s = 5, device = "GPU"
  )
  expect_equal(
    m$cap$args[c("apply_sigmoid", "sigmoid_sensitivity", "apply_softmax", "segment_size_s", "device")],
    list(
      apply_sigmoid = FALSE, sigmoid_sensitivity = 1.25, apply_softmax = TRUE,
      segment_size_s = 5, device = "GPU"
    )
  )
})

test_that("a GPU device defaults n_workers to one worker per device", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  birdnet_predict(m$model, files = tmp, device = "GPU")
  expect_identical(m$cap$args$n_workers, 1L)
  birdnet_predict(m$model, files = tmp, device = c("GPU:0", "GPU:1"))
  expect_identical(m$cap$args$n_workers, 2L)
  birdnet_predict(m$model, files = tmp, device = "GPU", n_workers = 3L)
  expect_identical(m$cap$args$n_workers, 3L)
  birdnet_predict(m$model, files = tmp, device = "CPU")
  expect_null(m$cap$args$n_workers)
})

test_that("new acoustic arguments are validated", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  expect_error(birdnet_predict(m$model, files = tmp, apply_softmax = "yes"), "`apply_softmax` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, segment_size_s = 0), "`segment_size_s` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, sigmoid_sensitivity = -1), "`sigmoid_sensitivity` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, device = character()), "`device` must be", fixed = TRUE)
})

test_that("geo forwards year_round_aggregation and device when set, omits them when NULL", {
  m <- local_capturing_model("geo")
  birdnet_predict(m$model, latitude = 50.8, longitude = 12.9)
  expect_false(any(c("year_round_aggregation", "device") %in% names(m$cap$args)))
  birdnet_predict(
    m$model, latitude = 50.8, longitude = 12.9,
    year_round_aggregation = "average", device = "CPU"
  )
  expect_equal(m$cap$args$year_round_aggregation, "average")
  expect_equal(m$cap$args$device, "CPU")
  expect_error(birdnet_predict(m$model, latitude = 50.8, longitude = 12.9, year_round_aggregation = "median"), "should be one of")
})

test_that("predict() methods are gone", {
  ns <- asNamespace("birdnetR")
  expect_false(exists("predict.birdnet_model_acoustic", envir = ns, inherits = FALSE))
  expect_false(exists("predict.birdnet_model_geo", envir = ns, inherits = FALSE))
})

test_that("predict.birdnet_model_acoustic expands ~ in file paths before forwarding them", {
  skip_on_os("windows") # ~ expansion follows HOME on Unix only
  captured_args <- NULL
  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )
  model <- structure(
    list(
      py_model = list(predict = function(...) {
        captured_args <<- list(...)
        create_mock_py_object()
      }),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  home <- withr::local_tempdir()
  withr::local_envvar(HOME = home)
  file.create(file.path(home, "tilde.wav"))

  birdnet_predict(model, files = "~/tilde.wav")
  expect_equal(captured_args[[1]][[1]], file.path(home, "tilde.wav"))
})

test_that("unknown arguments are an error instead of vanishing in `...`", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  # argument names of birdnetR 0.3.2
  expect_error(
    birdnet_predict(m$model, files = tmp, filter_species = "a_b", chunk_overlap_s = 1),
    "Unknown arguments: `filter_species`, `chunk_overlap_s`",
    fixed = TRUE
  )
  expect_error(birdnet_predict(m$model, files = tmp, topk = 1), "Unknown argument: `topk`", fixed = TRUE)
  expect_null(m$cap$args)

  geo <- local_capturing_model("geo")
  expect_error(
    birdnet_predict(geo$model, latitude = 50.8, longitude = 12.9, weak = 18),
    "Unknown argument: `weak`",
    fixed = TRUE
  )
})

test_that("files may be a list of paths, but not empty or non-character", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  birdnet_predict(m$model, files = list(tmp, tmp))
  expect_equal(m$cap$args[[1]], list(tmp, tmp))
  expect_error(birdnet_predict(m$model, files = character()), "`files` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = 1), "`files` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = NA_character_), "`files` must be", fixed = TRUE)
})

test_that("species_list becomes a Python set and min_confidence_custom a dict", {
  m <- local_capturing_model("acoustic")
  testthat::local_mocked_bindings(
    py_builtins = list(
      set = function(x) structure(list(x), class = "fake_set"),
      dict = function(x) structure(list(x), class = "fake_dict")
    ),
    .package = "birdnetR"
  )
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)

  birdnet_predict(m$model, files = tmp)
  expect_null(m$cap$args$custom_species_list)
  expect_null(m$cap$args$custom_confidence_thresholds)
  expect_true(all(c("custom_species_list", "custom_confidence_thresholds") %in% names(m$cap$args)))

  birdnet_predict(
    m$model, files = tmp,
    species_list = c("a_A", "b_B"), min_confidence_custom = list(a_A = 0.5)
  )
  expect_s3_class(m$cap$args$custom_species_list, "fake_set")
  expect_equal(m$cap$args$custom_species_list[[1]], list("a_A", "b_B"))
  expect_s3_class(m$cap$args$custom_confidence_thresholds, "fake_dict")
  expect_equal(m$cap$args$custom_confidence_thresholds[[1]], list(a_A = 0.5))

  expect_error(birdnet_predict(m$model, files = tmp, species_list = 1:2), "`species_list` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, species_list = character()), "`species_list` must be", fixed = TRUE)
  expect_error(
    birdnet_predict(m$model, files = tmp, min_confidence_custom = c(a_A = 0.5)),
    "`min_confidence_custom` must be",
    fixed = TRUE
  )
})

test_that("basic acoustic and geo arguments are checked with a message that names them", {
  m <- local_capturing_model("acoustic")
  tmp <- withr::local_tempfile(fileext = ".wav")
  file.create(tmp)
  expect_error(birdnet_predict(m$model, files = tmp, min_confidence = "0.5"), "`min_confidence` must be a number.", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, top_k = 1.5), "`top_k` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, overlap = "1"), "`overlap` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, bandpass_fmin = 0.5), "`bandpass_fmin` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, n_workers = 0), "`n_workers` must be", fixed = TRUE)
  expect_error(birdnet_predict(m$model, files = tmp, progress = "loud"), "should be one of")

  geo <- local_capturing_model("geo")
  expect_error(birdnet_predict(geo$model, latitude = "50", longitude = 12.9), "`latitude` must be", fixed = TRUE)
  expect_error(birdnet_predict(geo$model, latitude = 50.8, longitude = 12.9, week = 1.5), "`week` must be", fixed = TRUE)
})
