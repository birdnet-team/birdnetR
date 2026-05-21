# Predict species using a BirdNET geo model

This function predicts species occurence for a location and week of the
year using a BirdNET geo model.

## Usage

``` r
# S3 method for class 'birdnet_model_geo'
predict(
  object,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03,
  half_precision = NULL,
  ...
)
```

## Arguments

- object:

  A BirdNET model object of class `birdnet_model_geo` created with
  [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).

- latitude:

  A numeric value representing the latitude of the location.

- longitude:

  A numeric value representing the longitude of the location.

- week:

  An integer value representing the week of the year (1-52).

- min_confidence:

  A numeric value to set the minimum confidence threshold for
  predictions.

- half_precision:

  A logical value indicating whether to use float16 where supported for
  inference. If `NULL` (default), the Python backend default is used.

- ...:

  Additional arguments passed to the generic (currently unused).

## Value

An S3 object of class `birdnet_prediction_geo` and `birdnet_prediction`
containing the prediction results.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a BirdNET geo model
model <- load_birdnet(type = "geo")
# Predict species for a specific location and week
predictions <- predict(model, latitude = 50.8334, longitude = 12.9231, week = 18L)
# Convert predictions to a data frame
as.data.frame(predictions)
} # }
```
