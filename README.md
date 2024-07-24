# BirdNET-R
This is a wrapper for the `birdnet` Python package for automated bird sound ID.

## License

This package is licensed under the MIT License. See the LICENSE file for details.

## Citation

```bibtex
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

## Setup

First, install the `reticulate` package if you haven't already:

```r
install.packages("reticulate")
```

For now, you have to install the package from GitHub. 

To install the package directly from GitHub, you need to have the devtools package installed. If you don't have devtools installed, you can install it using:

```r
install.packages("devtools")
```

Then, you can install BirdNET-R from GitHub:

```r
devtools::install_github("birdnet-team/BirdNET-R")
```

After that, create and configure a Python virtual environment:

```r
library(reticulate)
reticulate::virtualenv_create("r-reticulate")
reticulate::virtualenv_install("r-reticulate", packages = "birdnet")
reticulate::use_virtualenv("r-reticulate", required = TRUE)
```

## Example use

Here's a simple example of how to use this package to predict bird species from an audio file:

```r
# Load the package
library(BirdNET)

# Initialize the BirdNET model
model <- init_model()

# Path to the audio file (replace with your own file path)
audio_path <- "path/to/your/soundscape.wav"

# Predict species within the audio file
predictions <- predict_species(model, audio_path)

# Get the most probable prediction within the time interval 0s-3s
top_prediction <- get_top_prediction(predictions, 0.0, 3.0)

# Print the top prediction and its confidence
print(paste("Predicted:", top_prediction$prediction))
print(paste("Confidence:", top_prediction$confidence))
```

## Dev setup

Setup dev environment:

```
install.packages("reticulate")

library(reticulate)
reticulate::virtualenv_create("r-reticulate")
reticulate::virtualenv_install("r-reticulate", packages = "birdnet")
reticulate::use_virtualenv("r-reticulate", required = TRUE)
```

Create the docs:

```
usethis::use_roxygen_md()
devtools::document()
```

Run some tests:

```
devtools::build()
devtools::check()
```

## Funding

This project is supported by Jake Holshuh (Cornell class of '69) and The Arthur Vining Davis Foundations. Our work in the K. Lisa Yang Center for Conservation Bioacoustics is made possible by the generosity of K. Lisa Yang to advance innovative conservation technologies to inspire and inform the conservation of wildlife and habitats.

The German Federal Ministry of Education and Research is funding the development of BirdNET through the project "BirdNET+" (FKZ 01|S22072).
Additionally, the German Federal Ministry of Environment, Nature Conservation and Nuclear Safety is funding the development of BirdNET through the project "DeepBirdDetect" (FKZ 67KI31040E).

## Partners

BirdNET is a joint effort of partners from academia and industry.
Without these partnerships, this project would not have been possible.
Thank you!

![Our partners](https://tuc.cloud/index.php/s/KSdWfX5CnSRpRgQ/download/box_logos.png)
