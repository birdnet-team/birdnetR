# Package index

## Installation

- [`install_arrow()`](https://birdnet-team.github.io/birdnetR/reference/install_arrow.md)
  : Install Apache Arrow

## Inference

### Models

- [`birdnet_model_tflite()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)
  [`birdnet_model_custom()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)
  [`birdnet_model_meta()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)
  [`birdnet_model_protobuf()`](https://birdnet-team.github.io/birdnetR/reference/birdnet_model_load.md)
  : Initialize a BirdNET Model

### Prediction

- [`get_top_prediction()`](https://birdnet-team.github.io/birdnetR/reference/get_top_prediction.md)
  : Get the top prediction by confidence within time intervals
- [`predict_species_at_location_and_time()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_at_location_and_time.md)
  : Predict species for a given location and time
- [`predict_species_from_audio_file()`](https://birdnet-team.github.io/birdnetR/reference/predict_species_from_audio_file.md)
  : Predict species within an audio file using a BirdNET model

## Helpers

- [`available_languages()`](https://birdnet-team.github.io/birdnetR/reference/available_languages.md)
  : Get Available Languages for BirdNET Model
- [`labels_path()`](https://birdnet-team.github.io/birdnetR/reference/labels_path.md)
  : Get Path to a Labels File
- [`read_labels()`](https://birdnet-team.github.io/birdnetR/reference/read_labels.md)
  : Read species labels from a file
