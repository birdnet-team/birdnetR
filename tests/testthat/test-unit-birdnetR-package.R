# Unit tests for .birdnet_py_spec() — the internal helper that builds
# the birdnet Python package requirement string.

test_that(".birdnet_py_spec() returns the default bounded range when no env var is set", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = NA), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() returns the default range for an empty env var", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = ""), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() returns the default range for whitespace-only env var", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "   "), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() accepts a valid exact pin", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "==1.5.0"), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet==1.5.0")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a two-segment version pin", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "==1.5"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a pin missing the operator", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "1.5.0"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a range specifier", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = ">=1.5.1,<1.6"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that(".birdnet_py_spec() warns and falls back when package name is included", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "birdnet==1.5.0"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=1.5,<2")
  })
})

test_that("require_birdnet_extra() adds the extra to the version spec", {
  captured <- NULL
  testthat::local_mocked_bindings(
    py_require = function(packages, ...) captured <<- packages,
    py_available = function(...) FALSE,
    .package = "reticulate"
  )
  withr::with_envvar(
    c(BIRDNETR_BIRDNET_VERSION = NA),
    birdnetR:::require_birdnet_extra("tf")
  )
  expect_equal(captured, "birdnet[tf]>=1.5,<2")
  withr::with_envvar(
    c(BIRDNETR_BIRDNET_VERSION = "==1.5.0"),
    birdnetR:::require_birdnet_extra("pt")
  )
  expect_equal(captured, "birdnet[pt]==1.5.0")
})

test_that("require_birdnet_extra() declares the extra's own packages once Python runs", {
  captured <- NULL
  testthat::local_mocked_bindings(
    py_require = function(packages, ...) captured <<- packages,
    py_available = function(...) TRUE,
    .package = "reticulate"
  )
  testthat::local_mocked_bindings(is_intel_mac = function() FALSE)
  birdnetR:::require_birdnet_extra("tf")
  expect_equal(captured, "tensorflow>=2.8.0")
  birdnetR:::require_birdnet_extra("pt")
  expect_equal(captured, "torch>=2.0.0")

  testthat::local_mocked_bindings(is_intel_mac = function() TRUE)
  captured <- NULL
  expect_error(birdnetR:::require_birdnet_extra("tf"), "Restart R")
  expect_null(captured)
})

test_that("use_managed_python() keeps a user's RETICULATE_PYTHON", {
  withr::with_envvar(c(RETICULATE_PYTHON = "/opt/venv/bin/python"), {
    birdnetR:::use_managed_python()
    expect_equal(Sys.getenv("RETICULATE_PYTHON"), "/opt/venv/bin/python")
  })
  withr::with_envvar(c(RETICULATE_PYTHON = NA), {
    birdnetR:::use_managed_python()
    expect_equal(Sys.getenv("RETICULATE_PYTHON"), "managed")
  })
})

test_that("is_intel_mac() builds on platform()", {
  intel <- function(sysname, machine) {
    testthat::local_mocked_bindings(
      platform = function() c(sysname = sysname, machine = machine)
    )
    birdnetR:::is_intel_mac()
  }
  expect_true(intel("Darwin", "x86_64"))
  expect_false(intel("Darwin", "arm64"))
  expect_false(intel("Linux", "x86_64"))
})

test_that("use_private_keras_home() keeps a user's KERAS_HOME", {
  withr::with_envvar(c(KERAS_HOME = "/my/keras"), {
    birdnetR:::use_private_keras_home()
    expect_equal(Sys.getenv("KERAS_HOME"), "/my/keras")
  })
  withr::with_envvar(c(KERAS_HOME = NA), {
    birdnetR:::use_private_keras_home()
    expect_equal(Sys.getenv("KERAS_HOME"), tools::R_user_dir("birdnetR", "config"))
  })
})
