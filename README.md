# birdnetR <a href="https://birdnet-team.github.io/birdnetR/"><img src="man/figures/logo.png" align="right" height="139" alt="birdnetR website" /></a>

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/birdnet-team/birdnetR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/birdnet-team/birdnetR/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/birdnetR)](https://CRAN.R-project.org/package=birdnetR)
<!-- badges: end -->

`birdnetR` integrates [BirdNET](https://birdnet.cornell.edu/), a state‐of‐the‐art deep learning classifier for automated (bird) sound identification, into an R-workflow.
This package will simplify the analysis of (large) audio datasets from bioacoustic projects, allowing researchers to easily apply machine learning techniques—even without a background in computer science.

`birdnetR` is an R wrapper around the `birdnet` [Python package](https://github.com/birdnet-team/birdnet). It provides the core functionality to analyze audio using the pre-trained 'BirdNET' or a custom classifier, and to predict bird species occurrence based on location and week of the year.
However, it does not include all the advanced features available in the [BirdNET Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer). For advanced applications, such as training custom classifiers, users should use the 'BirdNET Analyzer' directly.
`birdnetR` is under active development, and changes may affect existing workflows.


## Installation

Install the released version from CRAN:

```r
install.packages("birdnetR")
```
<br>
or install the development version from GitHub with:

```r
pak::pak("birdnet-team/birdnetR")
```

<div style="padding: 15px; margin-bottom: 20px; border: 1px solid #bce8f1; border-radius: 4px; background-color: #d9edf7; color: #31708f;">
<strong>Note</strong><br>
 Python dependencies are installed on demand, meaning they are installed when you use them for the first time. This will result in longer initial setup.
</div>


## Example use

This is a simple example using the `tflite` BirdNET model to predict species in an audio file.

```r
# Load the package
library(birdnetR)

# Initialize a BirdNET model
model <- birdnet_model_tflite()

# Path to the audio file (replace with your own file path)
audio_path <- system.file("extdata", "soundscape.mp3", package = "birdnetR")

# Predict species within the audio file
predictions <- predict_species_from_audio_file(model, audio_path)

# Get most probable prediction within each time interval
get_top_prediction(predictions)

```


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


## Funding

This project is supported by Jake Holshuh (Cornell class of '69) and The Arthur Vining Davis Foundations. Our work in the K. Lisa Yang Center for Conservation Bioacoustics is made possible by the generosity of K. Lisa Yang to advance innovative conservation technologies to inspire and inform the conservation of wildlife and habitats.

The development of BirdNET is supported by the German Federal Ministry of Education and Research through the project “BirdNET+” (FKZ 01|S22072). The German Federal Ministry for the Environment, Nature Conservation and Nuclear Safety contributes through the “DeepBirdDetect” project (FKZ 67KI31040E). In addition, the Deutsche Bundesstiftung Umwelt supports BirdNET through the project “RangerSound” (project 39263/01).


## Partners

BirdNET is a joint effort of partners from academia and industry.
Without these partnerships, this project would not have been possible.
Thank you!

![Our partners](https://tuc.cloud/index.php/s/KSdWfX5CnSRpRgQ/download/box_logos.png)
