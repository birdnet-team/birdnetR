# BirdNET-R
This will include diffrent analytics functions and packages for using BirdNET in R as standalone.

## Dev setup

run in R console:

```
install.packages("reticulate")

library(reticulate)
reticulate::virtualenv_create("r-reticulate")
reticulate::virtualenv_install("r-reticulate", packages = "birdnet")
reticulate::use_virtualenv("r-reticulate", required = TRUE)
```


run for docs:

```
usethis::use_roxygen_md()
devtools::document()
```

run tests

```
devtools::build()
devtools::check()
```

## Example use

First, install the `reticulate` package if you haven't already:

```r
install.packages("reticulate")
```

Then, create and configure a Python virtual environment:

```r
library(reticulate)
reticulate::virtualenv_create("r-reticulate")
reticulate::virtualenv_install("r-reticulate", packages = "birdnet")
reticulate::use_virtualenv("r-reticulate", required = TRUE)
```

Here's a simple example of how to use the YourPackage to predict bird species from an audio file:

```r
# Load the package
library(birdnet)

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

## License

This package is licensed under the MIT License. See the LICENSE file for details.

