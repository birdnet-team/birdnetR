# Load a BirdNET Model

Functions to load BirdNET models for sound identification or species
prediction from location and time. Models will be downloaded if not
available locally.

- `load_birdnet()`: load a pre-trained BirdNET model or a geographic
  model.

- `load_perch()`: load the Perch v2 acoustic model.

- `load_custom()`: load a custom trained BirdNET model.

## Usage

``` r
load_perch()

load_birdnet(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  language = "en_us"
)

load_custom(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  model = NULL,
  species_list = NULL,
  check_validity = TRUE,
  classifier_type = NULL,
  is_raven = NULL
)
```

## Arguments

- type:

  character. The type of model to load: `"acoustic"` or `"geo"`.

- version:

  character. The version of the model to load, e.g., `"2.4"`.

- backend:

  character. The backend to use: `"tf"` (TensorFlow) or `"pb"`
  (Protobuf).

- library:

  character or `NULL`. The TensorFlow library to use: `"litert"` or
  `"tflite"`. Only applies when `backend = "tf"`.

- precision:

  character. The precision of the model: `"int8"`, `"fp16"`, or
  `"fp32"`.

- language:

  character. Language code for the model to use e.g., "en_us". Common
  species names are returned in the specified language if available. Use
  [`supported_languages()`](https://birdnet-team.github.io/birdnetR/dev/reference/supported_languages.md)
  to see all available languages.

- model:

  If backend is "tf", path to custom model file. If backend is "pb",
  path to model directory.

- species_list:

  Path to the species list file.

- check_validity:

  Checks if the model is loadable by loading the model twice.

- classifier_type:

  Advanced option for custom TensorFlow models. Controls how the custom
  classifier head is interpreted.

- is_raven:

  Advanced option for custom protobuf models. Indicates whether the
  model uses the Raven protobuf layout.

## Value

A BirdNET model object (S3 class `birdnet_model` with type- and
version-specific subclasses). The returned object supports:

- [`predict()`](https://rdrr.io/r/stats/predict.html) — run inference on
  audio files or geographic coordinates

- [`get_species_list()`](https://birdnet-team.github.io/birdnetR/dev/reference/get_species_list.md)
  — retrieve the species list used by the model

Internal list fields are implementation details and should not be relied
upon.

## Details

The argument `type` specifies the type of model to load:

- `"acoustic"`: A model for species identification from audio
  recordings.

- `"geo"`: A model for species prediction based on geographic location
  and time.

The argument `version` specifies the version of the model to load, e.g.,
`"2.4"`. Use
[`supported_model_configurations()`](https://birdnet-team.github.io/birdnetR/dev/reference/supported_model_configurations.md)
to see all supported versions.

The argument `backend` specifies the backend to use:

- `"tf"`: TensorFlow backend, which supports different precisions and
  libraries but is CPU only.

- `"pb"`: Protobuf backend, which can be run on a GPU. GPU support
  requires additional system dependencies; see the upstream `birdnet`
  documentation for details.

The argument `library` is only used for the TensorFlow backend and
specifies the library to use:

- `"litert"`: The LiteRT library for running TensorFlow Lite models.

- `"tflite"`: The standard TensorFlow Lite library.

The argument `precision` specifies the precision of the model:

- `"int8"`: 8-bit integer precision, which is the most efficient in
  terms of speed and memory usage.

- `"fp16"`: 16-bit floating point precision, which is a good balance
  between speed and accuracy.

- `"fp32"`: 32-bit floating point precision, which is the most accurate
  but also the slowest and most memory-intensive. Protobuf and
  geographic models only support `"fp32"` precision.

To get an overview of all valid model configuration combinations use
[`supported_model_configurations()`](https://birdnet-team.github.io/birdnetR/dev/reference/supported_model_configurations.md).

## Examples

``` r
# Load a pre-trained acoustic model
if (FALSE) { # \dontrun{
model  <- load_birdnet(type = "acoustic", version = "2.4", backend = "tf", precision = "int8")
} # }
```
