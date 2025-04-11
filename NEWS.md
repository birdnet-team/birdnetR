# birdnetR 0.2.3

## Major changes
- use `recticulate::py_require()` to resolve python dependencies in an ephemeral virtual environment
- refactors tests to use a hybrid approach of unit tests and mocking without the `birdnet` python package,
  and full integration tests that depend on the `birdnet` python package. See `tests/TEST_PLAN.md` for more details.
- initial CRAN release preparations

## Defunctions
- `install_birdnet()` is now a defunctioned. It is no longer needed to install the `birdnet` python package
  manually. The package will be installed automatically when you use it for the first time.

# birdnetR 0.2.2

- updates `birdnet` Python package to `0.1.7`.
- Fixes #21: unable to initialize model
- Added a check if audio file is mono

# birdnetR 0.2.1

- install the TensorFlow Metal Plugin for GPU support on Apple devices  #25
- optionally use Apache Arrow to improve performance by reducing memory usage during data conversion and minimizing data
  copying between R and Python. #26


# birdnetR 0.2.0

This update brings significant changes and improvements, including support for loading pre-existing and custom-trained models, aligning the package with birdnet `0.1.6`.

#### breaking changes:
- The `init_model()` function is now **deprecated** and will be removed in the next version. Please use the `birdnet_model_*` function family for model initialization.
- `available_languages()` **update**: A new argument has been added to `available_languages()` to specify the BirdNET version, making it more flexible for different model versions.
- **Renaming** `get_labels_path` to `labels_path()`. It now requires a model object as its first argument.
- `predict_species()` was **renamed** to `predict_species_from_audio_file()`
- `predict_species_at_location_and_time()` was **changed** to requirer a model object as first argument.

#### New features:
 * **Support for Custom Models:** You can now load custom-trained models
 * **A new set of functions** (`birdnet_model_*`) to load pre-existing and custom-trained models. These functions offer a more flexible approach to model loading. See `?birdnet_model_load` for more details.
 * **S3 Object-Oriented System:** The models are now implemented as S3 classes, and most of the functionality related to these models is provided through methods. This update makes the API cleaner and more consistent, and allows for better extensibility in future versions.


# birdnetR 0.1.2

Uses `birdnet v0.1.6` under the hood to fix an issue when downloading models.
No new functionality has yet been implemented.


# birdnetR 0.1.1

The update of `birdnet` to `0.1.1` brings: <br>
- Add parameter 'chunk_overlap_s' to define overlapping between chunks <br>
- Remove parameter 'file_splitting_duration_s' instead load files in 3s chunks <br>
- Remove 'librosa' dependency<br>

Other: <br>
- check of the correct version of `birdnet` is installed in the current virtual environment <br>
- expand vignette on how to use virtual environments <br>


# birdnetR 0.1.0
  
- initial release
