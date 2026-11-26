# Predict species using a BirdNET geo model

Predicts which species occur at a location and week of the year with a
BirdNET geo model.

## Usage

``` r
# S3 method for class 'birdnet_model_geo'
birdnet_predict(
  model,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03,
  half_precision = NULL,
  year_round_aggregation = NULL,
  device = NULL,
  ...
)
```

## Arguments

- model:

  A BirdNET model object of class `birdnet_model_geo`, see
  [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

- latitude:

  A numeric value representing the latitude of the location.

- longitude:

  A numeric value representing the longitude of the location.

- week:

  An integer value representing the week of the year (1-48). If `NULL`
  (default), predicts for the whole year.

- min_confidence:

  A numeric value to set the minimum confidence threshold for
  predictions.

- half_precision:

  A logical value indicating whether to store the model's outputs as
  float16 (inference itself runs at the model's precision). If `NULL`
  (default), the default of the `birdnet` Python package is used.

- year_round_aggregation:

  `"max"` or `"average"`: how weekly scores are combined when
  `week = NULL`. If `NULL` (default), the model's own default (`"max"`)
  is used.

- device:

  A character string, `"CPU"` or `"GPU"`. If `NULL` (default), the CPU
  is used.

- ...:

  Not used. Passing any other argument is an error.

## Value

An S3 object of class `birdnet_prediction_geo` and `birdnet_prediction`
containing the prediction results.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a BirdNET geo model
model <- birdnet_load(type = "geo")
# Predict species for a specific location and week
predictions <- birdnet_predict(model, latitude = 50.8334, longitude = 12.9231, week = 18L)
# Convert predictions to a data frame
as.data.frame(predictions)
} # }
```
