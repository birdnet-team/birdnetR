# Package index

## Model loading

- [`birdnet_load()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  [`birdnet_load_perch()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  [`birdnet_load_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  [`birdnet_inspect_custom()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_load.md)
  : Load a BirdNET Model
- [`birdnet_list_models()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_models.md)
  : List the available BirdNET models
- [`birdnet_list_languages()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_languages.md)
  : List the languages of a BirdNET model version

## Prediction

- [`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
  : Predict species with a BirdNET model
- [`birdnet_predict(`*`<birdnet_model_acoustic>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.birdnet_model_acoustic.md)
  : Predict species from audio files using a BirdNET acoustic model
- [`birdnet_predict(`*`<birdnet_model_geo>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.birdnet_model_geo.md)
  : Predict species using a BirdNET geo model
- [`as.data.frame(`*`<birdnet_prediction>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/as.data.frame.birdnet_prediction.md)
  [`as.data.frame(`*`<birdnet_prediction_geo>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/as.data.frame.birdnet_prediction.md)
  : Convert BirdNET prediction results to a data frame
- [`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md)
  : Write BirdNET predictions or embeddings to a file

## Embeddings

- [`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)
  : Encode audio files using a BirdNET acoustic model
- [`as.data.frame(`*`<birdnet_encoding>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/as.data.frame.birdnet_encoding.md)
  : Convert BirdNET embeddings to a data frame

## Helpers

- [`birdnet_list_species()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_list_species.md)
  : List the species of a loaded model
- [`birdnet_sitrep()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_sitrep.md)
  [`print(`*`<birdnet_sitrep>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_sitrep.md)
  : Report the Python environment
- [`birdnet_use_gpu()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_use_gpu.md)
  : Set up GPU support
- [`print(`*`<birdnet_model>`*`)`](https://birdnet-team.github.io/birdnetR/dev/reference/print.birdnet_model.md)
  : Print a BirdNET model
