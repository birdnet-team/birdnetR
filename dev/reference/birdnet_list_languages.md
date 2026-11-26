# List the languages of a BirdNET model version

Common species names are available in these languages. Pass one of them
as `language` to
[`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

## Usage

``` r
birdnet_list_languages(version = "3.0")
```

## Arguments

- version:

  character. `"3.0"` (default) or `"2.4"`. The two versions support
  different languages.

## Value

Character vector of language codes (e.g. `"en_us"`, `"de"`).

## Examples

``` r
if (FALSE) { # \dontrun{
birdnet_list_languages()
birdnet_list_languages("2.4")
} # }
```
