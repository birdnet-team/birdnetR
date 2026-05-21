# Report Python and birdnet Version Information

Returns the Python executable path, Python version, and installed
`birdnet` Python package version as a named list. Useful for debugging
environment issues.

## Usage

``` r
birdnet_version()
```

## Value

A named list with elements:

- python_version:

  Character string with the Python version (e.g. `"3.12.3"`), or `NA` if
  Python is not available.

- python_executable:

  Character string with the path to the Python executable, or `NA` if
  Python is not available.

- birdnet_version:

  Character string with the installed `birdnet` package version (e.g.
  `"0.2.16"`), or `NA` if the package is not installed.

## Examples

``` r
if (FALSE) { # \dontrun{
birdnet_version()
} # }
```
