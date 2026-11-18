# Unit tests for the model loaders. No Python: py_birdnet, the extras helper,
# the platform and reticulate::py_available are mocked, and
# reticulate::py_module_available (which would start Python) must not be called.

# Mocks the Python loaders and records what birdnetR passes to them.
# `litert` picks the mocked platform: Linux (LiteRT wheels exist) or Intel
# macOS (they do not). Returns an environment with captured_load /
# captured_perch / captured_custom / captured_inspect / captured_extra.
local_loader_mocks <- function(litert = TRUE, quiet = TRUE, env = parent.frame()) {
  cap <- new.env()
  cap$captured_extra <- NULL
  py_obj <- create_mock_py_object(list(get_version = function() "2.4", n_species = 3L))

  testthat::local_mocked_bindings(
    is_py_object = mock_is_py_object(),
    py_available = function(...) FALSE,
    py_module_available = function(...) stop("must not be called"),
    .package = "reticulate",
    .env = env
  )
  testthat::local_mocked_bindings(
    platform = function() {
      if (litert) {
        c(sysname = "Linux", machine = "x86_64")
      } else {
        c(sysname = "Darwin", machine = "x86_64")
      }
    },
    .package = "birdnetR",
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
  if (quiet) {
    testthat::local_mocked_bindings(
      announce_model = function(model) invisible(model),
      .package = "birdnetR",
      .env = env
    )
  }
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

test_that("birdnet_load(version = '2.4') uses tf + litert where LiteRT has wheels", {
  cap <- local_loader_mocks(litert = TRUE)
  m <- birdnet_load(version = "2.4")
  expect_equal(cap$captured_load[[3]], "tf")
  expect_equal(cap$captured_load$library, "litert")
  expect_null(cap$captured_extra)
  expect_equal(m$library, "litert")
})

test_that("birdnet_load(version = '2.4') falls back to tflite and requires [tf] without LiteRT wheels", {
  cap <- local_loader_mocks(litert = FALSE)
  birdnet_load(version = "2.4")
  expect_equal(cap$captured_load$library, "tflite")
  expect_equal(cap$captured_extra, "tf")
})

test_that("resolve_library() decides by platform while Python is not running", {
  testthat::local_mocked_bindings(
    py_available = function(...) FALSE,
    py_module_available = function(...) stop("must not be called"),
    .package = "reticulate"
  )
  lib_on <- function(sysname, machine) {
    testthat::local_mocked_bindings(
      platform = function() c(sysname = sysname, machine = machine)
    )
    birdnetR:::resolve_library("tf", NULL)
  }
  expect_equal(lib_on("Linux", "x86_64"), "litert")
  expect_equal(lib_on("Linux", "aarch64"), "litert")
  expect_equal(lib_on("Darwin", "arm64"), "litert")
  expect_equal(lib_on("Windows", "x86-64"), "litert")
  expect_equal(lib_on("Darwin", "x86_64"), "tflite")
  expect_equal(lib_on("Windows", "arm64"), "tflite")
})

test_that("resolve_library() looks LiteRT up without importing it once Python runs", {
  find_spec_result <- NULL
  testthat::local_mocked_bindings(
    py_available = function(...) TRUE,
    py_module_available = function(...) stop("must not be called"),
    import = function(module, ...) {
      expect_equal(module, "importlib.util")
      list(find_spec = function(name) {
        expect_equal(name, "ai_edge_litert")
        find_spec_result
      })
    },
    .package = "reticulate"
  )
  expect_equal(birdnetR:::resolve_library("tf", NULL), "tflite")
  find_spec_result <- list()
  expect_equal(birdnetR:::resolve_library("tf", NULL), "litert")
})

test_that("resolve_library() ignores non-tf backends and keeps an explicit library", {
  testthat::local_mocked_bindings(
    py_available = function(...) stop("must not be called"),
    .package = "reticulate"
  )
  expect_null(birdnetR:::resolve_library("onnx", NULL))
  expect_equal(birdnetR:::resolve_library("tf", "tflite"), "tflite")
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

test_that("birdnet_load_perch() stops early on Intel macOS, before declaring TensorFlow", {
  cap <- local_loader_mocks(litert = FALSE)
  expect_error(birdnet_load_perch(), "not supported on Intel macOS")
  expect_null(cap$captured_extra)
  expect_null(cap$captured_perch)
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

test_that("birdnet_load_custom() expands ~ in model and species_list", {
  cap <- local_loader_mocks()
  m <- birdnet_load_custom("~/m.tflite", "~/labels.txt")
  expect_equal(cap$captured_custom[[4]], path.expand("~/m.tflite"))
  expect_equal(cap$captured_custom[[5]], path.expand("~/labels.txt"))
  expect_false(startsWith(cap$captured_custom[[4]], "~"))
  expect_equal(m$model_path, path.expand("~/m.tflite"))
  expect_equal(m$species_list_path, path.expand("~/labels.txt"))
})

test_that("birdnet_load(), birdnet_load_custom() and birdnet_list_languages() need a string version", {
  local_loader_mocks()
  msg <- "`version` must be a string"
  expect_error(birdnet_load(version = 3.0), msg, fixed = TRUE)
  expect_error(birdnet_load(version = c("3.0", "2.4")), msg, fixed = TRUE)
  expect_error(birdnet_load(version = NULL), msg, fixed = TRUE)
  expect_error(birdnet_load(version = NA_character_), msg, fixed = TRUE)
  expect_error(birdnet_load_custom("m.tflite", "l.txt", version = 2.4), msg, fixed = TRUE)
  expect_error(birdnet_list_languages(version = 3.0), msg, fixed = TRUE)
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

  birdnet_inspect_custom("~/m.tflite")
  expect_equal(cap$captured_inspect[[1]], path.expand("~/m.tflite"))
  expect_false(startsWith(cap$captured_inspect[[1]], "~"))
})

test_that("old loader names are gone", {
  ns <- asNamespace("birdnetR")
  for (f in c("load_birdnet", "load_perch", "load_custom")) {
    expect_false(exists(f, envir = ns, inherits = FALSE))
  }
})

test_that("loaders announce the loaded model", {
  local_loader_mocks(quiet = FALSE)
  expect_message(birdnet_load(), "BirdNET acoustic 3.0", fixed = TRUE)
  expect_message(birdnet_load_perch(), "Perch v2", fixed = TRUE)
  expect_message(birdnet_load_custom("m.tflite", "l.txt"), "Custom acoustic 2.4", fixed = TRUE)
})
