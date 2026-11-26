# Write BirdNET predictions or embeddings to a file

Writes predictions or embeddings to disk straight from Python, without
converting them to an R data frame first. The file extension selects the
format.

## Usage

``` r
birdnet_write(x, file, ...)

# S3 method for class 'birdnet_prediction_geo'
birdnet_write(x, file, ...)

# S3 method for class 'birdnet_prediction'
birdnet_write(x, file, ...)

# S3 method for class 'birdnet_encoding'
birdnet_write(x, file, ...)
```

## Arguments

- x:

  A prediction or encoding object (from
  [`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
  or
  [`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)).

- file:

  Output file path. It must end in `.csv`, `.parquet` or `.npz` (lower
  case); the extension selects the format.

- ...:

  Additional arguments passed to the underlying Python method.

## Value

Invisibly returns the output file path, with `~` expanded.

## Details

Supported formats by result type:

- **Acoustic predictions**: CSV (`.csv`), Parquet (`.parquet`), NumPy
  (`.npz`)

- **Geo predictions**: CSV (`.csv`), NumPy (`.npz`)

- **Embeddings**: CSV (`.csv`), Parquet (`.parquet`), NumPy (`.npz`)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_load()
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")

predictions <- birdnet_predict(model, files = audio_file)
birdnet_write(predictions, file.path(tempdir(), "results.csv"))
birdnet_write(predictions, file.path(tempdir(), "results.parquet"))

embeddings <- birdnet_encode(model, files = audio_file)
birdnet_write(embeddings, file.path(tempdir(), "embeddings.npz"))
} # }
```
