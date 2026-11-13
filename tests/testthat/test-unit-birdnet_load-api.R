# Unit tests for the model loaders. No Python: py_birdnet, the extras helper
# and reticulate::py_module_available are mocked.

# Mocks the Python loaders and records what birdnetR passes to them.
# Returns an environment with captured_load / captured_perch / captured_custom /
# captured_inspect / captured_extra.
local_loader_mocks <- function(litert = TRUE, env = parent.frame()) {
  cap <- new.env()
  cap$captured_extra <- NULL
  py_obj <- create_mock_py_object(list(get_version = function() "2.4", n_species = 3L))

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    py_module_available = function(module, ...) litert,
    .package = "reticulate",
    .env = env
  )
  testthat::local_mocked_bindings(
    py_birdnet = list(
      load = function(...) { cap$captured_load <- list(...); py_obj },
      load_perch_v2 = function(...) { cap$captured_perch <- list(...); py_obj },
      load_custom = function(...) { cap$captured_custom <- list(...); py_obj },
      inspect_custom_tflite = function(...) {
        cap$captured_inspect <- list(...)
        list(
          version = "3.0", mode = "append", n_species = 5L,
          applies_sigmoid = TRUE, supports_encoding = TRUE, input_samples = NULL
        )
      }
    ),
    require_birdnet_extra = function(extra) cap$captured_extra <- extra,
    .package = "birdnetR",
    .env = env
  )
  cap
}

test_that("birdnet_load() defaults to acoustic 3.0 on onnx without extras", {
  cap <- local_loader_mocks()
  m <- birdnet_load()
  expect_equal(unname(cap$captured_load[1:3]), list("acoustic", "3.0", "onnx"))
  expect_null(cap$captured_load$library)
  expect_null(cap$captured_extra)
  expect_equal(m$backend, "onnx")
  expect_null(m$library)
  expect_false(m$custom)
})

test_that("birdnet_load() forwards precision, language and an explicit library", {
  cap <- local_loader_mocks()
  m <- birdnet_load(
    type = "acoustic", version = "2.4", backend = "tf",
    library = "tflite", precision = "int8", language = "de"
  )
  expect_s3_class(m, c("birdnet_model_acoustic_v2_4", "birdnet_model_acoustic", "birdnet_model"))
  expect_equal(m$model_type, "acoustic")
  expect_equal(m$model_version, "2.4")
  expect_equal(m$precision, "int8")
  expect_equal(m$language, "de")
  expect_equal(m$library, "tflite")
  expect_equal(unname(cap$captured_load[1:3]), list("acoustic", "2.4", "tf"))
  expect_equal(cap$captured_load$precision, "int8")
  expect_equal(cap$captured_load$lang, "de")
  expect_equal(cap$captured_load$library, "tflite")
  expect_equal(cap$captured_extra, "tf")
})

test_that("birdnet_load(version = '2.4') uses tf + litert when LiteRT is importable", {
  cap <- local_loader_mocks(litert = TRUE)
  m <- birdnet_load(version = "2.4")
  expect_equal(cap$captured_load[[3]], "tf")
  expect_equal(cap$captured_load$library, "litert")
  expect_null(cap$captured_extra)
  expect_equal(m$library, "litert")
})

test_that("birdnet_load(version = '2.4') falls back to tflite and requires [tf] without LiteRT", {
  cap <- local_loader_mocks(litert = FALSE)
  birdnet_load(version = "2.4")
  expect_equal(cap$captured_load$library, "tflite")
  expect_equal(cap$captured_extra, "tf")
})

test_that("pb and pt backends require their extras before loading", {
  cap <- local_loader_mocks()
  birdnet_load(backend = "pb")
  expect_equal(cap$captured_extra, "tf")
  expect_null(cap$captured_load$library)
  birdnet_load(backend = "pt")
  expect_equal(cap$captured_extra, "pt")
})

test_that("birdnet_load() rejects a version without a default backend", {
  local_loader_mocks()
  expect_error(birdnet_load(version = "9.9"), "backend")
})

test_that("birdnet_load_perch() requires [tf] and forwards device", {
  cap <- local_loader_mocks()
  m <- birdnet_load_perch(device = "GPU")
  expect_equal(cap$captured_extra, "tf")
  expect_equal(cap$captured_perch[[1]], "GPU")
  expect_equal(
    class(m),
    c("birdnet_model_perch_v2", "birdnet_model_perch", "birdnet_model_acoustic", "birdnet_model")
  )
  expect_equal(m$model_type, "acoustic")
  expect_equal(m$model_version, "perch_v2")
  expect_equal(m$backend, "pb")
  expect_equal(m$device, "GPU")
})

test_that("birdnet_load_perch() defaults to CPU", {
  cap <- local_loader_mocks()
  birdnet_load_perch()
  expect_equal(cap$captured_perch[[1]], "CPU")
})

test_that("birdnet_load_custom() defaults to version auto and has no classifier_type", {
  cap <- local_loader_mocks()
  expect_false("classifier_type" %in% names(formals(birdnet_load_custom)))
  expect_equal(names(formals(birdnet_load_custom))[1:2], c("model", "species_list"))
  m <- birdnet_load_custom("m.tflite", "labels.txt")
  expect_equal(unname(cap$captured_custom[1:5]), list("acoustic", "auto", "tf", "m.tflite", "labels.txt"))
  expect_equal(cap$captured_custom$library, "litert")
  expect_true(cap$captured_custom$check_validity)
  expect_null(cap$captured_custom$is_raven)
  expect_s3_class(m, c("birdnet_model_custom", "birdnet_model"))
  expect_true(m$custom)
  # version "auto" is replaced by the version the Python model reports
  expect_equal(m$model_version, "2.4")
  expect_equal(m$model_path, "m.tflite")
  expect_equal(m$species_list_path, "labels.txt")
})

test_that("birdnet_load_custom(is_raven = TRUE) requires [tf] and forwards is_raven", {
  cap <- local_loader_mocks()
  birdnet_load_custom("raven_dir", "labels.csv", version = "3.0", backend = "pb", is_raven = TRUE)
  expect_equal(cap$captured_extra, "tf")
  expect_true(cap$captured_custom$is_raven)
  expect_null(cap$captured_custom$library)
})

test_that("birdnet_load_custom() errors when species_list is missing", {
  local_loader_mocks()
  expect_error(birdnet_load_custom(model = "m.tflite"), "species_list")
})

test_that("birdnet_inspect_custom() returns the CustomTFLiteInfo fields as a list", {
  cap <- local_loader_mocks()
  info <- birdnet_inspect_custom("m.tflite")
  expect_named(
    info,
    c("version", "mode", "n_species", "applies_sigmoid", "supports_encoding", "input_samples")
  )
  expect_equal(info$version, "3.0")
  expect_null(info$input_samples)
  expect_equal(cap$captured_inspect[[1]], "m.tflite")
  expect_equal(cap$captured_inspect$library, "litert")
})

test_that("old loader names are gone", {
  ns <- asNamespace("birdnetR")
  for (f in c("load_birdnet", "load_perch", "load_custom")) {
    expect_false(exists(f, envir = ns, inherits = FALSE))
  }
})
