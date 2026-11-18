# Unit tests for birdnet_use_gpu()

# Mocks the platform, the extra declaration and reticulate. Returns an
# environment recording the declared extra and extra py_require() packages.
local_gpu_mocks <- function(
  sysname = "Linux",
  machine = "x86_64",
  py_running = FALSE,
  env = parent.frame()
) {
  cap <- new.env()
  cap$extra <- NULL
  cap$required <- NULL
  testthat::local_mocked_bindings(
    platform = function() c(sysname = sysname, machine = machine),
    require_birdnet_extra = function(extra) cap$extra <- extra,
    .env = env
  )
  testthat::local_mocked_bindings(
    py_available = function(...) py_running,
    py_require = function(packages, ...) cap$required <- packages,
    .package = "reticulate",
    .env = env
  )
  cap
}

test_that("birdnet_use_gpu() errors once Python is running", {
  cap <- local_gpu_mocks(py_running = TRUE)
  expect_error(birdnet_use_gpu(), "before any model is loaded")
  expect_null(cap$extra)
})

test_that("birdnet_use_gpu() rejects unknown backends", {
  local_gpu_mocks()
  expect_error(birdnet_use_gpu("onnx"), "should be one of")
})

test_that("Linux pt requires [pt] and sets UV_TORCH_BACKEND=auto when unset", {
  withr::local_envvar(UV_TORCH_BACKEND = NA)
  cap <- local_gpu_mocks()
  expect_true(birdnet_use_gpu("pt"))
  expect_equal(cap$extra, "pt")
  expect_equal(Sys.getenv("UV_TORCH_BACKEND"), "auto")
})

test_that("Linux pt is the default backend", {
  withr::local_envvar(UV_TORCH_BACKEND = NA)
  cap <- local_gpu_mocks()
  birdnet_use_gpu()
  expect_equal(cap$extra, "pt")
})

test_that("Linux pt keeps a UV_TORCH_BACKEND the user already set", {
  withr::local_envvar(UV_TORCH_BACKEND = "rocm6.4")
  cap <- local_gpu_mocks()
  birdnet_use_gpu("pt")
  expect_equal(cap$extra, "pt")
  expect_equal(Sys.getenv("UV_TORCH_BACKEND"), "rocm6.4")
})

test_that("Linux pb requires [and-cuda]", {
  withr::local_envvar(UV_TORCH_BACKEND = NA)
  cap <- local_gpu_mocks()
  expect_invisible(birdnet_use_gpu("pb"))
  expect_equal(cap$extra, "and-cuda")
  expect_null(cap$required)
  expect_equal(Sys.getenv("UV_TORCH_BACKEND", unset = NA), NA_character_)
})

test_that("macOS arm64 pb requires [tf] and tensorflow-metal", {
  cap <- local_gpu_mocks(sysname = "Darwin", machine = "arm64")
  birdnet_use_gpu("pb")
  expect_equal(cap$extra, "tf")
  expect_equal(cap$required, "tensorflow-metal")
})

test_that("unsupported platform/backend combinations point to the vignette", {
  cap <- local_gpu_mocks(sysname = "Windows", machine = "x86-64")
  expect_error(
    birdnet_use_gpu("pt"),
    "No automatic GPU setup for Windows/x86-64 with backend 'pt'.*vignette"
  )
  expect_error(birdnet_use_gpu("pb"), "Windows/x86-64 with backend 'pb'")
  expect_null(cap$extra)

  cap <- local_gpu_mocks(sysname = "Darwin", machine = "arm64")
  expect_error(
    birdnet_use_gpu("pt"),
    "No automatic GPU setup for Darwin/arm64 with backend 'pt'.*vignette"
  )
  expect_null(cap$extra)
  expect_null(cap$required)
})

test_that("platform() reports the system and machine from Sys.info()", {
  p <- platform()
  expect_named(p, c("sysname", "machine"))
  expect_equal(p[["sysname"]], Sys.info()[["sysname"]])
  expect_equal(p[["machine"]], Sys.info()[["machine"]])
})
