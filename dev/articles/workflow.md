# The BirdNET ecosystem: a workflow overview

`birdnetR` is one of several BirdNET tools. This article shows how they
fit together and how to hand your results from birdnetR to birdnetTools.

## Overview

A typical R workflow looks like this:

1.  *(Optional)* Train a custom classifier in **BirdNET-Analyzer** and
    export it.
2.  Load a model in **birdnetR** with
    [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md),
    [`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
    or
    [`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).
3.  Run
    [`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
    on your audio files and save the results with
    [`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md).
4.  Read the results into **birdnetTools** for filtering, visualization,
    and validation.

For code examples, see the [Get started with
birdnetR](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.md)
article and the [birdnetTools
documentation](https://birdnet-team.github.io/birdnetTools/index.html).

## Stage 1: Custom training (optional) with BirdNET-Analyzer

[BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer) is
the upstream desktop and command-line application. For most users it is
**not required**: birdnetR downloads the pre-trained BirdNET models and
can run predictions out of the box.

Consider BirdNET-Analyzer when you need to:

- train a custom species classifier on your own recordings,
- use advanced configuration options not exposed in birdnetR,
- run batch analyses through a graphical interface.

Custom classifiers trained in BirdNET-Analyzer can be loaded in birdnetR
with
[`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md).

## Stage 2: Species detection with birdnetR

birdnetR wraps the `birdnet` Python package and exposes two model types
in R:

- **Acoustic models** detect species in audio files: BirdNET+ V3.0 (the
  default), BirdNET V2.4, Perch v2 and custom classifiers. Load them
  with
  [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md),
  [`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  or
  [`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md),
  run them with
  [`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md),
  and write the results with
  [`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md).
  [`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)
  returns embeddings instead of species.
- **Geo models** estimate which species to expect at a location and week
  of the year. Load them with `birdnet_load(type = "geo")` and run them
  with
  [`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md).

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) converts
any prediction object to a plain R data frame.

To process many files and save the results, see [Process many
files](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.html#process-many-files)
in Get started.

## Stage 3: Post-processing and validation with birdnetTools

[birdnetTools](https://birdnet-team.github.io/birdnetTools/index.html)
is a separate R package designed to work with tabular BirdNET output,
the kind produced by
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) or
[`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md)
in birdnetR.

It provides functions for:

- combining outputs from multiple files or recording sessions,
- filtering detections by species, confidence score, date, or time of
  day,
- visualizing temporal detection patterns as heatmaps,
- running an interactive Shiny app to review and label detections,
- calculating species-specific confidence thresholds to achieve a target
  precision.

birdnetTools does not call Python and has no dependency on birdnetR; it
works with any BirdNET-style data frame.

### Handing results to birdnetTools

birdnetR keeps the column names of the Python package: `input`,
`start_time`, `end_time`, `species_name` and `confidence`.

birdnetTools expects a `filepath` column and the species name split into
`scientific_name` and `common_name`. Add these columns before you pass
the data on. The species name is split at its first underscore:

``` r

df <- as.data.frame(predictions)

df$filepath <- df$input
df$scientific_name <- sub("_.*", "", df$species_name)
df$common_name <- sub("^[^_]*_", "", df$species_name)
```

Perch v2 names are scientific names only, so for Perch output both new
columns hold the scientific name.

For results written to CSV files with
[`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md),
don’t use `birdnetTools::birdnet_combine()` to read them back. The times
in CSV files are text such as `"00:00:01.50"` (see [Process many
files](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.html#process-many-files)),
and `birdnet_combine()` reads them as clock times without the
hundredths, so 1.5 seconds becomes 1. Read the files with
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) and convert the
times to seconds, then add the columns as above:

``` r

files <- list.files("results", pattern = "\\.csv$", full.names = TRUE)
df <- do.call(rbind, lapply(files, read.csv))

df$start_time <- as.numeric(as.difftime(df$start_time, format = "%H:%M:%OS", units = "secs"))
df$end_time <- as.numeric(as.difftime(df$end_time, format = "%H:%M:%OS", units = "secs"))
```

Reading birdnetR output directly in birdnetTools is discussed in
[birdnetTools issue
\#34](https://github.com/birdnet-team/birdnetTools/issues/34).
