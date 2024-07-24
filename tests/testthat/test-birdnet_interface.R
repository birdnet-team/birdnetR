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
  predictions <- predict_species(model)
  top_prediction <- get_top_prediction(predictions, 0.0, 3.0)
  expect_true(!is.null(top_prediction$prediction))
  expect_true(!is.null(top_prediction$confidence))
})
