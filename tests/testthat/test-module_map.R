library(birdnetR)
library(testthat)

test_that("create_module_map", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  expect_type(module_map, "list")
  expect_named(module_map, c("models", "misc"))
  expect_named(module_map$models, c("tflite_v2.4", "protobuf_v2.4", "custom_v2.4", "raven_v2.4", "meta_v2.4"))
  expect_named(module_map$misc, "available_languages_v2.4")
})


test_that("get_model", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  tflite_model_path <- get_model_from_module_map(module_map, "tflite_v2.4")
  expect_type(tflite_model_path, "character")
})


test_that("get_misc", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  available_languages_path <- get_misc_from_module_map(module_map, "available_languages_v2.4")
  expect_type(available_languages_path, "character")
})
