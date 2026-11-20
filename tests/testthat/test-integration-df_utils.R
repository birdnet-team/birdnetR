# Integration tests for inst/python/df_utils.py. They build NumPy structured
# arrays in Python, so they need the Python environment but no model.

test_that("df_utils.predictions_to_dict converts structured array to R-friendly dict", {
  skip_if_not_installed("reticulate")
  skip_if_not(is_full_test_env(), "Needs real Python (set BIRDNETR_RUN_INTEGRATION_TESTS=true)")

  # Build a numpy structured array matching birdnet's geo format
  mock_pred <- reticulate::py_run_string(
    "
import numpy as np

class MockGeoPred:
    def to_structured_array(self, **kwargs):
        dtype = [('species_name', '<U20'), ('confidence', np.float32)]
        arr = np.empty(2, dtype=dtype)
        arr['species_name'] = ['Blue Jay', 'House Sparrow']
        arr['confidence'] = [0.85, 0.50]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$predictions_to_dict(mock_pred$MockGeoPred())

  # Result should be a plain R list
  expect_type(result, "list")
  expect_named(result, c("species_name", "confidence"))

  # String column must be character vector of correct length
  expect_type(result$species_name, "character")
  expect_length(result$species_name, 2)
  expect_equal(result$species_name, c("Blue Jay", "House Sparrow"))

  # Numeric column
  expect_type(result$confidence, "double")
  expect_length(result$confidence, 2)
  expect_equal(as.numeric(result$confidence), c(0.85, 0.50), tolerance = 1e-4)

  # Must produce a valid data.frame
  df <- as.data.frame(result, stringsAsFactors = FALSE)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_true(all(sapply(df, length) == nrow(df)))
})

test_that("df_utils.predictions_to_dict handles multi-file object-dtype input column", {
  skip_if_not_installed("reticulate")
  skip_if_not(is_full_test_env(), "Needs real Python (set BIRDNETR_RUN_INTEGRATION_TESTS=true)")

  # Build a structured array with object-dtype "input" column (as
  # AcousticFilePredictionResult produces) containing two distinct file paths
  mock_pred <- reticulate::py_run_string(
    "
import numpy as np

class MockMultiFilePred:
    def to_structured_array(self, **kwargs):
        dtype = [
            ('input', object),
            ('start_time', np.float32),
            ('end_time', np.float32),
            ('species_name', object),
            ('confidence', np.float32),
        ]
        arr = np.empty(3, dtype=dtype)
        arr['input'] = ['/path/a.wav', '/path/a.wav', '/path/b.wav']
        arr['start_time'] = [0.0, 3.0, 0.0]
        arr['end_time'] = [3.0, 6.0, 3.0]
        arr['species_name'] = ['Blue Jay', 'House Sparrow', 'Blue Jay']
        arr['confidence'] = [0.85, 0.50, 0.70]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$predictions_to_dict(mock_pred$MockMultiFilePred())

  # input column must be a plain character vector

  expect_type(result$input, "character")
  expect_length(result$input, 3)
  expect_equal(result$input, c("/path/a.wav", "/path/a.wav", "/path/b.wav"))

  # species_name column must also be character
  expect_type(result$species_name, "character")

  # should produce a valid data.frame
  df <- as.data.frame(result, stringsAsFactors = FALSE)
  expect_s3_class(df, "data.frame")

  expect_equal(nrow(df), 3)
  # Both files present
  expect_equal(sort(unique(df$input)), c("/path/a.wav", "/path/b.wav"))
})

# --- Regression: integer-like doubles must be coerced to R integer ----------

test_that("predictions_to_dict keeps column names for an empty result", {
  skip_if_not_installed("reticulate")
  skip_if_not(is_full_test_env(), "Needs real Python (set BIRDNETR_RUN_INTEGRATION_TESTS=true)")

  mock_pred <- reticulate::py_run_string(
    "
import numpy as np

class MockEmptyPred:
    def to_structured_array(self, **kwargs):
        dtype = [
            ('input', object),
            ('start_time', np.float32),
            ('end_time', np.float32),
            ('species_name', object),
            ('confidence', np.float32),
        ]
        return np.empty(0, dtype=dtype)
",
    convert = FALSE
  )
  helper <- reticulate::import_from_path("df_utils", system.file("python", package = "birdnetR"))

  df <- as.data.frame(helper$predictions_to_dict(mock_pred$MockEmptyPred()), stringsAsFactors = FALSE)
  expect_named(df, c("input", "start_time", "end_time", "species_name", "confidence"))
  expect_equal(nrow(df), 0L)
  expect_type(df$input, "character")
})

test_that("df_utils.encodings_to_dict converts structured array to R-friendly dict", {
  skip_if_not_installed("reticulate")
  skip_if_not(is_full_test_env(), "Needs real Python (set BIRDNETR_RUN_INTEGRATION_TESTS=true)")

  mock_enc <- reticulate::py_run_string(
    "
import numpy as np

class MockEncoding:
    def to_structured_array(self):
        emb_dim = 3
        dtype = [
            ('input', object),
            ('start_time', np.float32),
            ('end_time', np.float32),
            ('embedding', np.float32, emb_dim),
        ]
        arr = np.empty(2, dtype=dtype)
        arr['input'] = ['/path/a.wav', '/path/a.wav']
        arr['start_time'] = [0.0, 3.0]
        arr['end_time'] = [3.0, 6.0]
        arr['embedding'] = [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]]
        return arr
",
    convert = FALSE
  )

  helper <- reticulate::import_from_path(
    "df_utils",
    system.file("python", package = "birdnetR")
  )

  result <- helper$encodings_to_dict(mock_enc$MockEncoding())

  expect_type(result, "list")
  expect_named(result, c("input", "start_time", "end_time", "embedding"))
  expect_type(result$input, "character")
  expect_length(result$input, 2)

  # embedding should be a list of numeric vectors
  expect_type(result$embedding, "list")
  expect_length(result$embedding, 2)
  expect_equal(
    as.numeric(result$embedding[[1]]),
    c(0.1, 0.2, 0.3),
    tolerance = 1e-4
  )

  # Must produce a valid data.frame
  scalar_data <- result[names(result) != "embedding"]
  df <- as.data.frame(scalar_data, stringsAsFactors = FALSE)
  df$embedding <- result$embedding
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
})

