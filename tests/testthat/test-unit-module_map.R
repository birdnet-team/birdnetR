library(testthat)


test_that("create_module_map creates expected structure", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  expect_type(module_map, "list")
  expect_named(module_map, c("models", "misc"))
  expect_named(
    module_map$models,
    c("tflite", "protobuf", "custom", "raven", "meta")
  )
})

test_that("get_element_from_module_map returns expected paths", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  tflite_model_path <- get_element_from_module_map(module_map, "models", "tflite")
  expect_equal(
    tflite_model_path,
    "py_birdnet_models$v2m4$AudioModelV2M4TFLite"
  )

  # Test with non-existent elements
  expect_error(
    get_element_from_module_map(module_map, "nonexistent", "key"),
    "Element 'nonexistent' not found in module map"
  )
  expect_error(
    get_element_from_module_map(module_map, "models", "nonexistent"),
    "Element 'nonexistent' not found in module map"
  )
})

test_that("module paths have expected format", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")

  # Check that all paths follow expected format
  all_paths <- unlist(module_map)
  for (path in all_paths) {
    expect_match(path, "^py_birdnet_models\\$",
                info = paste("Path", path, "should start with py_birdnet_models$"))
  }
})
