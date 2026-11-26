# Predict species with a BirdNET model

`birdnet_predict()` runs a loaded model. What it predicts depends on the
model:

- acoustic models (BirdNET, Perch, custom classifiers) identify species
  in audio files, see
  [`birdnet_predict.birdnet_model_acoustic()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.birdnet_model_acoustic.md);

- geo models predict which species occur at a location and week of the
  year, see
  [`birdnet_predict.birdnet_model_geo()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.birdnet_model_geo.md).

## Usage

``` r
birdnet_predict(model, ...)
```

## Arguments

- model:

  A BirdNET model object, see
  [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

- ...:

  Arguments for the model-specific method.

## Value

An S3 prediction object; convert it with
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) or save
it with
[`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md).

## See also

[`birdnet_list_models()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_models.md)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_load()
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
predictions <- birdnet_predict(model, files = audio_file)
as.data.frame(predictions)

geo <- birdnet_load(type = "geo")
as.data.frame(birdnet_predict(geo, latitude = 50.83, longitude = 12.92, week = 18L))
} # }
```
