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
    inherits(object, "mock_py_object") ||
      inherits(object, "birdnet_py_mock") ||
      reticulate::py_is_null_xptr(object) == FALSE
  }
}

#' Create a mock BirdNET model for unit testing
#'
#' Creates a mock model that doesn't require Python dependencies or
#' actual model initialization. Use this in unit tests.
#'
#' @param version Version string
#' @param language Language code
#' @param model_type Type of model (acoustic, geo, etc.)
#' @return A mock model object that can be used for testing
create_mock_model <- function(
  version = "2.4",
  language = "en_us",
  model_type = "acoustic"
) {
  mock_py_obj <- create_mock_py_object()

  structure(
    list(
      py_model = mock_py_obj,
      model_type = model_type,
      model_version = version,
      language = language
    ),
    class = c(
      paste0("birdnet_model_", model_type),
      "birdnet_model"
    )
  )
}

#' SECTION 2: SHARED TEST RESOURCES
#' These functions provide cached access to real models for integration tests

# Lazy-loaded models - only initialized when needed
.test_models <- new.env()

#' Get an acoustic model for integration testing
#'
#' Returns a cached acoustic model loaded via load_model(), or initializes a
#' new one. Skips the test if the model cannot be loaded.
#' @param skip_if_not_available If TRUE, skips the test if model can't be loaded
#' @return An acoustic model or skips the test
get_test_acoustic_model <- function(skip_if_not_available = TRUE) {
  if (!exists("acoustic_new", envir = .test_models)) {
    if (is_full_test_env()) {
      tryCatch(
        {
          model <- load_model(
            type = "acoustic",
            version = "2.4",
            backend = "tf"
          )
          assign("acoustic_new", model, envir = .test_models)
        },
        error = function(e) {
          if (skip_if_not_available) {
            skip(paste("Failed to load acoustic model:", e$message))
          }
          return(NULL)
        }
      )
    } else {
      if (skip_if_not_available) {
        skip("Not in a full test environment - acoustic model not available")
      }
      return(NULL)
    }
  }
  get("acoustic_new", envir = .test_models)
}

#' Get a geo model for integration testing
#'
#' Returns a cached geo model loaded via load_model(), or initializes a
#' new one. Skips the test if the model cannot be loaded.
#' @param skip_if_not_available If TRUE, skips the test if model can't be loaded
#' @return A geo model or skips the test
get_test_geo_model <- function(skip_if_not_available = TRUE) {
  if (!exists("geo_new", envir = .test_models)) {
    if (is_full_test_env()) {
      tryCatch(
        {
          model <- load_model(
            type = "geo",
            version = "2.4",
            backend = "tf"
          )
          assign("geo_new", model, envir = .test_models)
        },
        error = function(e) {
          if (skip_if_not_available) {
            skip(paste("Failed to load geo model:", e$message))
          }
          return(NULL)
        }
      )
    } else {
      if (skip_if_not_available) {
        skip("Not in a full test environment - geo model not available")
      }
      return(NULL)
    }
  }
  get("geo_new", envir = .test_models)
}

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
