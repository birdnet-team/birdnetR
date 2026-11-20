test_that("resolve_save_format takes the format from the file extension", {
  expect_equal(resolve_save_format("out.csv"), "csv")
  expect_equal(resolve_save_format("out.parquet"), "parquet")
  expect_equal(resolve_save_format("out.npz"), "npz")
})

# The Python writers refuse any other extension, so R stops first.
test_that("resolve_save_format needs a lower-case .csv, .parquet or .npz extension", {
  msg <- "`file` must end in `.csv`, `.parquet` or `.npz`"
  expect_error(resolve_save_format("out.xyz"), msg, fixed = TRUE)
  expect_error(resolve_save_format("out"), msg, fixed = TRUE)
  expect_error(resolve_save_format("OUT.CSV"), msg, fixed = TRUE)
  expect_error(resolve_save_format(1), "`file` must be a file path", fixed = TRUE)
})

test_that("birdnet_write has no format argument", {
  expect_named(formals(birdnet_write), c("x", "file", "..."))
})

test_that("birdnet_write expands ~ before the path reaches Python", {
  seen <- NULL
  pred <- structure(
    list(py_predictions = list(to_csv = function(path, ...) seen <<- path)),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )
  out <- birdnet_write(pred, "~/results.csv")
  expect_equal(seen, path.expand("~/results.csv"))
  expect_equal(out, path.expand("~/results.csv"))
})

test_that("birdnet_write dispatches to correct Python method for each format", {
  called <- NULL
  mock_result <- list(
    to_csv = function(path, ...) {
      called <<- "csv"
      invisible(NULL)
    },
    to_parquet = function(path, ...) {
      called <<- "parquet"
      invisible(NULL)
    },
    save = function(path, ...) {
      called <<- "npz"
      invisible(NULL)
    }
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  birdnet_write(pred, "out.csv")
  expect_equal(called, "csv")

  birdnet_write(pred, "out.parquet")
  expect_equal(called, "parquet")

  birdnet_write(pred, "out.npz")
  expect_equal(called, "npz")
})

test_that("birdnet_write rejects parquet for geo predictions", {
  mock_result <- list(
    to_csv = function(path, ...) invisible(NULL),
    save = function(path, ...) invisible(NULL)
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_geo", "birdnet_prediction")
  )

  expect_error(
    birdnet_write(pred, "out.parquet"),
    "Parquet format is not supported for geo predictions"
  )
})

test_that("birdnet_write allows csv and npz for geo predictions", {
  called <- NULL
  mock_result <- list(
    to_csv = function(path, ...) {
      called <<- "csv"
      invisible(NULL)
    },
    save = function(path, ...) {
      called <<- "npz"
      invisible(NULL)
    }
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_geo", "birdnet_prediction")
  )

  birdnet_write(pred, "out.csv")
  expect_equal(called, "csv")

  birdnet_write(pred, "out.npz")
  expect_equal(called, "npz")
})

test_that("birdnet_write returns file path invisibly", {
  mock_result <- list(
    to_csv = function(path, ...) invisible(NULL)
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  expect_invisible(result <- birdnet_write(pred, "results.csv"))
  expect_equal(result, "results.csv")
})

test_that("birdnet_write errors when predictions are NULL", {
  pred <- structure(
    list(py_predictions = NULL),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  expect_error(
    birdnet_write(pred, "out.csv"),
    "No prediction results available"
  )
})

test_that("birdnet_write dispatches encodings to the right Python method", {
  calls <- character()
  enc <- structure(
    list(
      py_encodings = list(
        to_csv = function(...) calls <<- c(calls, "csv"),
        to_parquet = function(...) calls <<- c(calls, "parquet"),
        save = function(...) calls <<- c(calls, "npz")
      )
    ),
    class = "birdnet_encoding"
  )
  for (f in c("e.csv", "e.parquet", "e.npz")) {
    birdnet_write(enc, f)
  }
  expect_equal(calls, c("csv", "parquet", "npz"))
})

test_that("birdnet_write returns file path invisibly for encodings", {
  enc <- structure(
    list(py_encodings = list(to_csv = function(...) invisible(NULL))),
    class = "birdnet_encoding"
  )
  expect_invisible(result <- birdnet_write(enc, "e.csv"))
  expect_equal(result, "e.csv")
})

test_that("birdnet_write errors when encodings are NULL", {
  enc <- structure(list(py_encodings = NULL), class = "birdnet_encoding")
  expect_error(birdnet_write(enc, "e.csv"), "No encoding results available")
})
