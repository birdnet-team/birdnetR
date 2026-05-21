test_that("load_perch returns an acoustic model with correct class vector", {

  mock_py_obj <- create_mock_py_object()
  captured <- NULL

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  testthat::local_mocked_bindings(
    py_birdnet = list(
      load_perch_v2 = function(...) {
        captured <<- list(...)
        mock_py_obj
      }
    ),
    .package = "birdnetR"
  )

  model <- load_perch()

  expect_equal(
    class(model),
    c("birdnet_model_perch_v2", "birdnet_model_perch", "birdnet_model_acoustic", "birdnet_model")
  )
  expect_s3_class(model, "birdnet_model")
  expect_s3_class(model, "birdnet_model_acoustic")
  expect_s3_class(model, "birdnet_model_perch")
  expect_s3_class(model, "birdnet_model_perch_v2")
  expect_equal(model$model_type, "acoustic")
  expect_equal(model$model_version, "perch_v2")
})

test_that("load_perch hardcodes CPU device for Python call", {
  mock_py_obj <- create_mock_py_object()
  captured <- NULL

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  testthat::local_mocked_bindings(
    py_birdnet = list(
      load_perch_v2 = function(...) {
        captured <<- list(...)
        mock_py_obj
      }
    ),
    .package = "birdnetR"
  )

  load_perch()
  expect_equal(captured[[1]], "CPU")
})

test_that("load_perch accepts no arguments", {
  expect_equal(length(formals(load_perch)), 0L)
})
