# Unit tests for the load message and print.birdnet_model().

mock_model <- function(n = 11725L, ...) {
  fields <- utils::modifyList(
    list(
      py_model = list(n_species = n),
      model_type = "acoustic",
      model_version = "3.0",
      backend = "onnx",
      library = NULL,
      precision = "fp32",
      language = "en_us",
      custom = FALSE
    ),
    list(...)
  )
  structure(fields, class = c("birdnet_model_acoustic", "birdnet_model"))
}

test_that("model_description() formats an official model", {
  expect_equal(
    birdnetR:::model_description(mock_model()),
    "BirdNET acoustic 3.0 · onnx · fp32 · en_us · 11,725 classes"
  )
})

test_that("model_description() shows backend/library for the tf backend", {
  m <- mock_model(n = 6522L, model_version = "2.4", backend = "tf", library = "litert")
  expect_equal(
    birdnetR:::model_description(m),
    "BirdNET acoustic 2.4 · tf/litert · fp32 · en_us · 6,522 classes"
  )
})

test_that("model_description() formats Perch", {
  m <- structure(
    list(
      py_model = list(n_species = 14795L), model_type = "acoustic",
      model_version = "perch_v2", backend = "pb", precision = "fp32",
      device = "CPU", custom = FALSE
    ),
    class = c("birdnet_model_perch_v2", "birdnet_model_perch", "birdnet_model_acoustic", "birdnet_model")
  )
  expect_equal(
    birdnetR:::model_description(m),
    "Perch v2 · pb · CPU · 14,795 classes"
  )
})

test_that("model_description() formats a custom model", {
  m <- mock_model(
    n = 34L, model_version = "2.4", backend = "tf", library = "litert",
    language = NULL, custom = TRUE
  )
  expect_equal(
    birdnetR:::model_description(m),
    "Custom acoustic 2.4 · tf/litert · fp32 · 34 classes"
  )
})

test_that("announce_model() prints only the description", {
  m <- mock_model()
  msg <- testthat::capture_messages(birdnetR:::announce_model(m))
  expect_equal(trimws(paste(msg, collapse = "")), birdnetR:::model_description(m))
})

test_that("announce_model() returns the model invisibly", {
  m <- mock_model()
  expect_invisible(suppressMessages(birdnetR:::announce_model(m)))
  expect_identical(suppressMessages(birdnetR:::announce_model(m)), m)
})

test_that("suppressMessages() silences the description", {
  expect_silent(suppressMessages(birdnetR:::announce_model(mock_model())))
})

test_that("print.birdnet_model() prints the description", {
  expect_output(print(mock_model()), "BirdNET acoustic 3.0", fixed = TRUE)
  utils::capture.output(res <- withVisible(print(mock_model())))
  expect_false(res$visible)
})
