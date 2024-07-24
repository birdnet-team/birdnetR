library(testthat)
library(birdnet)

test_that("init_model works", {
  model <- init_model()
  expect_true(!is.null(model))
})

test_that("predict_species works", {
  model <- init_model()
  predictions <- predict_species(model)
  expect_true(!is.null(predictions))
})

test_that("get_top_prediction works", {
  model <- init_model()
  audio_path <- system.file("extdata", "soundscape.wav", package = "birdnet")
  predictions <- predict_species(model, audio_path)
  print(predictions)  # Debugging: Print predictions

  # Ensure predictions contain the interval
  interval_str <- sprintf("(%.1f, %.1f)", 0.0, 3.0)
  print(interval_str)  # Debugging: Print interval string
  print(names(predictions))  # Debugging: Print names of predictions

  expect_true(interval_str %in% names(predictions))

  top_prediction <- get_top_prediction(predictions, 0.0, 3.0)
  expect_true(!is.null(top_prediction$prediction))
  expect_true(!is.null(top_prediction$confidence))
})
