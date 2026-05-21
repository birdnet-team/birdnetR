# Get Path to a Labels File

This function retrieves the file path to the BirdNET labels file on your
system corresponding to a specified language. This file contains all
class labels supported by the BirdNET model.

For a custom model, the path of the custom labels file is returned.

## Usage

``` r
labels_path(model, ...)

# S3 method for class 'birdnet_model_custom'
labels_path(model, ...)

# S3 method for class 'birdnet_model_tflite'
labels_path(model, language, ...)

# S3 method for class 'birdnet_model_protobuf'
labels_path(model, language, ...)
```

## Arguments

- model:

  A BirdNET model object.

- ...:

  Additional arguments passed to the method dispatch function.

- language:

  character. Specifies the language code for which the labels path is
  returned. The language must be one of the available languages
  supported by the BirdNET model.

## Value

A character string representing the file path to the labels file for the
specified language.

## Note

The `language` parameter must be one of the available languages returned
by
[`available_languages()`](https://birdnet-team.github.io/birdnetR/reference/available_languages.md).

## See also

[`available_languages()`](https://birdnet-team.github.io/birdnetR/reference/available_languages.md)
[`read_labels()`](https://birdnet-team.github.io/birdnetR/reference/read_labels.md)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_model_tflite(version = "v2.4")
labels_path(model, "fr")
} # }
```
