# Encode audio files using a BirdNET acoustic model

Run the encoder stage of a BirdNET acoustic model to obtain embedding
vectors for each segment of the supplied audio files. This is useful for
downstream tasks such as clustering, dimensionality reduction, or
transfer-learning workflows that build on BirdNET embeddings.

## Usage

``` r
birdnet_encode(model, ...)

# S3 method for class 'birdnet_model_acoustic'
birdnet_encode(
  model,
  files,
  overlap = 0,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
  progress = c("minimal", "progress", "benchmark"),
  n_producers = NULL,
  n_workers = NULL,
  batch_size = NULL,
  prefetch_ratio = NULL,
  speed = NULL,
  half_precision = NULL,
  max_audio_duration_min = NULL,
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

- ...:

  Not used. Passing any other argument is an error.

- files:

  A character vector of one or more file paths to audio files. The
  resulting data frame (via
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)) has an
  `input` column that names the source file of each row.

- overlap:

  A numeric value specifying the overlap duration in seconds between
  consecutive segments. Must be smaller than the segment length (3 s for
  BirdNET V2.4; see `segment_size_s` for V3.0).

- bandpass_fmin, bandpass_fmax:

  An integer value to set minimum and maximum frequencies for the
  bandpass filter (in Hz).

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

- segment_size_s:

  A numeric value: length of the analyzed segments in seconds (BirdNET+
  V3.0 only; it accepts variable-length input). If `NULL` (default), the
  model's own default is used.

- device:

  A character string, `"CPU"` or `"GPU"` (or a vector of devices). If
  `NULL` (default), the CPU is used. See
  [`birdnet_use_gpu()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_use_gpu.md).

## Value

An S3 object of class `birdnet_encoding` containing the embeddings. Use
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) to
convert to a data frame.

## See also

[`as.data.frame.birdnet_encoding()`](https://birdnet-team.github.io/birdnetR/dev/reference/as.data.frame.birdnet_encoding.md),
[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_load()
audio_file <- system.file("extdata", "soundscape.mp3",
  package = "birdnetR"
)
enc <- birdnet_encode(model, files = audio_file)
as.data.frame(enc)
} # }
```
