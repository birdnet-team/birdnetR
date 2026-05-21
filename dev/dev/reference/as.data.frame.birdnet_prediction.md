# Convert BirdNET prediction results to a data frame

Convert predictions from a geo or acoustic model to a data frame.

## Usage

``` r
# S3 method for class 'birdnet_prediction'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'birdnet_prediction_geo'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A BirdNET prediction object (as returned by
  [`predict()`](https://rdrr.io/r/stats/predict.html)).

- row.names:

  `NULL` or a character vector giving the row names for the data frame.
  Not used.

- optional:

  logical. Not used.

- ...:

  Additional arguments (ignored).

## Value

A data frame containing the prediction results.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a BirdNET acoustic model
model <- load_birdnet(type = "acoustic")
# Predict species from audio files
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
predictions <- predict(model, files = audio_file)
# Convert predictions to a data frame
as.data.frame(predictions)
} # }
```
