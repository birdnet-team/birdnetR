# birdnetR

> **Note:** This README describes the development version, birdnetR 1.0.
> It is a breaking release and not on CRAN yet: all functions have new
> `birdnet_<verb>` names, and BirdNET+ V3.0 is the default model. CRAN
> still has 0.3.2, which is documented at
> <https://birdnet-team.github.io/birdnetR/>. If you are upgrading from
> 0.x, see [Upgrading from birdnetR 0.x](#upgrading-from-birdnetr-0x)
> below.

`birdnetR` brings [BirdNET](https://birdnet.cornell.edu/) to R. BirdNET
is a deep learning model that identifies birds and many other animals by
their sounds. birdnetR helps you analyze audio from bioacoustic
projects, from a few recordings to large datasets, even without a
background in computer science.

`birdnetR` wraps the `birdnet` [Python
package](https://github.com/birdnet-team/birdnet) and sets up Python for
you. With it you can:

- identify species in audio files with BirdNET+ V3.0 (the default),
  BirdNET V2.4 or Google’s Perch v2,
- predict which species occur at a location and week of the year (geo
  models),
- extract embeddings (one feature vector per audio segment) for your own
  analyses,
- run custom classifiers trained with
  [BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer).

## Installation

Install the development version (1.0) from GitHub:

``` r

pak::pak("birdnet-team/birdnetR")
```

The released version on CRAN is still 0.3.2, with the old function
names:

``` r

install.packages("birdnetR")
```

You don’t need to install Python yourself. On first use, birdnetR sets
up Python and the `birdnet` package for you (through
[reticulate](https://rstudio.github.io/reticulate/)). The first setup
takes a few minutes. The default installation is small. TensorFlow
(about 600 MB) and PyTorch are downloaded only when you first load a
model that needs them.

[Installation and
setup](https://birdnet-team.github.io/birdnetR/dev/articles/installation.html)
covers these extra downloads, your own Python environment and working
offline. For GPUs, see the
[GPU](https://birdnet-team.github.io/birdnetR/dev/articles/gpu.html)
article.

## Example use

Identify species in an audio file:

``` r

library(birdnetR)

# Load the BirdNET+ V3.0 acoustic model (downloaded on first use)
model <- birdnet_load()

# Path to an audio file (replace with your own file path)
audio_path <- system.file("extdata", "soundscape.mp3", package = "birdnetR")

# Predict species in the audio file
predictions <- birdnet_predict(model, audio_path)

# Convert predictions to a data frame
df <- as.data.frame(predictions)
```

Each row of `df` is one detection: the file (`input`), the segment’s
`start_time` and `end_time` in seconds, the `species_name`
(`"<scientific name>_<common name>"`) and the `confidence` score.

Other models load the same way:

``` r

model_24 <- birdnet_load(version = "2.4")   # BirdNET V2.4
perch <- birdnet_load_perch()               # Google's Perch v2
geo <- birdnet_load(type = "geo")           # species expected at a place and week
```

## Working with prediction results

[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
returns a lightweight Python-backed object, not an R data frame. Use
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) when you
need the results in R. For large runs, it is faster to skip the
conversion and write the results to a file directly:

``` r

predictions <- birdnet_predict(model, audio_path)

# Faster for large runs; the data stays in Python:
birdnet_write(predictions, "results.parquet")

# Only when you need the results in R:
df <- as.data.frame(predictions)
```

## Models

| Model | Load with | Classes | License of the model files |
|----|----|----|----|
| BirdNET+ V3.0 acoustic (default) | [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md) | about 11,700 | Apache 2.0 |
| BirdNET+ V3.0 geo | `birdnet_load(type = "geo")` | about 14,000 | CC BY-NC-SA 4.0 |
| BirdNET V2.4 acoustic | `birdnet_load(version = "2.4")` | 6,522 | CC BY-NC-SA 4.0 |
| BirdNET V2.4 geo | `birdnet_load(type = "geo", version = "2.4")` | 6,522 | CC BY-NC-SA 4.0 |
| Perch v2 (Google) | [`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md) | 14,795 | CC BY-NC-SA 4.0 |

[`birdnet_list_models()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_models.md)
lists every backend and precision you can choose. The [Models and
backends](https://birdnet-team.github.io/birdnetR/dev/articles/models.html)
article explains them. For details on each model, see the [models page
of the Python
package](https://birdnet-team.github.io/birdnet/models.html).

## Upgrading from birdnetR 0.x

Version 1.0 is a breaking release. The table below maps removed
functions to their replacements:

| 0.3.2 | 1.0.0 |
|----|----|
| `birdnet_model_tflite()` | `birdnet_load(version = "2.4", backend = "tf")` |
| `birdnet_model_protobuf()` | `birdnet_load(version = "2.4", backend = "pb")` |
| `birdnet_model_meta()` | `birdnet_load(type = "geo", version = "2.4")` |
| `birdnet_model_custom()` | [`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md) |
| `predict_species_from_audio_file()` | `birdnet_predict(model, files = ...)` |
| `predict_species_at_location_and_time()` | `birdnet_predict(model, latitude = ..., longitude = ...)` |
| `labels_path()` / `read_labels()` | `birdnet_list_species(model)`; read your own list file with [`readLines()`](https://rdrr.io/r/base/readLines.html) |
| `available_languages()` | [`birdnet_list_languages()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_languages.md) |
| `get_top_prediction()` | Removed; use `dplyr` or birdnetTools |
| `install_arrow()` | Removed; not needed |

Predictions now come back as an object (convert with
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)), and the
output columns follow the Python package (`input`, `start_time`,
`end_time`, `species_name`, `confidence`). `NEWS.md` lists the renamed
arguments and all other changes.

## The BirdNET ecosystem

birdnetR is one step in the BirdNET tool chain:

1.  *(Optional)* Train a custom classifier with
    [BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer).
2.  Identify species in your recordings with birdnetR.
3.  Filter, visualize and validate the detections with
    [birdnetTools](https://birdnet-team.github.io/birdnetTools/index.html).

## Citation

Feel free to use `birdnetR` for your acoustic analyses and research. If
you do, please cite as:

``` bibtex
@article{kahl2021birdnet,
  title={BirdNET: A deep learning solution for avian diversity monitoring},
  author={Kahl, Stefan and Wood, Connor M and Eibl, Maximilian and Klinck, Holger},
  journal={Ecological Informatics},
  volume={61},
  pages={101236},
  year={2021},
  publisher={Elsevier}
}
```

## License

- **Source code**: The source code of this package is licensed under the
  [MIT License](https://opensource.org/licenses/MIT).
- **Models**: The BirdNET+ V3.0 acoustic model is licensed under the
  [Apache License
  2.0](https://github.com/birdnet-team/model-converter/blob/main/MODEL_LICENSE.md)
  and comes with an [acceptable use
  policy](https://github.com/birdnet-team/model-converter/blob/main/ACCEPTABLE_USE.md).
  The other models used in this package are licensed under the [Creative
  Commons Attribution-NonCommercial-ShareAlike 4.0 International License
  (CC BY-NC-SA
  4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/).

Please review and follow the license terms of each model; see the
[license section of the Python
package](https://github.com/birdnet-team/birdnet#license). Note that
educational and research purposes are considered non-commercial use
cases.

## Funding

Our work in the K. Lisa Yang Center for Conservation Bioacoustics is
made possible by the generosity of K. Lisa Yang to advance innovative
conservation technologies to inspire and inform the conservation of
wildlife and habitats.

The development of BirdNET is supported by the German Federal Ministry
of Research, Technology and Space (FKZ 01\|S22072), the German Federal
Ministry for the Environment, Climate Action, Nature Conservation and
Nuclear Safety (FKZ 67KI31040E), the German Federal Ministry of Economic
Affairs and Energy (FKZ 16KN095550), the Deutsche Bundesstiftung Umwelt
(project 39263/01) and the European Social Fund.

## Partners

BirdNET is a joint effort of partners from academia and industry.
Without these partnerships, this project would not have been possible.
Thank you!

![Our
partners](https://tuc.cloud/index.php/s/KSdWfX5CnSRpRgQ/download/box_logos.png)

Our partners
