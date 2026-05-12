# Integration tests for verifying installation, model download, and model load.
# These tests require a working Python environment with birdnet installed,
# internet access for model downloads, and BIRDNETR_RUN_INTEGRATION_TESTS=TRUE.

# -- Python environment bootstrap -----------------------------------------

test_that("Python environment is bootstrapped and birdnet is importable", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_true(reticulate::py_module_available("birdnet"))
  expect_true(reticulate::py_module_available("birdnet.globals"))
})

test_that("birdnet package version is within the supported range", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  pkg_version <- package_version(
    reticulate::import("importlib.metadata")$version("birdnet")
  )
  expect_true(pkg_version >= "0.2.16")
  expect_true(pkg_version < "0.3.0")
})

# -- Discovery helpers ----------------------------------------------------

test_that("supported_model_configurations() returns a valid configurations table from Python globals", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  opts <- supported_model_configurations()
  expect_s3_class(opts, "data.frame")
  expect_true(nrow(opts) > 0)
  expect_true(
    all(c("type", "version", "backend", "library", "precision") %in% names(opts))
  )
  expect_true("acoustic" %in% opts$type)
  expect_true("geo" %in% opts$type)
  expect_true("2.4" %in% opts$version)
})

test_that("supported_languages() returns language codes including en_us", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  langs <- supported_languages()
  expect_type(langs, "character")
  expect_true(length(langs) > 0)
  expect_true("en_us" %in% langs)
})

# -- Acoustic model loading -----------------------------------------------

test_that("load_model() loads a pretrained acoustic model", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()

  expect_s3_class(model, "birdnet_model")
  expect_s3_class(model, "birdnet_model_acoustic")
  expect_equal(model$model_type, "acoustic")
  expect_equal(model$model_version, "2.4")
  expect_true(!is.null(model$py_model))
  expect_true(reticulate::is_py_object(model$py_model))
})

test_that("loaded acoustic model exposes a species list", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  species <- get_species_list(model)

  expect_type(species, "character")
  expect_true(length(species) > 100) # BirdNET v2.4 has thousands of species
})

# -- Geo model loading ----------------------------------------------------

test_that("load_model() loads a pretrained geo model", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()

  expect_s3_class(model, "birdnet_model")
  expect_s3_class(model, "birdnet_model_geo")
  expect_equal(model$model_type, "geo")
  expect_equal(model$model_version, "2.4")
  expect_true(!is.null(model$py_model))
  expect_true(reticulate::is_py_object(model$py_model))
})

test_that("loaded geo model exposes a species list", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  species <- get_species_list(model)

  expect_type(species, "character")
  expect_true(length(species) > 100)
})

# -- Model wrapper structure ----------------------------------------------

test_that("acoustic model wrapper has the expected S3 class vector", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()

  classes <- class(model)
  # Must include versioned type class, type class, backend class, and base class
  expect_true("birdnet_model_acoustic_v2_4" %in% classes)
  expect_true("birdnet_model_acoustic" %in% classes)
  expect_true("birdnet_model_tf" %in% classes)
  expect_true("birdnet_model" %in% classes)
})

test_that("geo model wrapper has the expected S3 class vector", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()

  classes <- class(model)
  expect_true("birdnet_model_geo_v2_4" %in% classes)
  expect_true("birdnet_model_geo" %in% classes)
  expect_true("birdnet_model_tf" %in% classes)
  expect_true("birdnet_model" %in% classes)
})

# -- Custom model loading (error paths) -----------------------------------

test_that("load_custom() errors when model path does not exist", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    load_custom(
      model = "/nonexistent/path/model.tflite",
      species_list = "/nonexistent/path/species.txt"
    )
  )
})

test_that("load_custom() errors when species_list is NULL", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    load_custom(model = "/some/path/model.tflite", species_list = NULL),
    "must be provided"
  )
})

test_that("load_custom() errors when model is NULL", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    load_custom(model = NULL, species_list = "/some/path/species.txt"),
    "must be provided"
  )
})
