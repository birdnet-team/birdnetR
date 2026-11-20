# Unit tests for birdnet_sitrep()

fields <- c(
  "python_version",
  "python_executable",
  "birdnet_version",
  "runtimes"
)
runtime_names <- c("onnxruntime", "ai_edge_litert", "tensorflow", "torch")

# Same shape as reticulate::py_config(): `version` is a package_version with
# only major.minor, the full version is the first word of `version_string`.
fake_py_config <- function() {
  list(
    version = package_version("3.12"),
    version_string = "3.12.3 (main, Jan  1 2026, 00:00:00) [GCC]",
    python = "/usr/bin/python3"
  )
}

# A stand-in for reticulate::import() that serves importlib.metadata and
# importlib.util. `installed` are the modules find_spec() finds (it returns
# NULL for the others, as reticulate converts Python None to NULL).
fake_import <- function(bn_version = "1.5.0", installed = character()) {
  function(module, ...) {
    switch(
      module,
      "importlib.metadata" = list(version = function(pkg) bn_version),
      "importlib.util" = list(
        find_spec = function(name) if (name %in% installed) list() else NULL
      ),
      stop("unexpected import: ", module)
    )
  }
}

test_that("birdnet_sitrep() returns correct structure when Python is available", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = fake_import(),
    .package = "reticulate"
  )

  result <- birdnet_sitrep()

  expect_s3_class(result, "birdnet_sitrep")
  expect_type(result, "list")
  expect_named(result, fields)
  expect_identical(result$python_version, "3.12.3")
  expect_equal(result$python_executable, "/usr/bin/python3")
  expect_equal(result$birdnet_version, "1.5.0")
})

test_that("birdnet_sitrep() returns NA with warning when Python is unavailable", {
  local_mocked_bindings(
    py_config = function() stop("Python not found"),
    import = function(module, ...) stop("Python not found"),
    .package = "reticulate"
  )

  expect_warning(
    expect_warning(
      expect_warning(
        result <- birdnet_sitrep(),
        "Could not determine installed runtimes"
      ),
      "Could not determine birdnet version"
    ),
    "Could not determine Python version"
  )

  expect_s3_class(result, "birdnet_sitrep")
  expect_named(result, fields)
  expect_true(is.na(result$python_version))
  expect_true(is.na(result$python_executable))
  expect_true(is.na(result$birdnet_version))
  expect_equal(names(result$runtimes), runtime_names)
  expect_true(all(is.na(result$runtimes)))
})

test_that("birdnet_sitrep() returns NA birdnet_version when birdnet is not installed", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = function(module, ...) {
      if (module == "importlib.metadata") {
        stop("No package metadata was found for birdnet")
      }
      fake_import()(module)
    },
    .package = "reticulate"
  )

  expect_warning(
    result <- birdnet_sitrep(),
    "Could not determine birdnet version"
  )

  expect_identical(result$python_version, "3.12.3")
  expect_equal(result$python_executable, "/usr/bin/python3")
  expect_true(is.na(result$birdnet_version))
  expect_false(anyNA(result$runtimes))
})

test_that("birdnet_sitrep() returns character values for the three fields", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = fake_import("1.5.1"),
    .package = "reticulate"
  )

  result <- birdnet_sitrep()

  expect_type(result$python_version, "character")
  expect_type(result$python_executable, "character")
  expect_type(result$birdnet_version, "character")
  expect_length(result$python_version, 1)
  expect_length(result$python_executable, 1)
  expect_length(result$birdnet_version, 1)
})

test_that("birdnet_sitrep() reports a named logical vector of runtimes", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = fake_import(installed = c("onnxruntime", "torch")),
    .package = "reticulate"
  )

  s <- birdnet_sitrep()

  expect_type(s$runtimes, "logical")
  expect_equal(names(s$runtimes), runtime_names)
  expect_equal(
    s$runtimes,
    c(
      onnxruntime = TRUE,
      ai_edge_litert = FALSE,
      tensorflow = FALSE,
      torch = TRUE
    )
  )
})

test_that("birdnet_sitrep() does not import the runtimes", {
  imported <- character()
  local_mocked_bindings(
    py_config = fake_py_config,
    import = function(module, ...) {
      imported <<- c(imported, module)
      fake_import(installed = runtime_names)(module)
    },
    .package = "reticulate"
  )

  birdnet_sitrep()

  expect_setequal(imported, c("importlib.metadata", "importlib.util"))
})

test_that("print.birdnet_sitrep() prints one line per field", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = fake_import(installed = c("onnxruntime", "ai_edge_litert")),
    .package = "reticulate"
  )

  s <- birdnet_sitrep()

  expect_output(print(s), "python_version: 3.12.3")
  expect_output(print(s), "python_executable: /usr/bin/python3")
  expect_output(print(s), "birdnet_version: 1.5.0")
  expect_output(print(s), "runtimes: onnxruntime, ai_edge_litert")

  expect_output(res <- withVisible(print(s)))
  expect_false(res$visible)
  expect_identical(res$value, s)
})

test_that("print.birdnet_sitrep() says none when no runtime is installed", {
  local_mocked_bindings(
    py_config = fake_py_config,
    import = fake_import(),
    .package = "reticulate"
  )

  expect_output(print(birdnet_sitrep()), "runtimes: none")
})

test_that("print.birdnet_sitrep() prints NA when runtimes are unknown", {
  s <- structure(
    list(
      python_version = NA_character_,
      python_executable = NA_character_,
      birdnet_version = NA_character_,
      runtimes = c(
        onnxruntime = NA,
        ai_edge_litert = NA,
        tensorflow = NA,
        torch = NA
      )
    ),
    class = "birdnet_sitrep"
  )

  expect_output(print(s), "runtimes: NA")
})

test_that("birdnet_version() is no longer defined", {
  expect_false(
    exists("birdnet_version", envir = asNamespace("birdnetR"), inherits = FALSE)
  )
})
