test_that("get_species_list returns character vector from model", {
  mock_species <- c(
    "Cyanocitta cristata_Blue Jay",
    "Zenaida macroura_Mourning Dove"
  )

  model <- structure(
    list(
      py_model = list(species_list = mock_species),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_acoustic", "birdnet_model")
  )

  result <- get_species_list(model)
  expect_type(result, "character")
  expect_length(result, 2)
  expect_equal(result, mock_species)
})

test_that("get_species_list works for custom models", {
  mock_species <- c("Custom Species A", "Custom Species B", "Custom Species C")

  model <- structure(
    list(
      py_model = list(species_list = mock_species),
      model_type = "acoustic",
      model_version = "2.4"
    ),
    class = c("birdnet_model_custom", "birdnet_model")
  )

  result <- get_species_list(model)
  expect_type(result, "character")
  expect_length(result, 3)
})

test_that("get_species_list errors for non-model input", {
  expect_error(
    get_species_list("not_a_model"),
    "must be a BirdNET model object"
  )
  expect_error(get_species_list(42), "must be a BirdNET model object")
  expect_error(get_species_list(list()), "must be a BirdNET model object")
})
