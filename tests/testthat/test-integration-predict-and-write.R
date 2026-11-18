# Integration tests for birdnet_predict(), birdnet_encode(), as.data.frame(),
# and birdnet_write().
# These tests require a working Python environment with birdnet installed,
# internet access for model downloads, and BIRDNETR_RUN_INTEGRATION_TESTS=TRUE.

acoustic_columns <- c(
  "input",
  "start_time",
  "end_time",
  "species_name",
  "confidence"
)

# -- Acoustic prediction --------------------------------------------------

test_that("birdnet_predict() on acoustic model returns a prediction object", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  audio_file <- test_audio_file()

  pred <- birdnet_predict(model, files = audio_file)

  expect_s3_class(pred, "birdnet_prediction_acoustic")
  expect_s3_class(pred, "birdnet_prediction")
  expect_true(!is.null(pred$py_predictions))
  expect_true(reticulate::is_py_object(pred$py_predictions))
})

test_that("birdnet_predict() with BirdNET 2.4 returns predictions", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- suppressMessages(birdnet_load(version = "2.4"))
  df <- as.data.frame(birdnet_predict(model, files = test_audio_file()))

  expect_named(df, acoustic_columns)
  expect_gt(nrow(df), 0)
})

# -- Geo prediction --------------------------------------------------------

test_that("birdnet_predict() on geo model returns a prediction object", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()

  pred <- birdnet_predict(model, latitude = 50.83, longitude = 12.92, week = 18L)

  expect_s3_class(pred, "birdnet_prediction_geo")
  expect_s3_class(pred, "birdnet_prediction")
  expect_true(!is.null(pred$py_predictions))
  expect_true(reticulate::is_py_object(pred$py_predictions))
})

# -- Result conversion: acoustic ------------------------------------------

test_that("as.data.frame() on acoustic prediction returns expected columns", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  audio_file <- test_audio_file()
  pred <- birdnet_predict(model, files = audio_file)

  df <- as.data.frame(pred)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_named(df, acoustic_columns)
  expect_type(df$species_name, "character")
  expect_type(df$confidence, "double")
})

# -- Result conversion: geo -----------------------------------------------

test_that("as.data.frame() on geo prediction returns expected columns", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  pred <- birdnet_predict(model, latitude = 50.83, longitude = 12.92, week = 18L)

  df <- as.data.frame(pred)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_named(df, c("species_name", "confidence"))
  expect_type(df$species_name, "character")
  expect_type(df$confidence, "double")
})

# -- Encoding -------------------------------------------------------------

test_that("birdnet_encode() returns embeddings per segment", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  enc <- birdnet_encode(model, files = test_audio_file())

  expect_s3_class(enc, "birdnet_encoding")

  df <- as.data.frame(enc)

  expect_gt(nrow(df), 0)
  expect_named(df, c("input", "start_time", "end_time", "embedding"))
  expect_type(df$embedding, "list")
  expect_type(df$embedding[[1]], "double")
})

# -- Perch ----------------------------------------------------------------

test_that("Perch loads after a 3.0 model in the same session", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # Load directly (not via the cached helpers, which skip on load errors) so
  # a failure to load either model or to add TensorFlow fails this test.
  # Perch needs TensorFlow, which is added to a Python that already ran onnx.
  audio_file <- test_audio_file()
  acoustic <- suppressMessages(birdnet_load())
  expect_gt(
    nrow(as.data.frame(birdnet_predict(acoustic, files = audio_file))),
    0
  )

  expect_message(perch <- birdnet_load_perch(), "Perch v2")

  expect_s3_class(perch, "birdnet_model_perch")
  expect_s3_class(perch, "birdnet_model_acoustic")
  df <- as.data.frame(birdnet_predict(perch, files = audio_file))
  expect_named(df, acoustic_columns)
  expect_gt(nrow(df), 0)
})

# -- Custom classifier ----------------------------------------------------

test_that("birdnet_load_custom() loads a custom 2.4 classifier that predicts", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # dev/ is excluded from the package build
  model_file <- testthat::test_path(
    "..", "..", "dev", "rc_20240214", "Custom_Classifier.tflite"
  )
  labels_file <- testthat::test_path(
    "..", "..", "dev", "rc_20240214", "Custom_Classifier_Labels.txt"
  )
  skip_if_not(
    file.exists(model_file) && file.exists(labels_file),
    "Custom classifier files not found"
  )

  expect_message(
    model <- birdnet_load_custom(
      normalizePath(model_file),
      normalizePath(labels_file)
    ),
    "Custom acoustic 2.4"
  )

  expect_s3_class(model, "birdnet_model_custom")
  expect_true(model$custom)
  df <- as.data.frame(birdnet_predict(model, files = test_audio_file()))
  expect_named(df, acoustic_columns)
  expect_gt(nrow(df), 0)
})

# -- Empty results --------------------------------------------------------

test_that("an empty acoustic result keeps its columns and writes a header-only CSV", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  pred <- birdnet_predict(model, files = test_audio_file(), min_confidence = 0.999)

  df <- as.data.frame(pred)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
  expect_named(df, acoustic_columns)

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  birdnet_write(pred, tmp)

  expect_true(file.exists(tmp))
  lines <- readLines(tmp)
  expect_length(lines, 1)
  expect_equal(lines[[1]], paste(acoustic_columns, collapse = ","))
})

# -- Result saving: acoustic CSV ------------------------------------------

test_that("birdnet_write() saves acoustic predictions to CSV", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  audio_file <- test_audio_file()
  pred <- birdnet_predict(model, files = audio_file)

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result_path <- birdnet_write(pred, tmp)

  expect_equal(result_path, tmp)
  expect_true(file.exists(tmp))
  saved <- read.csv(tmp)
  expect_true(nrow(saved) > 0)
  expect_true(all(
    c("start_time", "end_time", "species_name", "confidence") %in% names(saved)
  ))
})

# -- Result saving: geo CSV -----------------------------------------------

test_that("birdnet_write() saves geo predictions to CSV", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  pred <- birdnet_predict(model, latitude = 50.83, longitude = 12.92, week = 18L)

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result_path <- birdnet_write(pred, tmp)

  expect_equal(result_path, tmp)
  expect_true(file.exists(tmp))
  saved <- read.csv(tmp)
  expect_true(nrow(saved) > 0)
  expect_true(all(c("species_name", "confidence") %in% names(saved)))
})
