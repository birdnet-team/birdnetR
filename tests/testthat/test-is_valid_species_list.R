library(testthat)


# Test cases
test_that("is_valid_species_list identifies valid vectors and lists", {
  # Vector of characters with length > 0
  expect_true(is_valid_species_list(c("a", "b", "c")))

  # List where each element is a single character string
  expect_true(is_valid_species_list(list(
    a = "x", b = "y", c = "z"
  )))

  # Vector of non-characters
  expect_false(is_valid_species_list(c(1, 2, 3)))

  # List with non-character elements
  expect_false(is_valid_species_list(list(a = 1, b = 2)))

  # Empty vector
  expect_false(is_valid_species_list(c()))

  # Empty list
  expect_false(is_valid_species_list(list()))

  # List where one element has more than one element
  expect_false(is_valid_species_list(list(a = "a", b = c("b", "c"))))

  # List with some single character entries and one empty entry
  expect_false(is_valid_species_list(list(a = "a", b = character(0))))

  # List with NULL entries
  expect_false(is_valid_species_list(list(a = NULL, b = "a")))
})

test_that("is_valid_species_list works with get_species_from_file", {
  species_list <- get_species_from_file(system.file("extdata", "species_list.txt", package = "birdnetR"))
  expect_true(is_valid_species_list(species_list))
})
