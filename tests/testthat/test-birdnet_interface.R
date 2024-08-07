library(testthat)
library(birdnetR)

# Assuming that the BirdNET model and data are set up correctly in the environment.

test_that("init_model works", {
  model <- init_model()
  expect_true(!is.null(model))
})

test_that("predict_species works with default parameters", {
  model <- init_model()
  predictions <- predict_species(model)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species handles custom species list correctly", {
  model <- init_model()

  # Single species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay")
  predictions <- predict_species(model, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) >= 0)  # Since keep_empty = FALSE, it could be 0 if no match

  # Multiple species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
  predictions <- predict_species(model, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) >= 0)  # As above, could be 0 if no match
})

test_that("predict_species handles bandpass filtering", {
  model <- init_model()

  # With bandpass filter
  predictions <- predict_species(model, use_bandpass = TRUE, bandpass_fmin = 500L, bandpass_fmax = 15000L)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  # Without bandpass filter
  predictions <- predict_species(model, use_bandpass = FALSE)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species applies sigmoid function correctly", {
  model <- init_model()

  # Apply sigmoid
  predictions <- predict_species(model, apply_sigmoid = TRUE, sigmoid_sensitivity = 1)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  # No sigmoid application
  predictions <- predict_species(model, apply_sigmoid = FALSE)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
})

test_that("predict_species respects minimum confidence threshold", {
  model <- init_model()

  # Lower threshold
  predictions <- predict_species(model, min_confidence = 0.05)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
  expect_true(max(predictions$confidence, na.rm = TRUE) >= 0.05)

  # Higher threshold
  predictions <- predict_species(model, min_confidence = 0.5)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)
  expect_true(max(predictions$confidence, na.rm = TRUE) >= 0.5)
})

test_that("predict_species applies overlap", {
  model <- init_model()

  # Lower threshold
  predictions <- predict_species(model, chunk_overlap_s = 1)
  expect_true(!is.null(predictions))
  expect_true(nrow(predictions) > 0)

  expect_equal(sort(unique(predictions$start))[1:4], c(0, 2, 4, 6))
})


test_that("predict_species keeps empty intervals when specified", {
  model <- init_model()

  # Keep empty intervals
  predictions_with_empty <- predict_species(model, keep_empty = TRUE)
  expect_true(!is.null(predictions_with_empty))
  expect_true(nrow(predictions_with_empty) > 0)

  # Do not keep empty intervals
  predictions_wo_empty <- predict_species(model, keep_empty = FALSE)
  expect_true(!is.null(predictions_wo_empty))
  expect_true(nrow(predictions_wo_empty ) >= 0)  # Could be 0 if no species detected
  expect_true(nrow(predictions_with_empty) > nrow(predictions_wo_empty))
})

test_that("predict_species handles invalid inputs gracefully", {
  model <- init_model()

  # Invalid species list type
  expect_error(predict_species(model, filter_species = 123))
  expect_error(predict_species(model, filter_species = list(c("A", "B"))))

  # Invalid bandpass frequencies
  expect_error(predict_species(model, bandpass_fmin = -100L))
  expect_error(predict_species(model, bandpass_fmin = 500L, bandpass_fmax = 100L))

  # Invalid sigmoid sensitivity
  expect_error(predict_species(model, sigmoid_sensitivity = 2))

  # Invalid batch size
  expect_error(predict_species(model, batch_size = 0L))

  # Invalid file path
  expect_error(predict_species(model, audio_file = "nonexistent_file.wav"))
})
