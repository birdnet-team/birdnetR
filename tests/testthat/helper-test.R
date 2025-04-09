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
#' @param model_type Type of model (tflite, protobuf, meta, etc.)
#' @return A mock model object that can be used for testing
create_mock_model <- function(version = "v2.4", language = "en_us", model_type = "tflite") {
  # Create a mock Python object
  mock_py_obj <- create_mock_py_object(list(
    language = language,
    predict = function(...) {
      # Return a mock prediction structure that matches what the real model would return
      list(
        "(0.0, 3.0)" = list(
          "Cyanocitta cristata_Blue Jay" = 0.85,
          "Zenaida macroura_Mourning Dove" = 0.65
        ),
        "(3.0, 6.0)" = list(
          "Poecile atricapillus_Black-capped Chickadee" = 0.75
        )
      )
    }
  ))

  # Temporarily override reticulate::is_py_object to recognize our mock objects
  old_is_py_object <- reticulate::is_py_object

  tryCatch({
    # Assign the mocked function
    assignInNamespace("is_py_object", mock_is_py_object(), ns = "reticulate")

    # Now create the model using the package function
    model <- new_birdnet_model(
      mock_py_obj,
      model_version = version,
      language = language,
      subclass = model_type
    )

    return(model)
  }, finally = {
    # Always restore the original function to prevent side effects
    assignInNamespace("is_py_object", old_is_py_object, ns = "reticulate")
  })
}

#' SECTION 2: SHARED TEST RESOURCES
#' These functions provide cached access to real models for integration tests

# Lazy-loaded models - only initialized when needed
.test_models <- new.env()

#' Get a TFLite model for integration testing
#'
#' This function returns a cached model or initializes a new one
#' @param skip_if_not_available If TRUE, skips the test if model can't be initialized
#' @return A TFLite model or skips the test
get_test_tflite_model <- function(skip_if_not_available = TRUE) {
  if (!exists("tflite", envir = .test_models)) {
    # First check if we should even attempt model initialization
    if (is_full_test_env()) {
      tryCatch({
        message("Initializing TFLite model for tests...")
        model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
        assign("tflite", model, envir = .test_models)
      }, error = function(e) {
        if (skip_if_not_available) {
          skip(paste("Failed to initialize TFLite model:", e$message))
        } else {
          NULL
        }
      })
    } else {
      if (skip_if_not_available) {
        skip("Not in a full test environment - TFLite model not available")
      }
      return(NULL)
    }
  }

  return(get("tflite", envir = .test_models))
}

#' Get a Meta model for integration testing
#' 
#' This function returns a cached model or initializes a new one
#' @param skip_if_not_available If TRUE, skips the test if model can't be initialized
#' @return A Meta model or skips the test
get_test_meta_model <- function(skip_if_not_available = TRUE) {
  if (!exists("meta", envir = .test_models)) {
    # First check if we should even attempt model initialization
    if (is_full_test_env()) {
      tryCatch({
        message("Initializing Meta model for tests...")
        model <- birdnet_model_meta(version = "v2.4", language = "en_us")
        assign("meta", model, envir = .test_models)
      }, error = function(e) {
        if (skip_if_not_available) {
          skip(paste("Failed to initialize Meta model:", e$message))
        } else {
          NULL
        }
      })
    } else {
      if (skip_if_not_available) {
        skip("Not in a full test environment - Meta model not available")
      }
      return(NULL)
    }
  }

  return(get("meta", envir = .test_models))
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