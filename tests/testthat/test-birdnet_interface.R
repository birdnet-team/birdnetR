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

test_that("prediction with a custom species list works", {
  model <- init_model()

  # single species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay")
  predictions <- predict_species(model, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) == 4)

  # multiple species
  custom_species_list <- c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
  predictions <- predict_species(model, filter_species = custom_species_list, keep_empty = FALSE)
  expect_true(nrow(predictions) == 4)
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
