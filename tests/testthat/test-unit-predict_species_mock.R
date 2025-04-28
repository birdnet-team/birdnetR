test_that("predict_species_from_audio_file handles mock model", {
  # Skip tests that use mocks if we're in the full test environment
  # This is just a safety to ensure we don't rely only on mocks when real testing is possible
  skip_if(is_full_test_env(), "In full test environment, skipping mocks")

  # Create mock model
  mock_model <- create_mock_model()

  # Create a more complete mock for Path that handles method chaining
  mock_path_obj <- structure(
    list(
      expanduser = function() {
        structure(
          list(
            resolve = function(...) "resolved/dummy_path.mp3"
          ),
          class = "mock_py_object"
        )
      }
    ),
    class = "mock_py_object"
  )

  # Mock our Python modules with all required functions
  mock_pathlib <- list(
    Path = function(...) mock_path_obj
  )

  # Create mock predictions with the structure expected by predictions_to_df
  mock_predictions <- mock_model$py_model$predict()

  # Mock the audio prediction module with its function
  mock_audio_prediction <- list(
    predict_species_within_audio_file = function(...) mock_predictions
  )

  # Mock the types module
  mock_types <- list(
    SpeciesPredictions = function(pred) pred
  )

  # Mock the builtins module for set() function
  mock_builtins <- list(
    set = function(x) x
  )

  # Set up all our mock bindings
  testthat::local_mocked_bindings(
    py_pathlib = mock_pathlib,
    .env = environment()
  )

  testthat::local_mocked_bindings(
    py_birdnet_audio_based_prediction = mock_audio_prediction,
    .env = environment()
  )

  testthat::local_mocked_bindings(
    py_birdnet_types = mock_types,
    .env = environment()
  )

  testthat::local_mocked_bindings(
    py_builtins = mock_builtins,
    .env = environment()
  )

  # Run the test with mocked functions
  results <- predict_species_from_audio_file(mock_model, "dummy_path.mp3", min_confidence = 0.1)

  # Validate results
  expect_s3_class(results, "data.frame")
  expect_equal(nrow(results), 3)
  expect_true(all(c("start", "end", "scientific_name", "common_name", "confidence") %in% names(results)))
})
