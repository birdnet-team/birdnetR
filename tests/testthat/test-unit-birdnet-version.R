# Unit tests for birdnet_version()

test_that("birdnet_version() returns correct structure when Python is available", {
  local_mocked_bindings(
    py_config = function() {
      list(version = "3.12.3", python = "/usr/bin/python3")
    },
    import = function(module, ...) {
      list(version = function(pkg) "0.2.16")
    },
    .package = "reticulate"
  )

  result <- birdnet_version()

  expect_type(result, "list")
  expect_named(result, c("python_version", "python_executable", "birdnet_version"))
  expect_equal(result$python_version, "3.12.3")
  expect_equal(result$python_executable, "/usr/bin/python3")
  expect_equal(result$birdnet_version, "0.2.16")
})

test_that("birdnet_version() returns NA with warning when Python is unavailable", {
  local_mocked_bindings(
    py_config = function() stop("Python not found"),
    import = function(module, ...) stop("Python not found"),
    .package = "reticulate"
  )

  expect_warning(
    expect_warning(
      result <- birdnet_version(),
      "Could not determine birdnet version"
    ),
    "Could not determine Python version"
  )

  expect_type(result, "list")
  expect_named(result, c("python_version", "python_executable", "birdnet_version"))
  expect_true(is.na(result$python_version))
  expect_true(is.na(result$python_executable))
  expect_true(is.na(result$birdnet_version))
})

test_that("birdnet_version() returns NA birdnet_version when birdnet is not installed", {
  local_mocked_bindings(
    py_config = function() {
      list(version = "3.12.3", python = "/usr/bin/python3")
    },
    import = function(module, ...) {
      stop("No package metadata was found for birdnet")
    },
    .package = "reticulate"
  )

  expect_warning(
    result <- birdnet_version(),
    "Could not determine birdnet version"
  )

  expect_equal(result$python_version, "3.12.3")
  expect_equal(result$python_executable, "/usr/bin/python3")
  expect_true(is.na(result$birdnet_version))
})

test_that("birdnet_version() returns all character values", {
  local_mocked_bindings(
    py_config = function() {
      list(version = "3.11.0", python = "/path/to/python")
    },
    import = function(module, ...) {
      list(version = function(pkg) "0.2.17")
    },
    .package = "reticulate"
  )

  result <- birdnet_version()

  expect_type(result$python_version, "character")
  expect_type(result$python_executable, "character")
  expect_type(result$birdnet_version, "character")
  expect_length(result$python_version, 1)
  expect_length(result$python_executable, 1)
  expect_length(result$birdnet_version, 1)
})
