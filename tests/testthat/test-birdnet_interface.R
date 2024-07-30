library(testthat)
library(birdnetR)
library(reticulate)


# Explicitly set the virtual environment
use_virtualenv("r-birdnet", required = TRUE)

# Test to ensure the environment is correctly set up
test_that("Python environment is set up correctly", {
  expect_true(py_module_available("birdnet.models"))
})

# Function to validate the environment setup
validate_python_env <- function() {
  tryCatch({
    use_virtualenv("r-birdnet", required = TRUE)
    py_run_string("import llvmlite")
    py_run_string("import numba")
    TRUE
  }, error = function(e) {
    message("Validation failed: ", e$message)
    FALSE
  })
}

if (!validate_python_env()) {
  stop("Python environment validation failed. Please check your setup.")
}


test_that("Environment diagnostics", {
  cat("Python version:", py_config()$version, "\n")
  cat("Virtualenv:", py_config()$virtualenv, "\n")
  cat("Sys.getenv(PATH):", Sys.getenv("PATH"), "\n")
  cat("Sys.getenv(LD_LIBRARY_PATH):", Sys.getenv("LD_LIBRARY_PATH"), "\n")
})


test_that("init_model initializes the BirdNET model correctly", {
  skip_if_not_installed("reticulate")

  tryCatch({
    model <- init_model()

    # Check that model is not NULL and has the correct class
    expect_true(!is.null(model))
    expect_true(inherits(model, "birdnet.models.model_v2m4.ModelV2M4"))
  }, error = function(e) {
    cat("An error occurred during model initialization:\n")
    print(e)
    cat("Last Python error:\n")
    print(reticulate::py_last_error())
    stop(e)
  })
})

test_that("predict_species predicts species from an audio file", {
  skip_if_not_installed("reticulate")

  tryCatch({
    model <- init_model()
    audio_file <- system.file("extdata", "soundscape.wav", package = "birdnetR")
    predictions <- predict_species(model, audio_file = audio_file)

    # Check that predictions is not NULL and is a data frame
    expect_true(!is.null(predictions))
    expect_true(is.data.frame(predictions))

    # Check that the data frame has the expected columns
    expected_columns <- c("start", "end", "scientific_name", "common_name", "confidence")
    expect_true(all(expected_columns %in% names(predictions)))
  }, error = function(e) {
    cat("An error occurred during species prediction:\n")
    print(e)
    cat("Last Python error:\n")
    print(reticulate::py_last_error())
    stop(e)
  })
})



# test_that("get_top_prediction works", {
#   model <- init_model()
#   audio_path <- system.file("extdata", "soundscape.wav", package = "birdnetR")
#   predictions <- predict_species(model, audio_file = audio_path)
#
#   top_prediction <- get_top_prediction(predictions, filter = list(start = 18, end = 21))
#   expect_true(nrow(top_prediction) == 1)
#
#   # without start and end filter, we expect more than 1 row but less rows when we have multiple predictions for a single time intervall
#   top_prediction <- get_top_prediction(predictions)
#   expect_true(nrow(top_prediction) > 1)
#   expect_true(nrow(top_prediction) <= nrow(predictions))
# })
