test_that("load_model forwards the canonical pretrained loader arguments", {
  mock_py_obj <- create_mock_py_object()
  captured <- NULL

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  testthat::local_mocked_bindings(
    py_birdnet = list(
      load = function(...) {
        captured <<- list(...)
        mock_py_obj
      }
    ),
    .package = "birdnetR"
  )

  model <- load_model(
    type = "acoustic",
    version = "2.4",
    backend = "tf",
    library = "tflite",
    precision = "int8",
    language = "de_de"
  )

  expect_s3_class(model, c("birdnet_model_acoustic", "birdnet_model"))
  expect_equal(model$model_type, "acoustic")
  expect_equal(model$model_version, "2.4")
  expect_equal(model$precision, "int8")
  expect_equal(model$lang, "de_de")
  expect_equal(model$library, "tflite")

  expect_equal(captured[[1]], "acoustic")
  expect_equal(captured[[2]], "2.4")
  expect_equal(captured[[3]], "tf")
  expect_equal(captured$precision, "int8")
  expect_equal(captured$lang, "de_de")
  expect_equal(captured$library, "tflite")
})

test_that("load_custom has no legacy labels argument", {
  expect_setequal(intersect(names(formals(load_custom)), "labels"), character())
})

test_that("load_custom forwards species_list and advanced custom loader arguments", {
  mock_py_obj <- create_mock_py_object()
  captured <- NULL

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    .package = "reticulate"
  )

  testthat::local_mocked_bindings(
    py_birdnet = list(
      load_custom = function(...) {
        captured <<- list(...)
        mock_py_obj
      }
    ),
    .package = "birdnetR"
  )

  model <- load_custom(
    type = "acoustic",
    version = "2.4",
    backend = "tf",
    model = "custom_model.tflite",
    species_list = "species.txt",
    check_validity = FALSE,
    classifier_type = "append",
    is_raven = FALSE
  )

  expect_s3_class(model, c("birdnet_model_custom", "birdnet_model"))
  expect_equal(model$model_type, "acoustic")
  expect_equal(model$model_version, "2.4")

  expect_equal(captured[[1]], "acoustic")
  expect_equal(captured[[2]], "2.4")
  expect_equal(captured[[3]], "tf")
  expect_equal(captured[[4]], "custom_model.tflite")
  expect_equal(captured[[5]], "species.txt")
  expect_equal(captured$check_validity, FALSE)
  expect_equal(captured$classifier_type, "append")
  expect_equal(captured$is_raven, FALSE)
})

test_that("load_custom errors when species_list is missing", {
  expect_snapshot(
    error = TRUE,
    load_custom(model = "custom_model.tflite")
  )
})
