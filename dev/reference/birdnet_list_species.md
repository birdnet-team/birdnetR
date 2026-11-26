# List the species of a loaded model

Returns all classes a loaded model can predict, in model order. Works
for official, Perch and custom models. Use entries of this list for the
`species_list` argument of
[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md).

## Usage

``` r
birdnet_list_species(model)
```

## Arguments

- model:

  A BirdNET model object, see
  [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

## Value

A character vector of species names (`"<scientific>_<common>"` for
BirdNET models).

## Examples

``` r
if (FALSE) { # \dontrun{
model <- birdnet_load()
species <- birdnet_list_species(model)
head(species)
} # }
```
