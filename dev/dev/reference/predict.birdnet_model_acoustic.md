# Predict species from audio files using a BirdNET acoustic model

This function predicts species from audio files using a BirdNET acoustic
model.

## Usage

``` r
# S3 method for class 'birdnet_model_acoustic'
predict(
  object,
  files,
  min_confidence = 0.1,
  min_confidence_custom = NULL,
  top_k = 5L,
  overlap = 0,
  apply_sigmoid = TRUE,
  sigmoid_sensitivity = 1,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
  species_list = NULL,
  progress = c("minimal", "progress", "benchmark"),
  n_producers = NULL,
  n_workers = NULL,
  batch_size = NULL,
  prefetch_ratio = NULL,
  speed = NULL,
  half_precision = NULL,
  max_audio_duration_min = NULL,
  ...
)
```

## Arguments

- object:

  A BirdNET model object of class `birdnet_model_acoustic` created with
  [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).

- files:

  A character vector of one or more file paths to audio files. When
  multiple files are provided, the returned prediction object will
  contain results for all files; the resulting data frame (via
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html))
  includes an `input` column identifying the source file for each
  prediction row.

- min_confidence:

  A numeric value to set the minimum confidence threshold for
  predictions.

- min_confidence_custom:

  A named list where each element is a single numeric value to set
  custom minimum confidence thresholds for specific species. A custom
  threshold will override the default one.

- top_k:

  An integer specifying the number of top predictions to return for each
  time interval if above minimum confidence threshold.

- overlap:

  A numeric value specifying the overlap duration in seconds between
  consecutive time intervals. Must be in the interval \[0.0, 3.0\].

- apply_sigmoid:

  A logical value indicating whether to apply a sigmoid function to the
  confidence scores.

- sigmoid_sensitivity:

  A numeric value that adjusts the sensitivity of the sigmoid function.
  Must be in the interval \[0.5, 1.5\].

- bandpass_fmin, bandpass_fmax:

  A integer value to set minimum and maximum frequencies for the
  bandpass filter (in Hz).

- species_list:

  A character vector or list of species names to filter the predictions.
  If `NULL`, all species are considered.

- progress:

  A character string specifying the type of progress reporting. Options
  are "minimal", "progress", or "benchmark".

- n_producers:

  An integer specifying the number of threads for producing audio
  batches. Must be \>= 1. If `NULL` (default), the Python backend
  default is used.

- n_workers:

  An integer specifying the number of backend workers for parallel
  inference. If `NULL` (default), the Python backend auto-detects based
  on available CPU cores.

- batch_size:

  An integer specifying the number of audio segments evaluated per
  inference call. Must be \>= 1. If `NULL` (default), the Python backend
  default is used.

- prefetch_ratio:

  An integer specifying how many batches to decode ahead of processing.
  Must be \>= 0. If `NULL` (default), the Python backend default is
  used.

- speed:

  A numeric value for the resampling multiplier to accommodate different
  recording speeds. Must be in the interval \[0.01, 100\]. If `NULL`
  (default), the Python backend default is used.

- half_precision:

  A logical value indicating whether to use float16 where supported for
  inference. If `NULL` (default), the Python backend default is used.

- max_audio_duration_min:

  A numeric value specifying the maximum total audio duration per call
  in minutes. Must be \> 0. If `NULL` (default), no limit is applied.

- ...:

  Additional arguments passed to the generic (currently unused).

## Value

An S3 object of class `birdnet_prediction_acoustic` and
`birdnet_prediction` containing the prediction results.

## Details

### Sigmoid Activation

When `apply_sigmoid = TRUE`, the raw logit scores from the linear
classifier are passed through a sigmoid function, scaling them into the
range \[0, 1\]. This unitless confidence score reflects BirdNET’s
certainty in its prediction (it is not a direct probability of species
presence). Adjusting the `sigmoid_sensitivity` parameter modifies the
score distribution:

- Values **\< 1** tend to produce more extreme scores (closer to 0 or
  1).

- Values **\> 1** result in scores that are more moderate (centered
  around intermediate values).

For additional details on BirdNET confidence scores and guidelines for
converting them to probabilities, see Wood & Kahl (2024).

## References

Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of
BirdNET scores and other detector outputs. Journal of Ornithology.
https://doi.org/10.1007/s10336-024-02144-5

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a BirdNET acoustic model
model <- load_birdnet(type = "acoustic")
# Predict species from audio files
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
predictions <- predict(model, files = audio_file)
# convert predictions to a data frame
as.data.frame(predictions)
} # }
```
