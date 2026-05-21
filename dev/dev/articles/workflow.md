# The BirdNET ecosystem: a workflow overview

`birdnetR` sits within an ecosystem of tools that cover the full arc
from optional custom training through species detection to
post-processing and validation. This article gives a high-level map of
that ecosystem so you can find the right tool for each stage of your
analysis.

## Stage 1 — Custom training (optional): BirdNET-Analyzer

[BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer) is
the upstream desktop and command-line application. For most users it is
**not required**: birdnetR ships with the pre-trained BirdNET acoustic
model and can run predictions out of the box.

Consider BirdNET-Analyzer when you need to:

- train a custom species classifier on your own recordings,
- use advanced configuration options not yet exposed in birdnetR,
- run batch analyses through a graphical interface.

Custom classifiers trained in BirdNET-Analyzer can be loaded in birdnetR
with
[`load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).

## Stage 2 — Species detection: birdnetR

birdnetR wraps the `birdnet` Python package and exposes the two main
model types in R:

- **Acoustic model** — detects species from audio files. Load with
  [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md),
  run with [`predict()`](https://rdrr.io/r/stats/predict.html), and
  write results with
  [`write_predictions()`](https://birdnet-team.github.io/birdnetR/dev/reference/write_predictions.md).
- **Geo model** — estimates expected species for a location and time of
  year. Load with `load_birdnet(type = "geo")` and run with
  [`predict()`](https://rdrr.io/r/stats/predict.html).

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) converts
any prediction object to a plain R data frame for downstream use.

Acoustic predictions can be saved as CSV, Parquet, or NPZ. Parquet is
efficient for large datasets and is the recommended format for acoustic
results when continuing the workflow in R. Geo predictions support CSV
or NPZ only.

## Stage 3 — Post-processing and validation: birdnetTools

[birdnetTools](https://birdnet-team.github.io/birdnetTools/index.html)
is a separate R package designed to work with tabular BirdNET output —
the kind produced by
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) or
[`write_predictions()`](https://birdnet-team.github.io/birdnetR/dev/reference/write_predictions.md)
in birdnetR.

It provides functions for:

- combining outputs from multiple files or recording sessions,
- filtering detections by species, confidence score, date, or time of
  day,
- visualising temporal detection patterns as heatmaps,
- running an interactive Shiny app to review and label detections,
- calculating species-specific confidence thresholds to achieve a target
  precision.

birdnetTools does not call Python and has no dependency on birdnetR; it
works with any BirdNET-style data frame.

## Putting it together

A typical R workflow looks like this:

1.  *(Optional)* Train a custom classifier in **BirdNET-Analyzer** and
    export it as a model package.
2.  Load the model in **birdnetR** with
    [`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md)
    or
    [`load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md).
3.  Run [`predict()`](https://rdrr.io/r/stats/predict.html) on your
    audio files and save results with
    [`write_predictions()`](https://birdnet-team.github.io/birdnetR/dev/reference/write_predictions.md).
4.  Read the results into **birdnetTools** for filtering, visualisation,
    and validation.

For code examples, see the [Get started with
birdnetR](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.md)
vignette and the [birdnetTools
documentation](https://birdnet-team.github.io/birdnetTools/index.html).
