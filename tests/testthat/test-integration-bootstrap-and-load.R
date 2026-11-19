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

  pkg_version <- birdnet_sitrep()$birdnet_version
  expect_gte(utils::compareVersion(pkg_version, "1.5.0"), 0)
  expect_lt(utils::compareVersion(pkg_version, "2"), 0)
})

# -- Discovery helpers ----------------------------------------------------

test_that("birdnet_list_models() covers every official model and Perch", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  # guards the private _OFFICIAL_MODELS table of the Python package
  models <- birdnet_list_models()
  expect_s3_class(models, "data.frame")
  expect_named(
    models,
    c("type", "version", "backend", "library", "precision", "needs")
  )
  for (type in c("acoustic", "geo")) {
    for (version in c("2.4", "3.0")) {
      expect_gte(
        sum(models$type == type & models$version == version),
        1
      )
    }
  }
  expect_gte(
    sum(models$type == "acoustic" & models$version == "perch_v2"),
    1
  )
})

test_that("birdnet_list_languages() returns language codes including en_us", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  for (version in c("3.0", "2.4")) {
    langs <- birdnet_list_languages(version)
    expect_type(langs, "character")
    expect_true("en_us" %in% langs)
  }
})

# -- Acoustic model loading -----------------------------------------------

test_that("birdnet_load() loads and announces a BirdNET 3.0 acoustic model", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_message(model <- birdnet_load(), "BirdNET acoustic 3.0")

  expect_s3_class(model, "birdnet_model")
  expect_s3_class(model, "birdnet_model_acoustic")
  expect_equal(model$model_type, "acoustic")
  expect_equal(model$model_version, "3.0")
  expect_equal(model$backend, "onnx")
  expect_true(!is.null(model$py_model))
  expect_true(reticulate::is_py_object(model$py_model))
})

test_that("loaded acoustic model exposes a species list", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()
  species <- birdnet_list_species(model)

  expect_type(species, "character")
  expect_true(length(species) > 100) # BirdNET 3.0 has thousands of species
})

# -- Geo model loading ----------------------------------------------------

test_that("birdnet_load() loads and announces a BirdNET 3.0 geo model", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_message(model <- birdnet_load(type = "geo"), "BirdNET geo 3.0")

  expect_s3_class(model, "birdnet_model")
  expect_s3_class(model, "birdnet_model_geo")
  expect_equal(model$model_type, "geo")
  expect_equal(model$model_version, "3.0")
  expect_equal(model$backend, "onnx")
  expect_true(!is.null(model$py_model))
  expect_true(reticulate::is_py_object(model$py_model))
})

test_that("loaded geo model exposes a species list", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()
  species <- birdnet_list_species(model)

  expect_type(species, "character")
  expect_true(length(species) > 100)
})

# -- BirdNET 2.4 loading --------------------------------------------------

test_that("birdnet_load(version = \"2.4\") loads and announces a 2.4 model", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_message(
    model <- birdnet_load(version = "2.4"),
    "BirdNET acoustic 2.4"
  )

  expect_s3_class(model, "birdnet_model_acoustic")
  expect_equal(model$model_version, "2.4")
  expect_equal(model$backend, "tf")
  # The default install has no TensorFlow: 2.4 runs on LiteRT
  expect_equal(model$library, "litert")
  expect_true(reticulate::is_py_object(model$py_model))
})

# -- Model wrapper structure ----------------------------------------------

test_that("acoustic model wrapper has the expected S3 class vector", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_acoustic_model()

  classes <- class(model)
  # Must include versioned type class, type class, backend class, and base class
  expect_true("birdnet_model_acoustic_v3_0" %in% classes)
  expect_true("birdnet_model_acoustic" %in% classes)
  expect_true("birdnet_model_onnx" %in% classes)
  expect_true("birdnet_model" %in% classes)
})

test_that("geo model wrapper has the expected S3 class vector", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  model <- get_test_geo_model()

  classes <- class(model)
  expect_true("birdnet_model_geo_v3_0" %in% classes)
  expect_true("birdnet_model_geo" %in% classes)
  expect_true("birdnet_model_onnx" %in% classes)
  expect_true("birdnet_model" %in% classes)
})

# -- Custom model loading (error paths) -----------------------------------

test_that("birdnet_load_custom() errors when model path does not exist", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    birdnet_load_custom(
      model = "/nonexistent/path/model.tflite",
      species_list = "/nonexistent/path/species.txt"
    )
  )
})

test_that("birdnet_load_custom() errors when species_list is missing", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    birdnet_load_custom(model = "/some/path/model.tflite"),
    "must be provided"
  )
})

test_that("birdnet_load_custom() errors when model is missing", {
  skip_if_not(is_full_test_env(), "Not in full test environment")

  expect_error(
    birdnet_load_custom(species_list = "/some/path/species.txt"),
    "must be provided"
  )
})
