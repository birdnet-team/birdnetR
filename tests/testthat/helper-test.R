# Comprehensive helper file for birdnetR tests
# Contains mocks, fixtures, and shared resources for testing

#' SECTION 1: MOCK OBJECTS FOR UNIT TESTS
#' These functions create mock objects that don't require Python

#' Create a mock Python object for testing
#'
#' This helper creates a mock that satisfies is_py_object() checks.
#' To use this in tests, you need to mock the is_py_object function.
#'
#' @param attributes List of attributes to attach to the mock object
#' @return A mock object that behaves like a Python object
create_mock_py_object <- function(attributes = list()) {
  obj <- structure(
    attributes,
    class = c("mock_py_object")
  )
  return(obj)
}

#' Creates a function to check if an object is a mock Python object for testing
#'
#' @return Function that returns TRUE for mock objects and real Python objects
mock_is_py_object <- function() {
  function(object) {
    inherits(object, "mock_py_object")
  }
}

#' SECTION 2: SHARED TEST RESOURCES
#' These functions provide cached access to real models for integration tests

# Lazy-loaded models - only initialized when needed
.test_models <- new.env()

#' Get a cached model for integration testing
#'
#' Skips when integration tests are disabled. A model that fails to load is an
#' error, so the calling test fails.
#' @param type "acoustic" or "geo"
#' @return A BirdNET 3.0 model loaded with birdnet_load()
get_test_model <- function(type) {
  skip_if_not(is_full_test_env(), "Not in full test environment")
  if (is.null(.test_models[[type]])) {
    .test_models[[type]] <- suppressMessages(birdnet_load(type = type))
  }
  .test_models[[type]]
}

get_test_acoustic_model <- function() get_test_model("acoustic")
get_test_geo_model <- function() get_test_model("geo")

#' Get standard test audio file path
#'
#' @return Path to the test audio file or skips the test if not found
test_audio_file <- function() {
  audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
  if (audio_file == "") {
    skip("Test audio file not found")
  }
  return(audio_file)
}
