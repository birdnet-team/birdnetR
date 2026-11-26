# List the available BirdNET models

Returns every model combination the installed `birdnet` Python package
can load: model type, version, backend, TFLite library and precision.
Use it to pick arguments for
[`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

## Usage

``` r
birdnet_list_models(compact = FALSE)
```

## Arguments

- compact:

  logical. If `TRUE`, precisions and libraries of otherwise identical
  rows are collapsed into one colon-separated string.

## Value

A data frame with columns `type`, `version`, `backend`, `library`,
`precision` and `needs`. `needs` tells what a model requires on top of
the default installation:

- `"base"`: nothing, it runs out of the box.

- `"tf"`: TensorFlow (`birdnet[tf]`), installed automatically on first
  use.

- `"pt"`: PyTorch (`birdnet[pt]`), installed automatically on first use.

- `"tf (2.18-2.19)"`: TensorFlow 2.18 or 2.19 (geo 3.0 on `tf`). The
  automatic install picks the newest TensorFlow, so this combination
  needs a Python environment you manage yourself.

The `perch_v2` row is loaded with
[`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md),
all other rows with
[`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

## Examples

``` r
if (FALSE) { # \dontrun{
birdnet_list_models()
birdnet_list_models(compact = TRUE)
} # }
```
