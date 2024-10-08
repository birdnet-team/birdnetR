# birdnetR <a href="https://birdnet-team.github.io/birdnetR/"><img src="man/figures/logo.png" align="right" height="139" alt="birdnetR website" /></a>

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/birdnet-team/birdnetR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/birdnet-team/birdnetR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This is a wrapper for the `birdnet` Python package for automated bird sound ID available [here](https://github.com/birdnet-team/birdnet).


birdnetR is geared towards providing a robust workflow for ecological data analysis in bioacoustic projects. While it covers essential functionalities, it doesn't include all the features found in BirdNET-Analyzer, which is available [here](https://github.com/kahst/BirdNET-Analyzer). Some features might only be available in the BirdNET Analyzer and not in this package.

Please note that birdnetR is under active development, so you might encounter changes that could affect your current workflow. We recommend checking for updates regularly.

For more information, please visit the [birdnetR website](https://birdnet-team.github.io/birdnetR/).


## Citation

Feel free to use birdnetR for your acoustic analyses and research. If you do, please cite as:

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
## License

- **Source Code**: The source code for this project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
- **Models**: The models used in this project are licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/).

Please ensure you review and adhere to the specific license terms provided with each model. Note that educational and research purposes are considered non-commercial use cases.


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

Then, you can install birdnetR from GitHub:

```r
devtools::install_github("birdnet-team/birdnetR")
```

Next, install `birdnet`, which will set up a Python virtual environment named `r-birdnet` by default. You can configure this with the envname parameter. Do this only once during the initial setup or if you encounter issues with the environment.
```r
library(birdnetR)
install_birdnet()

```

## Example use

Here's a simple example of how to use this package to predict bird species from an audio file:

```r
# Load the package
library(birdnetR)

# Initialize a BirdNET model
model <- birdnet_model_tflite()

# Path to the audio file (replace with your own file path)
audio_path <- system.file("extdata", "soundscape.wav", package = "birdnetR")

# Predict species within the audio file
predictions <- predict_species_from_audio_file(model, audio_path)

# Get most probable prediction within each time interval
get_top_prediction(predictions)

```

## Developer Guide

### Cloning the Repository

To contribute to the development of birdnetR, you can clone the repository from GitHub:

```sh
git clone https://github.com/birdnet-team/birdnetR.git
cd birdnetR
```

### Setting Up the Development Environment

**Install R Package Dependencies**

Ensure you have all the necessary R package dependencies:

```r
install.packages(c("devtools", "roxygen2", "testthat", "reticulate"))
```

**Setting Up the Python Environment**

Set up a Python virtual environment and install the `birdnet` Python package as described above.


**Generating Documentation**

To generate the documentation, use the roxygen2 package:

```r
devtools::document()
```

**Running Tests**

To run the tests, use the testthat package:

```r
devtools::test()
```

**Building and checking the Package**

To build and check the package, use the devtools package:

```r
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
