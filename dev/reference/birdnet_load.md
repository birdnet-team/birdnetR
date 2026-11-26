# Load a BirdNET Model

Load BirdNET models for sound identification or for species prediction
from location and time. Models are downloaded on first use.

- `birdnet_load()`: an official BirdNET model (acoustic or geographic).

- `birdnet_load_perch()`: the Perch v2 acoustic model.

- `birdnet_load_custom()`: a custom classifier trained with
  BirdNET-Analyzer.

- `birdnet_inspect_custom()`: describe a custom TFLite classifier
  without loading it.

Every successful load prints one line naming the loaded model; silence
it with [`suppressMessages()`](https://rdrr.io/r/base/message.html).

## Usage

``` r
birdnet_load(
  type = "acoustic",
  version = "3.0",
  backend = NULL,
  library = NULL,
  precision = "fp32",
  language = "en_us"
)

birdnet_load_perch(device = "CPU")

birdnet_load_custom(
  model,
  species_list,
  type = "acoustic",
  version = "auto",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  check_validity = TRUE,
  is_raven = NULL
)

birdnet_inspect_custom(model, library = NULL)
```

## Arguments

- type:

  character. `"acoustic"` or `"geo"`.

- version:

  character. Model version, `"3.0"` or `"2.4"`. For custom classifiers
  `"auto"` reads it from the file (TFLite only).

- backend:

  character or `NULL`. `"onnx"`, `"tf"`, `"pt"` or `"pb"`.

- library:

  character or `NULL`. `"litert"` or `"tflite"`. Only applies to
  `backend = "tf"`.

- precision:

  character. `"fp32"`, `"fp16"` or `"int8"`.

- language:

  character. Language of the common species names, e.g. `"en_us"`. See
  [`birdnet_list_languages()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_languages.md).

- device:

  character. `"CPU"` (default) or `"GPU"` (see
  [`birdnet_use_gpu()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_use_gpu.md)).

- model:

  character. Path to the custom classifier: a `.tflite` file for
  `backend = "tf"`, a directory for `backend = "pb"`.

- species_list:

  character. Path to the label file of the custom classifier.

- check_validity:

  logical. Check that the model can be loaded before using it.

- is_raven:

  logical or `NULL`. Only for `backend = "pb"`: is the classifier a
  Raven export? `NULL` (default) uses the default of the `birdnet`
  Python package: `TRUE` for a 2.4 classifier, `FALSE` for a 3.0 one.
  Set `FALSE` for a 2.4 classifier that is not a Raven export.

## Value

A BirdNET model object (S3 class `birdnet_model` with type-, backend-
and version-specific subclasses). Use it with
[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md),
[`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)
(acoustic models) and
[`birdnet_list_species()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_species.md).
Internal list fields are implementation details and should not be relied
upon.

`birdnet_inspect_custom()` returns a named list describing a custom
TFLite classifier: `version` (base model, `"2.4"` or `"3.0"`), `mode`
(`"replace"` or `"append"`), `n_species`, `applies_sigmoid`,
`supports_encoding` and `input_samples` (`NULL` if any input length is
accepted).

## Details

`type`:

- `"acoustic"`: identify species in audio recordings.

- `"geo"`: predict which species occur at a location and week of the
  year.

`version`: `"3.0"` (BirdNET+ V3.0, the default) or `"2.4"`.

`backend`:

- `"onnx"`: ONNX Runtime (3.0 only). Part of the default installation;
  the default for 3.0.

- `"tf"`: TensorFlow Lite (TFLite) model, CPU only. The default for 2.4.

- `"pt"`: PyTorch (3.0 only), CPU or GPU. Installs `birdnet[pt]` on
  first use.

- `"pb"`: TensorFlow SavedModel (Protobuf), CPU or GPU. Installs
  `birdnet[tf]` on first use.

If `backend` is `NULL`, it follows the version: `"onnx"` for 3.0 and
`"tf"` for 2.4.

`library` only applies to `backend = "tf"`:

- `"litert"`: the LiteRT interpreter, part of the default installation
  on the platforms listed below.

- `"tflite"`: TensorFlow's own interpreter. Installs `birdnet[tf]` on
  first use.

If `library` is `NULL`, LiteRT is used where it is available (Linux,
macOS on Apple silicon, Windows on x86-64), otherwise `"tflite"`. The
geo 3.0 model always uses `"tflite"`.

`precision`: `"fp32"`, `"fp16"` or `"int8"`; not every model supports
every precision.

Heavy runtimes (TensorFlow for `"pb"`, `"tflite"` and Perch; PyTorch for
`"pt"`) are not part of the default installation. They are added
automatically the first time a model needs them, which can take a while.

The Perch v2 model is not supported on Intel Macs.

Use
[`birdnet_list_models()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_models.md)
for all valid combinations and which ones need an extra download.

## Examples

``` r
if (FALSE) { # \dontrun{
# BirdNET+ V3.0 acoustic model (default)
model <- birdnet_load()

# BirdNET V2.4 and the V3.0 geo model
model_24 <- birdnet_load(version = "2.4")
geo <- birdnet_load(type = "geo")

# Perch v2
perch <- birdnet_load_perch()

# A custom classifier trained with BirdNET-Analyzer: describe it, then load it
birdnet_inspect_custom("path/to/CustomClassifier.tflite")
custom <- birdnet_load_custom(
  model = "path/to/CustomClassifier.tflite",
  species_list = "path/to/CustomClassifier_Labels.txt"
)
} # }
```
