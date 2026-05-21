# Get started with birdnetR

``` r

library(birdnetR)
```

The `birdnetR` package provides a comprehensive interface for utilizing
the `birdnet` Python package within R. This guide will walk you through
the basic steps of setting up the package, initializing models, and
using various functions to analyze audio files for (bird) species
identification.

## Installation

Install the released version from CRAN:

``` r

install.packages("birdnetR")
```

  
or install the development version from GitHub with:

``` r

pak::pak("birdnet-team/birdnetR")
```

  

**Note**  
`birdnetR` uses
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html)
to handle Python dependencies. These dependencies are installed only
when needed, which might result in a longer initial setup.

## Usage

### Load a BirdNET model

To begin using BirdNET, a model must first be loaded. During this step,
the required model is downloaded if necessary, loaded into memory, and
prepared for making predictions.

Several model variations are available, including different backends and
precisions. Use
[`supported_model_configurations()`](https://birdnet-team.github.io/birdnetR/dev/reference/supported_model_configurations.md)
to see all valid combinations.

You can also load a custom model if one is available. For information on
training custom models, please refer to the BirdNET-Analyzer repository.

``` r

# Load a pre-trained acoustic model (default: TensorFlow backend, fp32 precision)
model <- load_birdnet()

# Load a model with specific options
model <- load_birdnet(type = "acoustic", version = "2.4", backend = "tf", precision = "int8")

# See all supported model configurations
supported_model_configurations()
```

To load a custom model, provide the path to the model file and the
species list file.

``` r

model_path <- "/path/to/custom/model.tflite"
species_list_path <- "/path/to/custom/species_list.txt"

custom_model <- load_custom(model = model_path, species_list = species_list_path)
```

### Identify species in an audio file

With BirdNET, you can identify bird species present in an audio file.
The function returns a prediction object that can be converted to a data
frame. Each row in the resulting data frame represents a single
prediction for a specific 3-second interval.

``` r

library(birdnetR)

# Load the BirdNET acoustic model
model <- load_birdnet()

# Path to an example audio file (replace with your own file path)
audio_path <- system.file("extdata", "soundscape.mp3", package = "birdnetR")

# Predict species in the audio file
predictions <- predict(model, audio_path, min_confidence = 0.3)

# Convert to a data frame
df <- as.data.frame(predictions)

# Example output:
#   input                   start_time end_time                   species_name confidence
#   soundscape.mp3                   0        3 Poecile atricapillus_...       0.8140557
#   soundscape.mp3                   3        6 Poecile atricapillus_...       0.3082857
#   soundscape.mp3                   9       12 Haemorhous mexicanus_...       0.6393781
# ...
```

If there are multiple predictions above the confidence threshold for the
same time interval, you will see multiple rows for that interval.

### Using a custom species list

In many cases, you may not need to identify all 6,000+ species available
in the model. To focus on species relevant to your project, you can use
a custom species list containing only the necessary class labels.
Providing a custom species list will limit the output to that set of
species.

Class labels follow a specific format, consisting of the scientific name
and the common name, separated by an underscore, like this:

``` r

"Accipiter cooperii_Cooper's Hawk"
"Agelaius phoeniceus_Red-winged Blackbird"
```

You can retrieve the full species list from a loaded model using
[`get_species_list()`](https://birdnet-team.github.io/birdnetR/dev/reference/get_species_list.md):

``` r

# Get the full species list from the model
species <- get_species_list(model)
head(species)
```

To filter predictions to specific species, pass a character vector to
the `species_list` argument:

``` r

predictions <- predict(model, audio_path,
  species_list = c("Cyanocitta cristata_Blue Jay", "Junco hyemalis_Dark-eyed Junco"),
  min_confidence = 0.3
)

as.data.frame(predictions)
```

### Processing multiple files

When processing many audio files, it is more efficient to keep
predictions in Python and write them to disk without converting to R
data frames. A practical pattern is to loop over meaningful chunks
(e.g. one folder or one recording day) and write one output file per
chunk:

``` r

model <- load_birdnet()

# Folders of audio recordings, e.g. one folder per site
audio_folders <- list.dirs("recordings", recursive = FALSE)

for (folder in audio_folders) {
  files <- list.files(folder, pattern = "\\.wav$", full.names = TRUE)
  predictions <- predict(model, files)

  out_file <- file.path("results", paste0(basename(folder), ".parquet"))
  write_predictions(predictions, out_file)
}
```

This keeps memory usage constant regardless of total dataset size
because each iteration discards the previous prediction object before
creating the next one.

[`write_predictions()`](https://birdnet-team.github.io/birdnetR/dev/reference/write_predictions.md)
supports CSV, Parquet, and NPZ formats. Choose based on your downstream
workflow:

| Format | Best for | Notes |
|----|----|----|
| CSV | Interoperability, quick inspection | Human-readable; largest file size |
| Parquet | Efficient storage and analysis in R/Python | Columnar; much smaller than CSV |
| NPZ | NumPy-based pipelines | Compact; requires Python to read |

**Note:** Parquet is not supported for geo predictions — use CSV or NPZ
instead.

### Reading Parquet files in R

`write_predictions(predictions, "results.parquet")` writes Parquet files
directly from Python and does not require the `arrow` R package.

If you want to **read** Parquet files back into R (e.g. with
[`arrow::read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.html)),
you need the `arrow` package installed:

``` r

install.packages("arrow")
```

On Linux this may require compilation and can take several minutes.

### Predict species occurrence with the geo model

BirdNET includes a geographic model that predicts the likelihood of bird
species occurrence at a specific location and time of year. This
function returns a prediction object that can be converted to a data
frame containing species labels and corresponding confidence values.

``` r

# Load the geo model
geo_model <- load_birdnet(type = "geo")

# Predict species occurrence in Ithaca, NY in week 4 of the year
predictions <- predict(geo_model, latitude = 42.5, longitude = -76.45, week = 4L)

# Convert to data frame
as.data.frame(predictions)

# Example output:
#   species_name                                confidence
#   Cyanocitta cristata_Blue Jay                0.92886776
#   Poecile atricapillus_Black-capped Chickadee 0.90332001
#   Sitta carolinensis_White-breasted Nuthatch  0.83232993
#   ...
```

### Translating common species names

The birdnetR package allows you to translate common bird species names
into several different languages. To check which languages are
supported, you can use the following command:

``` r

supported_languages()
```

To output the common names in your preferred language, load the model
with the `language` parameter:

``` r

model_fr <- load_birdnet(language = "fr")

# Get species list in French
head(get_species_list(model_fr))
```

## Next steps

Once you have predictions, you may want to filter, visualise, or
validate them. The
[birdnetTools](https://birdnet-team.github.io/birdnetTools/index.html)
package provides functions for these tasks — filtering detections by
species, confidence, or date range; creating heatmaps; and running
interactive validation workflows to set species-specific confidence
thresholds.

For a high-level overview of how BirdNET-Analyzer, birdnetR, and
birdnetTools fit together, see the [BirdNET ecosystem
workflow](https://birdnet-team.github.io/birdnetR/dev/articles/workflow.md)
article.
