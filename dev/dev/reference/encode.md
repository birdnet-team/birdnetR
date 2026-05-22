# Encode audio files using a BirdNET acoustic model

Run the encoder stage of a BirdNET acoustic model to obtain embedding
vectors for each segment of the supplied audio files. This is useful for
downstream tasks such as clustering, dimensionality reduction, or
transfer-learning workflows that build on BirdNET embeddings.

## Usage

``` r
encode(object, ...)

# S3 method for class 'birdnet_model_acoustic'
encode(
  object,
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
  ...
)
```

## Arguments

- object:

  A BirdNET model object of class `birdnet_model_acoustic` created with
  [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md)
  or
  [`load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).

- ...:

  Additional arguments passed to the generic (currently unused).

- files:

  A character vector of one or more file paths to audio files. When
  multiple files are provided the resulting data frame (via
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html))
  includes an `input` column identifying the source file for each row.

- overlap:

  A numeric value specifying the overlap duration in seconds between
  consecutive time intervals. Must be in the interval \[0.0, 3.0\].

- bandpass_fmin, bandpass_fmax:

  An integer value to set minimum and maximum frequencies for the
  bandpass filter (in Hz).

- progress:

  A character string specifying the type of progress reporting. Options
  are `"minimal"`, `"progress"`, or `"benchmark"`.

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

## Value

An S3 object of class `birdnet_encoding` containing the encoding
results. Use
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) to
convert to a data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- load_birdnet(type = "acoustic")
audio_file <- system.file("extdata", "soundscape.mp3",
  package = "birdnetR"
)
enc <- encode(model, files = audio_file)
as.data.frame(enc)
} # }
```
