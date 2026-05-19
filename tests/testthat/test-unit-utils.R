test_that("is_valid_species_list correctly validates species lists", {
  # Valid cases:
  # Character vector of species names
  expect_true(is_valid_species_list(c("species1", "species2")))
  # A list of character strings
  expect_true(is_valid_species_list(list("species1", "species2")))

  # Invalid cases:
  # Numeric vector
  expect_false(is_valid_species_list(c(1, 2, 3)))
  # Named list of non-character elements
  expect_false(is_valid_species_list(list(a = 1, b = 2)))
  # Empty vector
  expect_false(is_valid_species_list(character(0)))
  # Empty list
  expect_false(is_valid_species_list(list()))
  # List of character vectors with length > 1
  expect_false(is_valid_species_list(list(c("species1", "species2"))))
  # NULL
  expect_false(is_valid_species_list(NULL))
})

test_that("is_scalar_integer accepts integer and whole-number double values", {
  expect_true(is_scalar_integer(5L))
  expect_true(is_scalar_integer(5))
  expect_true(is_scalar_integer(0))
  expect_true(is_scalar_integer(-3L))
  expect_true(is_scalar_integer(-3))
})

test_that("is_scalar_integer rejects non-integer, non-finite, NA, and vector values", {
  expect_false(is_scalar_integer(5.5))
  expect_false(is_scalar_integer(NA_integer_))
  expect_false(is_scalar_integer(NA_real_))
  expect_false(is_scalar_integer(Inf))
  expect_false(is_scalar_integer(-Inf))
  expect_false(is_scalar_integer(NaN))
  expect_false(is_scalar_integer(c(1L, 2L)))
  expect_false(is_scalar_integer(c(1, 2)))
  expect_false(is_scalar_integer("5"))
  expect_false(is_scalar_integer(NULL))
  expect_false(is_scalar_integer(TRUE))
})
