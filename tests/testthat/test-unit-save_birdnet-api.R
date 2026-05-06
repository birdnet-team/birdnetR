test_that("resolve_save_format infers format from file extension", {
  expect_equal(resolve_save_format("out.csv", NULL), "csv")
  expect_equal(resolve_save_format("out.parquet", NULL), "parquet")
  expect_equal(resolve_save_format("out.npz", NULL), "npz")
})

test_that("resolve_save_format uses explicit format over extension", {
  expect_equal(resolve_save_format("out.csv", "parquet"), "parquet")
  expect_equal(resolve_save_format("out.npz", "csv"), "csv")
})

test_that("resolve_save_format errors on unknown extension without explicit format", {
  expect_error(resolve_save_format("out.xyz", NULL), "Cannot infer format")
})

test_that("resolve_save_format errors on unsupported explicit format", {
  expect_error(resolve_save_format("out.csv", "json"), "Unsupported format")
})

test_that("save_birdnet dispatches to correct Python method for each format", {
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

  save_birdnet(pred, "out.csv")
  expect_equal(called, "csv")

  save_birdnet(pred, "out.parquet")
  expect_equal(called, "parquet")

  save_birdnet(pred, "out.npz")
  expect_equal(called, "npz")
})

test_that("save_birdnet rejects parquet for geo predictions", {
  mock_result <- list(
    to_csv = function(path, ...) invisible(NULL),
    save = function(path, ...) invisible(NULL)
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_geo", "birdnet_prediction")
  )

  expect_error(
    save_birdnet(pred, "out.parquet"),
    "Parquet format is not supported for geo predictions"
  )
})

test_that("save_birdnet allows csv and npz for geo predictions", {
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

  save_birdnet(pred, "out.csv")
  expect_equal(called, "csv")

  save_birdnet(pred, "out.npz")
  expect_equal(called, "npz")
})

test_that("save_birdnet returns file path invisibly", {
  mock_result <- list(
    to_csv = function(path, ...) invisible(NULL)
  )

  pred <- structure(
    list(py_predictions = mock_result),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  result <- save_birdnet(pred, "results.csv")
  expect_equal(result, "results.csv")
})

test_that("save_birdnet errors when predictions are NULL", {
  pred <- structure(
    list(py_predictions = NULL),
    class = c("birdnet_prediction_acoustic", "birdnet_prediction")
  )

  expect_error(save_birdnet(pred, "out.csv"), "No prediction results available")
})
