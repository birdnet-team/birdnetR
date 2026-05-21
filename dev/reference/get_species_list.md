# Get the species list from a loaded BirdNET model

Returns the full species list from a loaded model as a character vector.
Works for both pretrained and custom models.

## Usage

``` r
get_species_list(model)
```

## Arguments

- model:

  A BirdNET model object returned by
  [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md)
  or
  [`load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).

## Value

A character vector of species names in model order.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- load_birdnet(type = "acoustic")
species <- get_species_list(model)
head(species)
} # }
```
