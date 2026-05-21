# List supported BirdNET model languages

Returns a character vector of supported language codes for BirdNET
models, as provided by the Python backend.

## Usage

``` r
supported_languages()
```

## Value

Character vector of supported language codes (e.g., `"en_us"`, `"de"`,
`"es"`).

## Examples

``` r
supported_languages()
#> Downloading uv...
#> Done!
#>  [1] "af"    "ar"    "cs"    "da"    "de"    "en_uk" "en_us" "es"    "fi"   
#> [10] "fr"    "hu"    "it"    "ja"    "ko"    "nl"    "no"    "pl"    "pt"   
#> [19] "ro"    "ru"    "sk"    "sl"    "sv"    "th"    "tr"    "uk"    "zh"   
#> [28] "latin"
```
