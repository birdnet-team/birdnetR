# Write BirdNET prediction results to file

Write prediction results to disk using the underlying Python result
object. The format can be inferred from the file extension or specified
explicitly.

## Usage

``` r
write_predictions(x, file, format = NULL, ...)

# S3 method for class 'birdnet_prediction_geo'
write_predictions(x, file, format = NULL, ...)

# S3 method for class 'birdnet_prediction'
write_predictions(x, file, format = NULL, ...)
```

## Arguments

- x:

  A BirdNET prediction object (as returned by
  [`predict()`](https://rdrr.io/r/stats/predict.html)).

- file:

  Output file path.

- format:

  Output file format. If `NULL` (default), inferred from the file
  extension. Explicit values: `"csv"`, `"parquet"`, `"npz"`.

- ...:

  Additional arguments passed to the underlying Python method.

## Value

Invisibly returns the output file path.

## Details

Supported formats by prediction type:

- **Acoustic predictions**: CSV (`.csv`), Parquet (`.parquet`), NumPy
  (`.npz`)

- **Geo predictions**: CSV (`.csv`), NumPy (`.npz`)

## Examples

``` r
if (FALSE) { # \dontrun{
write_predictions(pred, "results.csv")
write_predictions(pred, "results.parquet")
write_predictions(pred, "results.npz")
write_predictions(pred, "output.csv", format = "csv")
} # }
```
