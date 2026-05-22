# Convert BirdNET encoding results to a data frame

Convert encoding results from an acoustic model to a data frame. Each
row represents one audio segment. The `embedding` column is returned as
a list of numeric vectors (one per segment).

## Usage

``` r
# S3 method for class 'birdnet_encoding'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A BirdNET encoding object (as returned by
  [`encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/encode.md)).

- row.names:

  `NULL` or a character vector giving the row names for the data frame.
  Not used.

- optional:

  logical. Not used.

- ...:

  Additional arguments (ignored).

## Value

A data frame containing the encoding results. Columns include `input`,
`start_time`, `end_time`, and `embedding` (a list column of numeric
vectors).

## Examples

``` r
if (FALSE) { # \dontrun{
model <- load_birdnet(type = "acoustic")
audio_file <- system.file("extdata", "soundscape.mp3",
  package = "birdnetR"
)
enc <- encode(model, files = audio_file)
df <- as.data.frame(enc)
# Access the first embedding vector
df$embedding[[1]]
} # }
```
