library(testthat)

# Assuming that the BirdNET model and data are set up correctly in the environment.

tflite_model <- NULL
protobuf_model <- NULL
audio_file <- system.file("extdata", "soundscape.wav", package = "birdnetR")


test_that("birdnet_model_tflite works", {
  tflite_model <<- birdnet_model_tflite(version = "v2.4")
  expect_true(!is.null(tflite_model))
})

test_that("birdnet_model_protobuf works", {
  protobuf_model <<- birdnet_model_protobuf(version = "v2.4")
  expect_true(!is.null(tflite_model))
})


test_that("birdnet_model structure is correct", {
  expect_s3_class(tflite_model, c("birdnet_model_tflite"))
  expect_s3_class(tflite_model$py_model, c("python.builtin.object", "birdnet.models.v2m4.model_v2m4_tflite.AudioModelV2M4TFLite" ))
  expect_equal(tflite_model$model_version, "v2.4")

  expect_s3_class(protobuf_model, c("birdnet_model_protobuf"))
  expect_s3_class(protobuf_model$py_model, c("birdnet.models.v2m4.model_v2m4_protobuf.AudioModelV2M4Protobuf"))
  expect_equal(protobuf_model$model_version, "v2.4")
})

test_that("predict_species works with default parameters", {
  predictions <- predict_species_from_audio_file(tflite_model, audio_file)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  predictions <- predict_species_from_audio_file(protobuf_model, audio_file)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species handles custom species list correctly", {
  # Single species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay")
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) >= 0) # Since keep_empty = FALSE, it could be 0 if no match

  # Multiple species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) >= 0) # As above, could be 0 if no match
})

test_that("predict_species handles bandpass filtering", {
  # With bandpass filter
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, use_bandpass = TRUE, bandpass_fmin = 500L, bandpass_fmax = 15000L)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  # Without bandpass filter
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, use_bandpass = FALSE)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species applies sigmoid function correctly", {
  # Apply sigmoid
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, apply_sigmoid = TRUE, sigmoid_sensitivity = 1)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  # No sigmoid application
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, apply_sigmoid = FALSE)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species respects minimum confidence threshold", {

  # Lower threshold
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, min_confidence = 0.05)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
  expect_true(max(predictions$confidence, na.rm = TRUE) >= 0.05)

  # Higher threshold
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, min_confidence = 0.5)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
  expect_true(max(predictions$confidence, na.rm = TRUE) >= 0.5)
})

test_that("predict_species applies overlap", {

  # Lower threshold
  predictions <- predict_species_from_audio_file(tflite_model, audio_file, chunk_overlap_s = 1)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  expect_equal(sort(unique(predictions$start))[1:4], c(0, 2, 4, 6))
})


test_that("predict_species keeps empty intervals when specified", {
  # Keep empty intervals
  predictions_with_empty <- predict_species_from_audio_file(tflite_model, audio_file, keep_empty = TRUE)
  expect_true(!is.null(predictions_with_empty))
  expect_true(nrow(predictions_with_empty) > 0)

  # Do not keep empty intervals
  predictions_wo_empty <- predict_species_from_audio_file(tflite_model, audio_file, keep_empty = FALSE)
  expect_true(!is.null(predictions_wo_empty))
  expect_true(nrow(predictions_wo_empty) >= 0) # Could be 0 if no species detected
  expect_true(nrow(predictions_with_empty) > nrow(predictions_wo_empty))
})

test_that("predict_species handles invalid inputs gracefully", {

  # Invalid species list type
  expect_error(predict_species_from_audio_file(tflite_model, audio_file, filter_species = 123))
  expect_error(predict_species_from_audio_file(tflite_model, audio_file,filter_species = list(c("A", "B"))))

  # Invalid bandpass frequencies
  expect_error(predict_species_from_audio_file(tflite_model, audio_file, bandpass_fmin = -100L))
  expect_error(predict_species_from_audio_file(tflite_model, audio_file, bandpass_fmin = 500L, bandpass_fmax = 100L))

  # Invalid sigmoid sensitivity
  expect_error(predict_species_from_audio_file(tflite_model, audio_file, sigmoid_sensitivity = 2))

  # Invalid batch size
  expect_error(predict_species_from_audio_file(tflite_model, audio_file, batch_size = 0L))

  # Invalid file path
  expect_error(predict_species_from_audio_file(tflite_model, audio_file = "nonexistent_file.wav"))
})
