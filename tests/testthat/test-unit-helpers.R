test_that("get_top_prediction returns highest confidence predictions", {
  # Create a test data frame
  test_df <- data.frame(
    start = c(0, 0, 1, 1, 2, 2),
    end = c(1, 1, 2, 2, 3, 3),
    scientific_name = c(
      "Species A",
      "Species B",
      "Species A",
      "Species B",
      "Species A",
      "Species B"
    ),
    common_name = c(
      "Common A",
      "Common B",
      "Common A",
      "Common B",
      "Common A",
      "Common B"
    ),
    confidence = c(0.1, 0.2, 0.5, 0.3, 0.7, 0.8),
    stringsAsFactors = FALSE
  )

  # Test getting top prediction for each interval
  top_predictions <- get_top_prediction(test_df)

  # Should have 3 rows (one per interval)
  expect_equal(nrow(top_predictions), 3)

  # Check that each row has the highest confidence for its interval
  expect_equal(top_predictions$confidence[top_predictions$start == 0 & top_predictions$end == 1], 0.2)
  expect_equal(top_predictions$confidence[top_predictions$start == 1 & top_predictions$end == 2], 0.5)
  expect_equal(top_predictions$confidence[top_predictions$start == 2 & top_predictions$end == 3], 0.8)

  # Test with specific filter
  filtered_top <- get_top_prediction(test_df, filter = list(start = 1, end = 2))
  expect_equal(nrow(filtered_top), 1)
  expect_equal(filtered_top$scientific_name, "Species A")
  expect_equal(filtered_top$confidence, 0.5)

  # Test with empty result after filter
  empty_filter_top <- get_top_prediction(test_df, filter = list(start = 5, end = 6))
  expect_equal(empty_filter_top, NULL)

  # Test error cases
  expect_error(get_top_prediction("not a data frame"), "The 'data' argument must be a data frame.")
  expect_error(get_top_prediction(data.frame(a = 1)), "Data frame must contain the following columns:")
  expect_error(get_top_prediction(test_df, filter = "not a list"), "The 'filter' must be a list")
  expect_error(get_top_prediction(test_df, filter = list(wrong = 1)), "The 'filter' must be a list containing 'start' and 'end'")
})
