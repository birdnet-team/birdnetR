# Mock model objects to avoid downloading actual models
create_mock_tflite_model <- function() {
  structure(
    list(
      py_model = NULL,
      model_version = "v2.4",
      language = "en_us",
      tflite_num_threads = NULL
    ),
    class = c("birdnet_model_tflite", "birdnet_model")
  )
}

create_mock_protobuf_model <- function() {
  structure(
    list(
      py_model = NULL,
      model_version = "v2.4",
      language = "en_us"
    ),
    class = c("birdnet_model_protobuf", "birdnet_model")
  )
}

create_mock_custom_model <- function() {
  structure(
    list(
      py_model = NULL,
      model_version = "v2.4",
      classifier_folder = "/path/to/classifier",
      classifier_name = "custom_classifier",
      tflite_num_threads = NULL
    ),
    class = c("birdnet_model_custom", "birdnet_model")
  )
}

test_that("available_languages returns expected language codes", {
  # Setup mock for evaluate_python_path
  testthat::local_mocked_bindings(
    evaluate_python_path = function(path) list("en_us", "fr", "de"),
    .env = environment()
  )

  # Mock create_module_map and get_element_from_module_map
  testthat::local_mocked_bindings(
    create_module_map = function(...) list(),
    .env = environment()
  )

  testthat::local_mocked_bindings(
    get_element_from_module_map = function(...) "mock_path",
    .env = environment()
  )

  # Create mock for py_builtins$list
  mock_py_builtins <- list(list = function(obj) c("en_us", "fr", "de"))
  testthat::local_mocked_bindings(
    py_builtins = mock_py_builtins,
    .env = environment()
  )

  # Test the function
  languages <- available_languages("v2.4")
  expect_type(languages, "character")
  expect_true(all(c("de", "en_us", "fr") %in% languages))
  expect_equal(length(languages), 3)
})

test_that("read_labels correctly reads species list from file", {
  # Create a temporary file with mock species data
  temp_file <- tempfile(fileext = ".txt")
  species_list <- c(
    "Accipiter cooperii_Cooper's Hawk",
    "Agelaius phoeniceus_Red-winged Blackbird",
    "Anas platyrhynchos_Mallard"
  )
  writeLines(species_list, temp_file)

  # Mock Python path and file reading
  mock_path_obj <- list(
    expanduser = function() {
      list(
        resolve = function(...) temp_file
      )
    }
  )

  mock_pathlib <- list(
    Path = function(...) mock_path_obj
  )

  mock_py_birdnet_utils <- list(
    get_species_from_file = function(...) list(items = species_list)
  )

  testthat::local_mocked_bindings(
    py_pathlib = mock_pathlib,
    .env = environment()
  )

  testthat::local_mocked_bindings(
    py_birdnet_utils = mock_py_birdnet_utils,
    .env = environment()
  )

  # Test the function
  result <- read_labels(temp_file)
  expect_equal(result, species_list)
  expect_length(result, 3)

  # Clean up
  unlink(temp_file)
})

test_that("get_language_path validates language and returns expected path", {
  # Skip test if function is not exported (internal function)
  skip_if_not_installed("birdnetR", "0.2.2")

  # Mock available_languages
  testthat::local_mocked_bindings(
    available_languages = function(...) c("en_us", "fr", "de"),
    .env = environment()
  )

  # Mock module_map related functions
  testthat::local_mocked_bindings(
    create_module_map = function(...) list(),
    .env = environment()
  )

  testthat::local_mocked_bindings(
    get_element_from_module_map = function(...) "mock_path",
    .env = environment()
  )

  # Mock evaluate_python_path
  testthat::local_mocked_bindings(
    evaluate_python_path = function(path) {
      if (grepl("version_app_data_folder", path)) {
        function() "/mock/app/folder"
      } else {
        function(path_obj) {
          list(get_language_path = function(lang) paste0("/mock/path/to/", lang, ".txt"))
        }
      }
    },
    .env = environment()
  )

  # Create a mock model
  mock_model <- list(model_version = "v2.4")

  # Test with valid language
  path <- get_language_path(mock_model, "en_us", "downloader_tflite", "TFLite")
  expect_type(path, "character")
  expect_match(path, "en_us.txt$")

  # Test with invalid language
  expect_error(
    get_language_path(mock_model, "invalid_lang", "downloader_tflite", "TFLite"),
    "`language` must be one of"
  )
})

test_that("labels_path dispatches to correct method based on model class", {
  # Mock get_language_path for tflite and protobuf models
  testthat::local_mocked_bindings(
    get_language_path = function(model, language, downloader_key, subfolder) {
      paste0("/mock/path/to/", language, ".txt")
    },
    .env = environment()
  )

  # Create mock models
  tflite_model <- create_mock_tflite_model()
  protobuf_model <- create_mock_protobuf_model()
  custom_model <- create_mock_custom_model()

  # Test tflite model
  path <- labels_path(tflite_model, "en_us")
  expect_match(path, "en_us.txt$")

  # Test protobuf model
  path <- labels_path(protobuf_model, "fr")
  expect_match(path, "fr.txt$")

  # Test custom model
  # The custom model should directly use the classifier folder and name
  path <- labels_path(custom_model)
  expect_equal(path, file.path(custom_model$classifier_folder, paste0(custom_model$classifier_name, ".txt")))
})
