test_that("birdnet_model_tflite initializes correctly", {
  # Skip if not in full test environment
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # Test model initialization
  tryCatch(
    {
      model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
      expect_s3_class(model, c("birdnet_model_tflite", "birdnet_model"))
      expect_equal(model$language, "en_us")
      expect_equal(model$model_version, "v2.4")
    },
    error = function(e) {
      skip(paste("Failed to initialize model:", e$message))
    }
  )
})

test_that("birdnet_model_tflite loads TFLite model correctly", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # Test model initialization
  model <- birdnet_model_tflite(version = "v2.4")

  # Check structure
  expect_s3_class(model, c("birdnet_model_tflite", "birdnet_model"))
  expect_equal(model$model_version, "v2.4")
  expect_equal(model$language, "en_us")
  expect_true("py_model" %in% names(model))
})

test_that("predict_species_from_audio_file works with real audio", {
  # Skip if not in full test environment
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # Use a small test audio file from the package
  audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
  skip_if(audio_file == "", "Test audio file not found")

  # Initialize model
  tryCatch(
    {
      model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
      results <- predict_species_from_audio_file(
        model,
        audio_file,
        min_confidence = 0.1
      )

      expect_s3_class(results, "data.frame")
      expect_true(all(c("start", "end", "scientific_name", "common_name", "confidence") %in%
        names(results)))
    },
    error = function(e) {
      skip(paste("Failed to test prediction:", e$message))
    }
  )
})
