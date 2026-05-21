# birdnetR 1.0.0 (development version)
 
This is a **breaking release**. The package API has been redesigned to align
with the upstream `birdnet` Python package (>=0.2.16,<0.3). Legacy entry points
are removed without a deprecation cycle.

## Upgrading from birdnetR 0.x

The table below maps removed functions to their replacements:

| Removed | Replacement |
|---|---|
| `birdnet_model_tflite(...)` | `load_birdnet(..., backend = "tf", library = "tflite")` |
| `birdnet_model_protobuf(...)` | `load_birdnet(..., backend = "pb")` |
| `birdnet_model_meta(...)` | `load_birdnet(type = "geo", ...)` |
| `birdnet_model_custom(...)` | `load_custom(...)` |
| `predict_species_from_audio_file(model, ...)` | `predict(model, files = ...)` |
| `predict_species_at_location_and_time(model, ...)` | `predict(model, latitude = ..., longitude = ..., ...)` |
| `labels_path(model)` | `get_species_list(model)` |
| `read_labels(path)` | `get_species_list(model)` on a loaded model |
| `available_languages(version)` | `supported_languages()` |
| `get_top_prediction()` | Removed; use `dplyr::slice_max()` or `birdnetTools` |

## Breaking changes

- All legacy model loaders (`birdnet_model_tflite()`, `birdnet_model_protobuf()`,
  `birdnet_model_meta()`, `birdnet_model_custom()`) are removed.
  Use `load_birdnet()` or `load_custom()` instead.
- `load_model()` has been renamed to `load_birdnet()` to distinguish it from the future `load_perch()` loader (#45).
- `predict_species_from_audio_file()` and `predict_species_at_location_and_time()`
  are removed. Use `predict()` on a loaded model.
- `labels_path()` and `read_labels()` are removed.
  Use `get_species_list(model)` instead.
- `available_languages()` is removed. Use `supported_languages()`.
- `get_top_prediction()` is removed. Use `dplyr::slice_max()` or the
  `birdnetTools` package for post-processing.
- The `labels` argument in `load_custom()` is replaced by `species_list`.
- `predict()` for geo models now defaults `min_confidence` to `0.03` to match the upstream Python `birdnet` default.

## New features

- `load_perch()` loads the Perch v2 acoustic model (CPU only). The returned model object is compatible with the existing `predict()` and `as.data.frame()` workflows (#46). Device selection is not exposed, consistent with `load_birdnet()`.
- `load_birdnet()` now supports `type`, `version`, `backend`, `library`,
  `precision`, and `language` arguments for flexible model loading.
- `load_custom()` gains advanced arguments `classifier_type` and `is_raven`
  for custom model configurations.
- `supported_model_configurations()` returns all valid model configuration
  combinations.
- `supported_languages()` returns the set of supported language codes.
- `get_species_list(model)` retrieves the species list from a loaded model.
- `write_predictions()` saves prediction results directly from Python to CSV,
  Parquet, or NumPy format without crossing the R boundary.
- `birdnet_version()` returns the installed Python version, executable path,
  and `birdnet` package version.
- `predict()` for acoustic models now exposes performance parameters `n_producers`, `n_workers`, `batch_size`, `prefetch_ratio`, `speed`, `half_precision`, and `max_audio_duration_min`; these default to `NULL` so the Python backend defaults are used unless explicitly set.
- `predict()` for geo models now exposes `half_precision`, defaulting to `NULL` so the Python backend default is used unless explicitly set.

## Bug fixes

- `load_perch()` internally hardcodes CPU for the upstream Python call; the `device` argument is not exposed to users (#46).
- `supported_model_configurations()` documentation now explicitly notes that Perch v2 is excluded from the table and directs users to `load_perch()` (#46).
- `supported_model_configurations()` no longer advertises acoustic version `"2"` (Perch v2), which is not loadable via `load_birdnet()` (#45).
- Integer-like parameter validation (`top_k`, `bandpass_fmin`, etc.) now silently accepts whole-number doubles (e.g. `5`) in addition to integer values (e.g. `5L`) (#45).
- `as.data.frame()` for acoustic and geo prediction objects now converts
  results via a Python dict helper that calls `to_structured_array()` and
  returns plain Python lists and numpy arrays, bypassing `pandas` entirely.
  This fixes corrupt data frames caused by Arrow-backed `StringDtype` columns
  introduced in pandas >= 2 when pyarrow is installed.

# birdnetR 0.3.2

- Removes defunct and deprected functions `init_model()` and `install_birdnet()`.
- Includes some minor changes to take CRAN Reviewer comments into account.

# birdnetR 0.3.1

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
