# Unit tests for birdnet_list_models(), birdnet_list_languages() and
# birdnet_list_species(). The Python model table is mocked.

local_model_rows <- function(env = parent.frame()) {
  testthat::local_mocked_bindings(
    get_df_helper = function() {
      list(official_model_rows = function() {
        list(
          type = c("acoustic", "acoustic", "acoustic", "geo", "acoustic", "acoustic"),
          version = c("3.0", "2.4", "2.4", "3.0", "2.4", "3.0"),
          backend = c("onnx", "tf", "tf", "tf", "pb", "pt"),
          precision = c("fp32", "int8", "fp32", "fp32", "fp32", "fp32")
        )
      })
    },
    .package = "birdnetR",
    .env = env
  )
}

test_that("birdnet_list_models() has the documented columns", {
  local_model_rows()
  expect_named(
    birdnet_list_models(),
    c("type", "version", "backend", "library", "precision", "needs")
  )
})

test_that("tf rows split into litert (base) and tflite (tf); geo 3.0 tf is tflite only", {
  local_model_rows()
  x <- birdnet_list_models()
  a24 <- x[x$type == "acoustic" & x$version == "2.4" & x$backend == "tf", ]
  expect_setequal(paste(a24$library, a24$needs), c("litert base", "tflite tf"))
  g30 <- x[x$type == "geo" & x$version == "3.0" & x$backend == "tf", ]
  expect_equal(g30$library, "tflite")
  expect_equal(g30$needs, "tf (2.18-2.19)")
})

test_that("non-tf rows have no library and the right extra", {
  local_model_rows()
  x <- birdnet_list_models()
  needs <- stats::setNames(x$needs, x$backend)[c("onnx", "pb", "pt")]
  expect_equal(unname(needs), c("base", "tf", "pt"))
  expect_true(all(is.na(x$library[x$backend != "tf"])))
})

test_that("birdnet_list_models() includes the Perch row", {
  local_model_rows()
  x <- birdnet_list_models()
  perch <- x[x$version == "perch_v2", ]
  expect_equal(nrow(perch), 1L)
  expect_equal(
    unlist(perch[1, ], use.names = FALSE),
    c("acoustic", "perch_v2", "pb", NA, "fp32", "tf")
  )
})

test_that("birdnet_list_models(compact = TRUE) collapses precisions", {
  local_model_rows()
  x <- birdnet_list_models(compact = TRUE)
  expect_named(x, c("type", "version", "backend", "needs", "precision", "library"), ignore.order = TRUE)
  expect_equal(anyDuplicated(x[c("type", "version", "backend", "needs")]), 0L)
  a24 <- x[x$version == "2.4" & x$backend == "tf", ]
  expect_equal(a24$precision, c("fp32:int8", "fp32:int8"))
  expect_setequal(a24$library, c("litert", "tflite"))
  expect_true(is.na(x$library[x$backend == "onnx"]))
})

test_that("birdnet_list_languages() picks the per-version list and rejects unknown versions", {
  testthat::local_mocked_bindings(
    py_birdnet_globals = list(
      VALID_MODEL_LANGUAGES_V2_4 = c("en_us", "et"),
      VALID_MODEL_LANGUAGES_V3_0 = c("en_us", "de")
    ),
    .package = "birdnetR"
  )
  expect_equal(birdnet_list_languages(), c("en_us", "de"))
  expect_equal(birdnet_list_languages("2.4"), c("en_us", "et"))
  expect_error(birdnet_list_languages("9.9"), "version")
})

test_that("birdnet_list_species() returns the model's species as a character vector", {
  mock_species <- c("Cyanocitta cristata_Blue Jay", "Zenaida macroura_Mourning Dove")
  # builtins$list() is Python's list(); the real one would start Python
  testthat::local_mocked_bindings(
    py_builtins = list(list = function(x) x),
    .package = "birdnetR"
  )
  model <- structure(
    list(py_model = list(species_list = mock_species), model_type = "acoustic", model_version = "3.0"),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )
  result <- birdnet_list_species(model)
  expect_type(result, "character")
  expect_equal(result, mock_species)
})

test_that("birdnet_list_species() errors for non-model input", {
  expect_error(birdnet_list_species("not_a_model"), "must be a BirdNET model object")
  expect_error(birdnet_list_species(list()), "must be a BirdNET model object")
})

test_that("old lookup names are gone", {
  ns <- asNamespace("birdnetR")
  for (f in c("supported_model_configurations", "supported_languages", "get_species_list")) {
    expect_false(exists(f, envir = ns, inherits = FALSE))
  }
})
