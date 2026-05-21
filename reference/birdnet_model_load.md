# Initialize a BirdNET Model

The various function of the `birdnet_model_*` family are used to create
and initialize diffent BirdNET models. Models will be downloaded if
necessary.

- `birdnet_model_tflite()`: creates a tflite-model used for species
  prediction from audio.

- `birdnet_model_custom()`: loads a custom model for species prediction
  from audio.

- `birdnet_model_protobuf()`: creates a protobuf model for species
  prediction from audio that can be run on the GPU (GPU support so far
  only implemented on Apple Silicon).

- `birdnet_model_meta()`: creates a meta model for species prediction
  from location and time.

## Usage

``` r
birdnet_model_tflite(
  version = "v2.4",
  language = "en_us",
  tflite_num_threads = NULL
)

birdnet_model_custom(
  version = "v2.4",
  classifier_folder,
  classifier_name,
  tflite_num_threads = NULL
)

birdnet_model_meta(
  version = "v2.4",
  language = "en_us",
  tflite_num_threads = NULL
)

birdnet_model_protobuf(
  version = "v2.4",
  language = "en_us",
  custom_device = NULL
)
```

## Arguments

- version:

  character. The version of BirdNET to use (default is "v2.4", no other
  versions are currently supported).

- language:

  character. Specifies the language code to use for the model's text
  processing. The language must be one of the available languages
  supported by the BirdNET model.

- tflite_num_threads:

  integer. The number of threads to use for TensorFlow Lite operations.
  If NULL (default), the default threading behavior will be used. Will
  be coerced to an integer if possible.

- classifier_folder:

  character. Path to the folder containing the custom classifier.

- classifier_name:

  character. Name of the custom classifier.

- custom_device:

  character. This parameter allows specifying a custom device on which
  computations should be performed. If `custom_device` is not specified
  (i.e., it has the default value None), the program will attempt to use
  a GPU (e.g., "/device:GPU:0") by default. If no GPU is available, it
  will fall back to using the CPU. By specifying a device string such as
  "/device:GPU:0" or "/device:CPU:0", the user can explicitly choose the
  device on which operations should be executed.

## Value

A BirdNET model object, which is an S3 object of class `birdnet_model`
and specific subclasses (e.g., `birdnet_model_tflite`,
`birdnet_model_v2_4`). This object is a list containing:

`py_model`

:   The underlying Python BirdNET model object.

`model_version`

:   The version string of the model (e.g., "v2.4").

...

:   Additional elements specific to the model type:

## Details

**Species Prediction from audio**

Models created from `birdnet_model_tflite()`, `birdnet_model_custom()`,
and `birdnet_model_protobuf()` can be used to predict species within an
audio file using
[`predict_species_from_audio_file()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_from_audio_file.md).  

**Species prediction from location and time**

The `birdnet_model_meta()` model can be used to predict species
occurrence at a specific location and time of the year using
[`predict_species_at_location_and_time()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_at_location_and_time.md).

## Note

Currently, all models can only be executed on the CPU. GPU support is
only available on Apple Silicon.

## See also

[`available_languages()`](https://birdnet-team.github.io/birdnetR/reference/available_languages.md)
[`predict_species_from_audio_file()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_from_audio_file.md)
[`predict_species_at_location_and_time()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_at_location_and_time.md)

## Examples

``` r
# Create a TFLite BirdNET model with 2 threads and English (US) language
if (FALSE) { # \dontrun{
birdnet_model <- birdnet_model_tflite(version = "v2.4", language = "en_us", tflite_num_threads = 2)
} # }
```
