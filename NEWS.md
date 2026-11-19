# birdnetR (development version)

birdnetR 1.0 is a breaking release. It wraps version 1.5 of the Python
`birdnet` package (0.3.2 used 0.1.7) and loads BirdNET+ V3.0 by default. All
functions have new `birdnet_<verb>` names. The old functions are removed
without a deprecation cycle; the table below maps them to the new ones.

## Upgrading from birdnetR 0.3.2

| 0.3.2 | 1.0.0 |
|---|---|
| `birdnet_model_tflite(version = "v2.4")` | `birdnet_load(version = "2.4", backend = "tf")` |
| `birdnet_model_protobuf(version = "v2.4")` | `birdnet_load(version = "2.4", backend = "pb")` |
| `birdnet_model_meta(version = "v2.4")` | `birdnet_load(type = "geo", version = "2.4")` |
| `birdnet_model_custom(classifier_folder, classifier_name)` | `birdnet_load_custom(model = "<folder>/<name>.tflite", species_list = "<folder>/<name>_Labels.txt")` |
| `predict_species_from_audio_file(model, audio_file)` | `birdnet_predict(model, files = audio_file)`, then `as.data.frame()` |
| `predict_species_at_location_and_time(model, latitude, longitude, week)` | `birdnet_predict(model, latitude = , longitude = , week = )`, then `as.data.frame()` |
| `labels_path(model)`, `read_labels(species_file)` | `birdnet_list_species(model)` |
| `available_languages(version)` | `birdnet_list_languages(version)` |
| `get_top_prediction()` | Removed; use `dplyr::slice_max()` or birdnetTools |
| `install_arrow()` | Removed; not needed |

Arguments of the model loaders:

| 0.3.2 | 1.0.0 |
|---|---|
| `tflite_num_threads` (`birdnet_model_tflite()`, `birdnet_model_meta()`, `birdnet_model_custom()`) | Removed. Each model runs on one thread per worker; set `n_workers` in `birdnet_predict()` or `birdnet_encode()` for parallelism. |
| `custom_device` (`birdnet_model_protobuf()`) | Removed from the loader; pass `device = "CPU"` or `"GPU"` to `birdnet_predict()` or `birdnet_encode()`. See `birdnet_use_gpu()`. |

Arguments of the acoustic prediction function:

| 0.3.2 `predict_species_from_audio_file()` | 1.0.0 `birdnet_predict()` |
|---|---|
| `audio_file` (one file) | `files` (one or more files) |
| `chunk_overlap_s` | `overlap` |
| `filter_species` | `species_list` |
| `use_bandpass` | Removed; set `bandpass_fmin` / `bandpass_fmax` |
| `keep_empty` (default `TRUE`) | Removed; segments without detections give no rows, see below |
| `use_arrow` | Removed |

Output columns now follow the Python package exactly:

| Result | 0.3.2 | 1.0.0 |
|---|---|---|
| acoustic | `start`, `end`, `scientific_name`, `common_name`, `confidence` | `input`, `start_time`, `end_time`, `species_name`, `confidence` |
| geo | `label`, `confidence` | `species_name`, `confidence` |

For BirdNET models, `species_name` is `"<scientific name>_<common name>"`.

## Breaking changes

- Requires the Python package `birdnet` >= 1.5 (< 2) and Python 3.11 to 3.13.
  reticulate installs both on first use, as before.
- `birdnet_load()` loads BirdNET+ V3.0 by default. Use `version = "2.4"` for the
  model 0.3.2 used. Versions are written `"2.4"` and `"3.0"`, without the `v`.
- `birdnet_predict()` returns a result object instead of a data frame. Convert
  it with `as.data.frame()` or write it to a file with `birdnet_write()`.
- Segments without detections no longer produce a row. 0.3.2 defaulted to
  `keep_empty = TRUE` and returned a row with `NA` species and confidence for
  each such segment; 1.0 returns only actual detections, so row counts and
  per-file counts change. A recording without any detection gives a data frame
  with 0 rows.
- `birdnet_predict()` returns at most `top_k = 5` species per segment by
  default. 0.3.2 returned every species above `min_confidence`; use
  `top_k = NULL` for that.
- `apply_sigmoid` and `sigmoid_sensitivity` default to `NULL`, which means
  each model uses its own default.
- Loading the protobuf model on macOS no longer installs `tensorflow-metal`.
  Use `birdnet_use_gpu("pb")` for GPU support.

## New features

- BirdNET+ V3.0 acoustic and geo models. They run on ONNX Runtime, which is
  part of the default installation on every platform.
- `birdnet_load_perch()` loads Google's Perch v2 acoustic model (not supported
  on Intel macOS).
- `birdnet_encode()` returns embeddings (one vector per audio segment).
- `birdnet_load_custom()` loads classifiers trained with BirdNET-Analyzer on
  the 2.4 or 3.0 base model. `version = "auto"` reads the base version from a
  TFLite file. `birdnet_inspect_custom()` describes a TFLite classifier without
  loading it. Raven exports of custom classifiers load with
  `backend = "pb"` and `is_raven = TRUE`: scores span the full 0 to 1 range
  (the sigmoid is applied once), species names come from the label file
  without its id column, and `birdnet_encode()` does not work with them.
- Smaller default installation: the base install contains ONNX Runtime and
  LiteRT only. TensorFlow (for Perch, `backend = "pb"` and Raven exports) and
  PyTorch (for `backend = "pt"`) are installed automatically the first time a
  model needs them.
- `birdnet_list_models()` lists every model combination the installed Python
  package can load. Its `needs` column tells which ones download TensorFlow or
  PyTorch.
- `birdnet_list_languages()` and `birdnet_list_species()` list the languages of
  common names and the classes of a loaded model.
- `birdnet_predict()` for acoustic models accepts several files at once and
  gains `top_k`, `min_confidence_custom`, `apply_softmax`, `segment_size_s`
  (3.0 only), `device`, and settings for speed and memory (`n_workers`,
  `n_producers`, `prefetch_ratio`, `speed`, `half_precision`,
  `max_audio_duration_min`). Settings left at `NULL` use the Python defaults.
- `birdnet_predict()` for geo models gains `year_round_aggregation` (how
  weekly scores are combined when `week = NULL`), `half_precision` and
  `device`.
- `birdnet_write()` writes predictions and embeddings straight from Python to
  CSV, Parquet or NumPy (`.npz`) files.
- `birdnet_sitrep()` reports the Python version and path, the `birdnet`
  version and the installed runtimes. Include its output in bug reports.
- `birdnet_use_gpu()` sets up GPU support (PyTorch on Linux, TensorFlow on
  Linux and Apple silicon). `device = "GPU"` in `birdnet_load_perch()`,
  `birdnet_predict()` and `birdnet_encode()` uses it, with one worker per GPU
  unless you set `n_workers`.
- Loading a model prints one line naming the model, backend, precision and
  number of classes. `print()` on a model shows the same line.

## Bug fixes

- birdnetR no longer overwrites `RETICULATE_PYTHON`. If you point it at your
  own Python environment, birdnetR uses that environment.
- Integer arguments such as `top_k` and `bandpass_fmin` accept whole numbers
  like `5` as well as `5L`.
- A recording without detections gives a data frame with 0 rows and the usual
  columns.

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
