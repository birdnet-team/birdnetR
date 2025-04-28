test_that("predictions_to_df handles empty predictions", {
  empty_predictions <- list()
  result <- predictions_to_df(empty_predictions, keep_empty = FALSE)
  expect_equal(nrow(result), 0)

  result_with_empty <- predictions_to_df(empty_predictions, keep_empty = TRUE)
  expect_equal(nrow(result_with_empty), 0)
})

test_that("predictions_to_df correctly processes prediction data", {
  # Mock data structure returned by Python model
  mock_predictions <- list(
    "(0.0, 3.0)" = list(
      "Cyanocitta cristata_Blue Jay" = 0.85,
      "Zenaida macroura_Mourning Dove" = 0.65
    ),
    "(3.0, 6.0)" = list(
      "Poecile atricapillus_Black-capped Chickadee" = 0.75
    )
  )

  # Process with keep_empty = FALSE
  result <- predictions_to_df(mock_predictions, keep_empty = FALSE)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(colnames(result), c("start", "end", "scientific_name", "common_name", "confidence"))

  # Check content
  expect_equal(nrow(result), 3)
  expect_equal(result$start, c(0, 0, 3))
  expect_equal(result$end, c(3, 3, 6))
  expect_true("Cyanocitta cristata" %in% result$scientific_name)
  expect_true("Blue Jay" %in% result$common_name)
})
