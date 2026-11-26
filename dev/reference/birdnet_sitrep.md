# Report the Python environment

Summarizes the Python environment birdnetR runs on: the Python version
and path, the installed `birdnet` Python package version, and which
inference runtimes are installed. Useful for debugging environment
issues.

## Usage

``` r
birdnet_sitrep()

# S3 method for class 'birdnet_sitrep'
print(x, ...)
```

## Arguments

- x:

  A `birdnet_sitrep` object, as returned by `birdnet_sitrep()`.

- ...:

  Ignored.

## Value

`birdnet_sitrep()` returns a list of class `birdnet_sitrep` with
elements:

- python_version:

  Character string with the Python version (e.g. `"3.12.3"`), or `NA` if
  Python is not available.

- python_executable:

  Character string with the path to the Python executable, or `NA` if
  Python is not available.

- birdnet_version:

  Character string with the installed `birdnet` package version (e.g.
  `"1.5.0"`), or `NA` if the package is not installed.

- runtimes:

  Named logical vector, `TRUE` for each of `onnxruntime`,
  `ai_edge_litert`, `tensorflow` and `torch` that is installed (found by
  importlib, without importing it), `NA` if this could not be
  determined.

[`print()`](https://rdrr.io/r/base/print.html) returns `x`, invisibly.

## Details

The character fields and `runtimes` are `NA` (with a warning) when they
cannot be determined.

## Examples

``` r
if (FALSE) { # \dontrun{
birdnet_sitrep()
} # }
```
