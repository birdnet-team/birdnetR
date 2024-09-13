library(testthat)

test_that("create_module_map", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  expect_type(module_map, "list")
  expect_named(module_map, c("models", "misc"))
  expect_named(
    module_map$models,
    c("tflite", "protobuf", "custom", "raven", "meta")
  )
})

test_that("getting eelements from modules mpa", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")
  tflite_model_path <- get_element_from_module_map(module_map, "models", "tflite")
  expect_equal(
    tflite_model_path,
    "py_birdnet_models$v2m4$AudioModelV2M4TFLite"
  )
})



test_that("all mapped modules can be evaluates", {
  module_map <- create_module_map("v2.4", "py_birdnet_models")

  # Evaluate all modules
  for (module in unlist(module_map)) {
    expect_s3_class(
      evaluate_python_path(module),
      c(
        "python.builtin.type",
        "python.builtin.object",
        "python.builtin.set"
      )
    )
  }
})
