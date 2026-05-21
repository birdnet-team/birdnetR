# Read species labels from a file

This is a convenience function to read species labels from a file.

## Usage

``` r
read_labels(species_file)
```

## Arguments

- species_file:

  Path to species file.

## Value

A vector with class labels e.g. c("Cyanocitta cristata_Blue Jay",
"Zenaida macroura_Mourning Dove")

## See also

[`available_languages()`](https://birdnet-team.github.io/birdnetR/reference/available_languages.md)
[`labels_path()`](https://birdnet-team.github.io/birdnetR/reference/labels_path.md)

## Examples

``` r
if (FALSE) { # interactive()
# Read a custom species file
read_labels(system.file("extdata", "species_list.txt", package = "birdnetR"))

# To access all class labels that are supported in your language,
# you can read in the respective label file
if (FALSE) { # \dontrun{
model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
labels_path <- labels_path(model, "fr")
species_list <- read_labels(labels_path)
head(species_list)
} # }
}
```
