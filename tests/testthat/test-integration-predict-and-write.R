# Integration tests for predict(), as.data.frame(), and write_predictions().
# These tests require a working Python environment with birdnet installed,
# internet access for model downloads, and BIRDNETR_RUN_INTEGRATION_TESTS=TRUE.

# -- Acoustic prediction --------------------------------------------------

test_that("predict() on acoustic model returns a prediction object", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  audio_file <- test_audio_file()

  pred <- predict(model, files = audio_file)

  expect_s3_class(pred, "birdnet_prediction_acoustic")
  expect_s3_class(pred, "birdnet_prediction")
  expect_true(!is.null(pred$py_predictions))
  expect_true(reticulate::is_py_object(pred$py_predictions))
})

# -- Geo prediction --------------------------------------------------------

test_that("predict() on geo model returns a prediction object", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()

  pred <- predict(model, latitude = 47.5, longitude = 11.0, week = 18L)

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
  pred <- predict(model, files = audio_file)

  df <- as.data.frame(pred)

  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
  expect_true(all(c("input", "start_time", "end_time", "species_name", "confidence") %in% names(df)))
  expect_type(df$species_name, "character")
  expect_type(df$confidence, "double")
})

# -- Result conversion: geo -----------------------------------------------

test_that("as.data.frame() on geo prediction returns expected columns", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  pred <- predict(model, latitude = 47.5, longitude = 11.0, week = 18L)

  df <- as.data.frame(pred)

  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
  expect_true(all(c("species_name", "confidence") %in% names(df)))
  expect_type(df$species_name, "character")
  expect_type(df$confidence, "double")
})

# -- Result saving: acoustic CSV ------------------------------------------

test_that("write_predictions() saves acoustic predictions to CSV", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  audio_file <- test_audio_file()
  pred <- predict(model, files = audio_file)

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result_path <- write_predictions(pred, tmp)

  expect_equal(result_path, tmp)
  expect_true(file.exists(tmp))
  saved <- read.csv(tmp)
  expect_true(nrow(saved) > 0)
  expect_true(all(c("start_time", "end_time", "species_name", "confidence") %in% names(saved)))
})

# -- Result saving: geo CSV -----------------------------------------------

test_that("write_predictions() saves geo predictions to CSV", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  pred <- predict(model, latitude = 47.5, longitude = 11.0, week = 18L)

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  result_path <- write_predictions(pred, tmp)

  expect_equal(result_path, tmp)
  expect_true(file.exists(tmp))
  saved <- read.csv(tmp)
  expect_true(nrow(saved) > 0)
  expect_true(all(c("species_name", "confidence") %in% names(saved)))
})
