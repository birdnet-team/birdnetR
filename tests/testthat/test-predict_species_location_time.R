library(testthat)

# Assuming that `init_model` is a function that initializes the BirdNET model
model <- init_model(language = "en_us")

test_that("predict_species_at_location_and_time returns a data frame", {
  result <- predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231)
  expect_s3_class(result, "data.frame")
})

test_that("result has correct column names", {
  result <- predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231)
  expect_equal(colnames(result), c("label", "confidence"))
})

test_that("latitude and longitude are within valid ranges", {
  # "latitude must be in the interval \\[-90.0, 90.0\\]"
  expect_error(predict_species_at_location_and_time(model, latitude = -100, longitude = 12.9231))
  # "longitude must be in the interval \\[-180.0, 180.0\\]"
  expect_error(predict_species_at_location_and_time(model, latitude = 50.8334, longitude = -200))
})

test_that("week parameter accepts correct values", {
  result <- predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, week = 1)
  expect_s3_class(result, "data.frame")

  result <- predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, week = NULL)
  expect_s3_class(result, "data.frame")

  #  "week must be in the interval \\[1, 48\\]"
  expect_error(predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, week = 0))
  expect_error(predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, week = 49))
})

test_that("min_confidence parameter accepts correct values", {
  result <- predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, min_confidence = 0.99)
  expect_s3_class(result, "data.frame")

  "min_confidence must be in the interval \\[0, 1.0\\)"
  expect_error(predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, min_confidence = -0.1))
  expect_error(predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231, min_confidence = 1))
})
