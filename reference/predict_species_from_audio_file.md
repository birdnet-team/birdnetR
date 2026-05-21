# Predict species within an audio file using a BirdNET model

Use a BirdNET model to predict species within an audio file. The model
can be a TFLite model, a custom model, or a Protobuf model.

## Usage

``` r
predict_species_from_audio_file(
  model,
  audio_file,
  min_confidence = 0.1,
  batch_size = 1L,
  chunk_overlap_s = 0,
  use_bandpass = TRUE,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
  apply_sigmoid = TRUE,
  sigmoid_sensitivity = 1,
  filter_species = NULL,
  keep_empty = TRUE,
  use_arrow = FALSE
)

# S3 method for class 'birdnet_model'
predict_species_from_audio_file(
  model,
  audio_file,
  min_confidence = 0.1,
  batch_size = 1L,
  chunk_overlap_s = 0,
  use_bandpass = TRUE,
  bandpass_fmin = 0L,
  bandpass_fmax = 15000L,
  apply_sigmoid = TRUE,
  sigmoid_sensitivity = 1,
  filter_species = NULL,
  keep_empty = TRUE,
  use_arrow = FALSE
)
```

## Arguments

- model:

  A BirdNET model object. An instance of the BirdNET model (e.g.,
  [`birdnet_model_tflite()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)).

- audio_file:

  character. The path to the audio file.

- min_confidence:

  numeric. Minimum confidence threshold for predictions (default is
  0.1).

- batch_size:

  integer. Number of audio samples to process in a batch (default is
  1L).

- chunk_overlap_s:

  numeric. The overlap between audio chunks in seconds (default is 0).
  Must be in the interval \[0.0, 3.0\].

- use_bandpass:

  logical. Whether to apply a bandpass filter (default is TRUE).

- bandpass_fmin, bandpass_fmax:

  integer. Minimum and maximum frequencies for the bandpass filter (in
  Hz). Ignored if `use_bandpass` is FALSE (default is 0L to 15000L).

- apply_sigmoid:

  logical. Whether to apply a sigmoid function to the model output
  (default is TRUE).

- sigmoid_sensitivity:

  numeric. Sensitivity parameter for the sigmoid function (default is
  1). Must be in the interval \[0.5, 1.5\]. Ignored if `apply_sigmoid`
  is FALSE.

- filter_species:

  NULL, a character vector of length greater than 0, or a list where
  each element is a single non-empty character string. Used to filter
  the predictions. If NULL (default), no filtering is applied.

- keep_empty:

  logical. Whether to include empty intervals in the output (default is
  TRUE).

- use_arrow:

  logical. Whether to use Arrow for processing predictions (default is
  FALSE).

## Value

A data frame with the following columns:

- start:

  Start time of the prediction interval.

- end:

  End time of the prediction interval.

- scientific_name:

  Scientific name of the predicted species.

- common_name:

  Common name of the predicted species.

- confidence:

  BirdNET’s confidence score for the prediction.

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
  around intermediate values). For additional details on BirdNET
  confidence scores and guidelines for converting them to probabilities,
  see Wood & Kahl (2024).

### Apache Arrow optimization

By default, predictions from Python are converted to R using basic data
structures. For large datasets using Apache Arrow (`use_arrow=TRUE`) can
significantly improve performance by reducing memory usage during data
conversion and minimizing data copying between R and Python.

When to use Apache Arrow:

- Large audio files (\>20 minutes)

- Low confidence thresholds (`min_confidence < 0.1`)

- Memory-constrained environments

- Whenever you encounter an unusual long pause after inference. This is
  a sign that the data conversion is taking a long time.

Note that using Apache Arrow requires additional dependencies (`arrow` R
package and `pyarrow` Python package). You can install them manually
using
[`install_arrow()`](https://birdnet-team.github.io/birdnetR/reference/install_arrow.md).

## References

Wood, C. M., & Kahl, S. (2024). Guidelines for appropriate use of
BirdNET scores and other detector outputs. Journal of Ornithology.
https://doi.org/10.1007/s10336-024-02144-5

## See also

[`read_labels()`](https://birdnet-team.github.io/birdnetR/reference/read_labels.md)
for more details on species filtering.

[`birdnet_model_tflite()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md),
[`birdnet_model_protobuf()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md),
[`birdnet_model_custom()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
predictions <- predict_species_from_audio_file(model, audio_file, min_confidence = 0.1)
} # }
```
