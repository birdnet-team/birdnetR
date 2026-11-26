# Predict species from audio files using a BirdNET acoustic model

Identifies species in audio files with an acoustic model (BirdNET+ V3.0,
BirdNET V2.4, Perch v2 or a custom classifier).

## Usage

``` r
# S3 method for class 'birdnet_model_acoustic'
birdnet_predict(
  model,
  files,
  min_confidence = 0.1,
  min_confidence_custom = NULL,
  top_k = 5L,
  overlap = 0,
  apply_sigmoid = NULL,
  sigmoid_sensitivity = NULL,
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
  apply_softmax = NULL,
  segment_size_s = NULL,
  device = NULL,
  ...
)
```

## Arguments

- model:

  A BirdNET model object of class `birdnet_model_acoustic`, see
  [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md),
  [`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  and
  [`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

- files:

  A character vector of one or more file paths to audio files. The
  resulting data frame (via
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)) has an
  `input` column that names the source file of each row.

- min_confidence:

  A numeric value to set the minimum confidence threshold for
  predictions.

- min_confidence_custom:

  A named list where each element is a single numeric value to set
  custom minimum confidence thresholds for specific species. A custom
  threshold will override the default one.

- top_k:

  An integer specifying the number of top predictions to return for each
  segment if above minimum confidence threshold. `NULL` returns every
  species above the threshold.

- overlap:

  A numeric value specifying the overlap duration in seconds between
  consecutive segments. Must be smaller than the segment length (3 s for
  BirdNET V2.4; see `segment_size_s` for V3.0).

- apply_sigmoid:

  A logical value indicating whether to apply a sigmoid function to the
  confidence scores. If `NULL` (default), the model's own default is
  used.

- sigmoid_sensitivity:

  A numeric value that shifts the sigmoid scores, see Details. Must be
  in the interval \[0.5, 1.5\]. If `NULL` (default), the model's own
  default (1.0) is used.

- bandpass_fmin, bandpass_fmax:

  An integer value to set minimum and maximum frequencies for the
  bandpass filter (in Hz).

- species_list:

  A character vector or list of species names to filter the predictions.
  If `NULL`, all species are considered.

- progress:

  A character string specifying the type of progress reporting. Options
  are `"minimal"`, `"progress"`, or `"benchmark"`.

- n_producers:

  An integer specifying the number of processes that read and prepare
  audio batches. Must be \>= 1. If `NULL` (default), the default of the
  `birdnet` Python package is used.

- n_workers:

  An integer specifying the number of worker processes for parallel
  inference. Each worker loads its own copy of the model. If `NULL`
  (default), `birdnet` chooses based on available CPU cores and memory;
  with a GPU `device`, one worker per device.

- batch_size:

  An integer specifying the number of audio segments evaluated per
  inference call. Must be \>= 1. The BirdNET+ V3.0 `"pb"` and `"tf"`
  models only accept 1; use `n_workers` for parallelism there. If `NULL`
  (default), the default of the `birdnet` Python package (1) is used.

- prefetch_ratio:

  An integer specifying how many batches to decode ahead of processing.
  Must be \>= 0. If `NULL` (default), the default of the `birdnet`
  Python package is used.

- speed:

  A numeric value for the resampling multiplier to accommodate different
  recording speeds. Must be in the interval \[0.01, 100\]. If `NULL`
  (default), the default of the `birdnet` Python package is used.

- half_precision:

  A logical value indicating whether to store the model's outputs as
  float16 (inference itself runs at the model's precision). If `NULL`
  (default), the default of the `birdnet` Python package is used.

- max_audio_duration_min:

  A numeric value specifying the longest single input in minutes. Must
  be \> 0. If `NULL` (default), no limit is applied.

- apply_softmax:

  A logical value. If `TRUE`, scores become a softmax over the model's
  logits (e.g. for Perch v2). Not supported by models that apply the
  sigmoid inside the model (BirdNET+ V3.0, Raven exports). If `NULL`
  (default), the model's own default (`FALSE`) is used.

- segment_size_s:

  A numeric value: length of the analyzed segments in seconds (BirdNET+
  V3.0 only; it accepts variable-length input). If `NULL` (default), the
  model's own default is used.

- device:

  A character string, `"CPU"` or `"GPU"` (or a vector of devices). If
  `NULL` (default), the CPU is used. See
  [`birdnet_use_gpu()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_use_gpu.md).

- ...:

  Not used. Passing any other argument is an error.

## Value

An S3 object of class `birdnet_prediction_acoustic` and
`birdnet_prediction` containing the prediction results.

## Details

### Confidence scores

With `apply_sigmoid = NULL` (default) each model uses its own default:
BirdNET models and custom classifiers return sigmoid scores between 0
and 1, Perch v2 returns raw model outputs (logits). A score reflects how
certain the model is. It is not the probability that the species is
present.

`sigmoid_sensitivity` shifts the scores: values above 1 raise them,
values below 1 lower them (the logits are shifted by
`10 * (sigmoid_sensitivity - 1)` before the sigmoid). It has no effect
with `apply_sigmoid = FALSE`.

For guidelines on BirdNET scores and on converting them to
probabilities, see Wood & Kahl (2024).

## References

Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of
BirdNET scores and other detector outputs. Journal of Ornithology.
https://doi.org/10.1007/s10336-024-02144-5

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a BirdNET acoustic model
model <- birdnet_load()
# Predict species from audio files
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
predictions <- birdnet_predict(model, files = audio_file)
# convert predictions to a data frame
as.data.frame(predictions)
} # }
```
