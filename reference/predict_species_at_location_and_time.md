# Predict species for a given location and time

Uses the BirdNET Species Range Model to estimate the presence of bird
species at a specified location and time of year.

## Usage

``` r
predict_species_at_location_and_time(
  model,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03
)

# S3 method for class 'birdnet_model_meta'
predict_species_at_location_and_time(
  model,
  latitude,
  longitude,
  week = NULL,
  min_confidence = 0.03
)
```

## Arguments

- model:

  birdnet_model_meta. An instance of the BirdNET model returned by
  [`birdnet_model_meta()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md).

- latitude:

  numeric. The latitude of the location for species prediction. Must be
  in the interval \[-90.0, 90.0\].

- longitude:

  numeric. The longitude of the location for species prediction. Must be
  in the interval \[-180.0, 180.0\].

- week:

  integer. The week of the year for which to predict species. Must be in
  the interval \[1, 48\] if specified. If NULL, predictions are not
  limited to a specific week.

- min_confidence:

  numeric. Minimum confidence threshold for predictions to be considered
  valid. Must be in the interval \[0, 1.0).

## Value

A data frame with columns: `label`, `confidence`. Each row represents a
predicted species, with the `confidence` indicating the likelihood of
the species being present at the specified location and time.

## Details

The BirdNET Species Range Model leverages eBird checklist frequency data
to estimate the probability of bird species occurrences based on
latitude, longitude, and time of year. It integrates actual observations
and expert-curated data, making it adaptable to regions with varying
levels of data availability. The model employs circular embeddings and a
classifier to predict species presence and migration patterns, achieving
higher accuracy in data-rich regions and lower accuracy in
underrepresented areas like parts of Africa and Asia. For more details,
you can view the full discussion here:
https://github.com/kahst/BirdNET-Analyzer/discussions/234

## Examples

``` r
# Predict species in Chemnitz, Germany, that are present all year round
if (FALSE) { # \dontrun{
model <- birdnet_model_meta(language = "de")
predict_species_at_location_and_time(model, latitude = 50.8334, longitude = 12.9231)
} # }
```
