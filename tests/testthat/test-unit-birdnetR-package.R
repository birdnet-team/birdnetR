# Unit tests for .birdnet_py_spec() — the internal helper that builds
# the birdnet Python package requirement string.

test_that(".birdnet_py_spec() returns the default bounded range when no env var is set", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = NA), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() returns the default range for an empty env var", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = ""), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() returns the default range for whitespace-only env var", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "   "), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() accepts a valid exact pin", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "==0.2.16"), {
    spec <- birdnetR:::.birdnet_py_spec()
    expect_equal(spec, "birdnet==0.2.16")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a two-segment version pin", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "==0.2"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a pin missing the operator", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "0.2.16"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() warns and falls back for a range specifier", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = ">=0.2.14,<0.3"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})

test_that(".birdnet_py_spec() warns and falls back when package name is included", {
  withr::with_envvar(c(BIRDNETR_BIRDNET_VERSION = "birdnet==0.2.16"), {
    expect_warning(
      spec <- birdnetR:::.birdnet_py_spec(),
      "Ignoring invalid BIRDNETR_BIRDNET_VERSION"
    )
    expect_equal(spec, "birdnet>=0.2.16,<0.3")
  })
})
