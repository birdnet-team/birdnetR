library(testthat)
library(birdnetR)

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
  audio_path <- system.file("extdata", "soundscape.wav", package = "birdnetR")
  predictions <- predict_species(model, audio_path)

  top_prediction <- get_top_prediction(predictions, filter = list(start = 18, end = 21))
  expect_true(nrow(top_prediction) == 1)

  top_prediction <- get_top_prediction(predictions)
  expect_true(nrow(top_prediction) > 1)
  expect_true(nrow(top_prediction) <= nrow(predictions))
})
