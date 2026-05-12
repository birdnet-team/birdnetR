# birdnetR 1.0 update plan (upstream: birdnet >=0.2.16,<0.3)

This document translates the migration guidance in
`dev/architecture/birdnet-python-architecture.md` into a concrete,
test-driven implementation checklist for updating `birdnetR` to the current
`birdnet` Python API.

This is a breaking release to version 1.0. Legacy entry points are removed
without a deprecation cycle. The upgrade path for users is documented in
`NEWS.md` and the README migration guide.

## Target

- Upstream target: `birdnet` `>=0.2.16,<0.3`
- R package version: `1.0.0` (breaking release)
- R strategy: API-first, test-driven migration
- Scope:
  - pretrained acoustic and geo model loading
  - custom model loading
  - prediction
  - explicit conversion to R data frames
  - Python-side saving/export where possible
  - legacy code removal and docs cleanup

## Guiding principles

1. Use the new Python `birdnet` package as the source of truth.
2. Keep the R bridge thin and explicit.
3. Minimize Python-to-R conversion until the user asks for an R object.
4. Remove all legacy entry points cleanly; document the upgrade path.
5. Prefer behavior tests over implementation-coupled tests.

## Canonical R API after migration

The intended primary API is:

- `load_model()`
- `load_custom()`
- `predict()` via S3 methods
- `as.data.frame()` for prediction objects
- `write_predictions()`
- `supported_model_configurations()`
- `supported_languages()`
- `get_species_list()`

Also exported but not part of the core migration:

- `install_arrow()` — de-emphasized; upstream `birdnet` depends on `pyarrow`

## Removed legacy surface

The following entry points are removed in 1.0. The upgrade path is documented
for users in `NEWS.md`.

| Removed | Replacement |
|---|---|
| `birdnet_model_tflite(...)` | `load_model(..., backend = "tf", library = "tflite")` |
| `birdnet_model_protobuf(...)` | `load_model(..., backend = "pb")` |
| `birdnet_model_meta(...)` | `load_model(type = "geo", ...)` |
| `birdnet_model_custom(...)` | `load_custom(...)` |
| `predict_species_from_audio_file(model, ...)` | `predict(model, files = ...)` |
| `predict_species_at_location_and_time(model, ...)` | `predict(model, latitude = ..., longitude = ..., ...)` |
| `labels_path(model, ...)` | `get_species_list(model)` |
| `read_labels(path)` | `get_species_list(model)` on a loaded model |
| `labels =` in `load_custom()` | `species_list =` |
| `available_languages(version)` (old signature) | `supported_languages()` (no args) |
| `get_top_prediction()` | Removed; use `dplyr` or `birdnetTools` |

Also removed (internal or supporting code):

- `birdnet_interface.R` — old model loader and prediction code
- `module_map.R` — dynamic Python module path resolution
- `predictions_to_df()` — legacy internal converter

## API decisions

### 1. Model loading

`load_model()` remains the canonical loader for pretrained models.

Expected user contract:

- validates obvious R-side type/shape issues early
- delegates compatibility validation to Python
- returns a lightweight S3 wrapper around the Python model object

Supported arguments:

- `type`
- `version`
- `backend`
- `library`
- `precision`
- `language`

### 2. Custom model loading

`load_custom()` remains the canonical loader for custom models.

Expected user contract:

- the argument is `species_list`, matching the Python API
- the old `labels` argument is removed without an alias
- the R wrapper stays aligned with Python semantics

Include advanced arguments now:

- `classifier_type`
- `is_raven`

Reason:

- both are part of the current Python loader contract
- not exposing them would leave valid Python features unreachable from R
- adding them later would force another public API change

These should be documented as advanced options rather than emphasized in basic
examples.

### 3. Prediction

`predict()` is the canonical prediction interface.

Expected user contract:

- acoustic predictions operate on files in the first migration pass
- geo predictions remain explicit and minimal
- return values remain Python-backed prediction wrappers until conversion is
  requested

Execution model:

- `predict()` is eager and blocking: it processes all input files and returns
  only when inference is complete
- results are stored as compact pre-allocated numpy arrays on the Python side
  (species IDs, probabilities, masks)
- the R wrapper holds a reference to the Python result object via
  `$py_predictions`; no data crosses the Python→R boundary until the user
  requests conversion
- there is no streaming or lazy evaluation; for very large datasets (e.g.
  100 GB of audio), users should chunk input files and call `predict()` +
  `write_predictions()` per chunk

### 4. Result conversion

`as.data.frame()` remains the primary conversion path.

Expected user contract:

- conversion is explicit
- prediction wrappers should not promise internal field names as stable API

Conversion mechanics:

- `as.data.frame()` calls the Python helper `inst/python/df_utils.py`
  (`predictions_to_dict()`), which calls `to_structured_array()` on the
  prediction object to materialise results as a structured numpy array
- each dtype field is extracted individually:
  - string / object columns (`U`, `O` dtypes) → plain Python lists via `.tolist()`
  - numeric columns → raw numpy arrays
  - multi-dimensional columns → Python lists
- the resulting plain Python `dict` is returned to R and passed to `as.data.frame()`;
  `reticulate` converts each value to an R vector without involving pandas
- this bypasses `pandas.to_dataframe()` entirely, avoiding Arrow-backed
  `StringDtype` conversion issues that arise with `pandas >= 2` + `pyarrow`
- the helper module is loaded lazily via `get_df_helper()` in `R/predict.R`
  and cached in `.df_cache` for the session lifetime
- geo predictions pass `sort_by = NULL` to suppress Python-side sorting;
  acoustic predictions use the Python default
- this is the step where memory grows: the compact numpy tensor is expanded
  into full string columns
- for large results, prefer `write_predictions()` to write directly from Python
  without crossing the R boundary

### 5. Saving/export

`write_predictions()` remains the canonical persistence helper.

Expected user contract:

- delegates to Python-side writers; data never crosses into R
- infer `format` from file extension when unambiguous
- allow explicit `format =` override
- error early for unsupported or ambiguous formats

Supported formats by result type:

| Format | Acoustic predictions | Geo predictions |
|---|---|---|
| CSV (`.csv`) | yes | yes |
| Parquet (`.parquet`) | yes | **no** (not implemented upstream) |
| NumPy (`.npz`) | yes | yes |

Dispatch:

- `write_predictions()` dispatches on `birdnet_prediction` (the shared parent class)
- `write_predictions().birdnet_prediction_geo()` intercepts parquet requests with a
  clear error before delegating to the parent method
- the R wrapper accesses the Python object via `x$py_predictions` (not the
  legacy `x$py_result`)

Reason for extension-based inference:

- keeps the common case concise
- matches common R file-writing patterns
- still permits strict validation

### 6. Species list exploration

Species list exploration is part of the user-facing API, backed by the loaded
Python model object.

Resolved direction:

- the species list is available from loaded model objects via
  `get_species_list(model)`
- the implementation delegates to the Python model's `species_list` property
- no file-path-based exploration (`labels_path()`, `read_labels()`) is retained
- `get_species_list()` is a standalone exported function, not an S3 generic

### 7. Diagnostic helper

Not in scope for the first migration release, but worth defining now.

A future diagnostic helper would report:

- selected Python executable/version
- installed `birdnet` version
- import status for required Python modules
- backend/library availability
- cache/model directories in use

Candidate names:

- `birdnet_status()`
- `birdnet_diagnose()`

## Resolved API freeze decisions

- expose `classifier_type` and `is_raven` now; if a path is not fully
  functional yet, mark it explicitly in docs/tests
- keep species list exploration as a supported user need
- base species list exploration on the loaded Python model object
- add `get_species_list(model)` as the model-backed exploration function
- remove `labels_path()` — no replacement
- remove `read_labels()` — no replacement
- keep `install_arrow()` out of the core migration; upstream `birdnet` already
  depends on `pyarrow`
- remove all legacy entry points (`birdnet_model_*`, `predict_species_*`,
  etc.) without a deprecation cycle

## Final exported surface decision

### Exported API

| Function | Decision | Notes |
|---|---|---|
| `load_model()` | keep | canonical pretrained loader |
| `load_custom()` | keep | canonical custom loader |
| `predict()` | keep | canonical prediction API |
| `as.data.frame()` | keep | explicit R conversion boundary |
| `write_predictions()` | keep | Python-side export; dispatches on `birdnet_prediction` |
| `supported_model_configurations()` | keep | Python-backed discovery helper (renamed from `model_options()`) |
| `supported_languages()` | keep | Python-backed discovery helper (renamed from `available_languages()`) |
| `get_species_list()` | add | model-backed species list exploration |
| `install_arrow()` | keep | de-emphasized; not part of core migration |

### Removed from API

| Function | Notes |
|---|---|
| `birdnet_model_tflite()` | replaced by `load_model()` |
| `birdnet_model_protobuf()` | replaced by `load_model()` |
| `birdnet_model_meta()` | replaced by `load_model()` |
| `birdnet_model_custom()` | replaced by `load_custom()` |
| `predict_species_from_audio_file()` | replaced by `predict()` |
| `predict_species_at_location_and_time()` | replaced by `predict()` |
| `labels_path()` | replaced by `get_species_list()` |
| `read_labels()` | replaced by `get_species_list()` |
| `get_top_prediction()` | removed; use `dplyr` or `birdnetTools` |

## Object contracts for the future API

These contracts are defined by the future primary entry points:

- `load_model()`
- `load_custom()`
- `predict()`

### Model object contract for `load_model()` and `load_custom()`

Stable, user-relevant contract:

- wraps a loaded Python model object
- records model identity needed for dispatch and inspection
- supports `predict()`
- supports `get_species_list()`

The public contract should stay minimal. Internal storage details should not be
treated as stable unless they are intentionally documented.

### Prediction object contract for `predict()`

Stable, user-relevant contract:

- wraps prediction results produced by the loaded Python model
- supports `as.data.frame()`
- supports `write_predictions()`

The future contract is behavioral rather than structural. Internal list fields
or wrapper names should not be treated as user-facing guarantees unless they are
explicitly documented.

### Species list contract for `get_species_list()`

Stable, user-relevant contract:

- input: loaded model object from `load_model()` or `load_custom()`
- output: plain R character vector
- content: full species list in model order
- works for pretrained and custom models
- delegates to the Python model's `species_list` property

## Coding and review strategy

### Phase rules

1. **Planning only**
   - allowed: architecture, API decisions, migration checklist, test design
   - not allowed: package code changes, dependency changes, roxygen changes
2. **Spec-only**
   - allowed: tests that define the intended behavior
   - not allowed: implementation changes
3. **Implementation**
   - allowed: minimal code needed to satisfy the approved tests
   - scope: one migration slice at a time
4. **Review**
   - every slice gets a critical review before moving on

### Skill usage

- `describe-design`
  - maintain architecture and migration docs
  - keep the API contract and old-to-new mapping current
- `testing-r-packages`
  - design spec tests first
  - prefer self-contained tests
  - use snapshots for warning and error text where helpful
- `r-package-development`
  - keep changes in small package-sized slices
  - pair each user-facing change with tests and docs impact
- `critical-code-reviewer`
  - review each slice with blocking/required/suggestion outcomes

### Review gates

#### Gate 1: API freeze

Must be agreed before any test or code work:

- exported function set
- argument names
- result object contract
- save/export behavior

#### Gate 2: spec freeze

Must be agreed before implementation:

- unit test coverage
- integration test coverage
- snapshot coverage for errors

#### Gate 3: slice approval

Each implementation slice must include:

- passing tests for that slice
- documented migration impact
- documented review outcome

### Slice order

1. runtime/bootstrap strategy
2. model loading API
3. prediction/result contract
4. saving/export
5. legacy code removal
6. docs and namespace cleanup

## Spec-first test matrix

### A. API contract tests

These define the intended stable surface.

| Area | Tests to define |
|---|---|
| `load_model()` | accepted args, early R validation, object class/metadata contract |
| `load_custom()` | `species_list` naming, advanced args, object metadata contract |
| `predict()` acoustic | accepted inputs, argument mapping, returned wrapper contract |
| `predict()` geo | accepted inputs, argument mapping, returned wrapper contract |
| `as.data.frame()` | explicit conversion behavior and expected tabular shape |
| `write_predictions()` | supported formats, extension inference, early error behavior |
| `supported_model_configurations()` | machine-readable configurations and compact view |
| `supported_languages()` | Python-backed discovery contract |
| `get_species_list()` | model-backed species list exploration contract |

### B. Integration tests

These confirm real Python interoperability.

| Area | Integration target |
|---|---|
| official acoustic model | load + predict |
| official geo model | load + predict |
| custom model path | load_custom for supported combinations |
| result conversion | `as.data.frame()` on real results |
| result saving | Python-side export succeeds |

### C. Review focus per slice

| Slice | Main review concerns |
|---|---|
| bootstrap | dependency drift, fragile environment assumptions |
| model loading | API drift vs Python loader, bad argument naming |
| prediction | wrapper shape drift, accidental eager conversion |
| saving | stale result assumptions, unsupported format promises |
| legacy removal | leftover imports, stale test references |
| docs | stale examples, mismatch with real API |

## TDD migration checklist

### Phase 1: freeze the intended API in tests

- [x] Add API contract tests for `load_model()`
- [x] Add API contract tests for `load_custom()`
- [x] Add API contract tests for acoustic `predict()`
- [x] Add API contract tests for geo `predict()`
- [x] Add API contract tests for `as.data.frame()`
- [x] Add API contract tests for `write_predictions()`
- [x] Add API contract tests for `supported_model_configurations()`
- [x] Add API contract tests for `supported_languages()`
- [x] Add API contract tests for `get_species_list()`

Test rule:

- new tests should assert user-visible behavior, not brittle internal Python
  class names or module paths

### Phase 2: align the runtime bootstrap

- [x] Update dependency pinning in `R/birdnetR-package.R` to target `birdnet`
      `>=0.2.16,<0.3`
- [x] Reassess Python version range against upstream package requirements
      (now `>=3.11,<3.14`, matching upstream)
- [x] Reassess whether explicit `ai_edge_litert` pinning is still needed
      (removed; no longer required)
- [x] Reassess `numpy` version ceiling (`<2.0.0`) against upstream requirements
      (removed; no ceiling needed)
- [x] Remove orphaned `py_pathlib` import from `.onLoad` in
      `R/birdnetR-package.R` (removed)

### Phase 3: implement the core API contract

- [x] Align `load_model()` argument handling with upstream Python loader
- [x] Use `species_list` as the argument name in `load_custom()` (no alias)
- [x] Add advanced custom-model arguments `classifier_type` and `is_raven`
- [x] Ensure model wrapper objects carry only the metadata needed for dispatch
      and documentation

### Phase 4: implement prediction and result behavior

- [x] Confirm acoustic `predict()` argument mapping against upstream Python
- [x] Confirm geo `predict()` argument mapping against upstream Python
- [x] Standardize the prediction wrapper shape in `R/predict.R`
- [x] Implement `get_species_list()` backed by the Python model's
      `species_list` property
- [x] Align `write_predictions()` dispatch to use `birdnet_prediction` as the
      dispatch class
- [x] Implement format inference from file extension
- [x] Validate supported writers per prediction/result type

### Phase 5: remove legacy code

- [x] Delete `R/birdnet_interface.R`
- [x] Delete `R/module_map.R`
- [x] Remove `predictions_to_df()` from `R/utils.R`
- [x] Remove all legacy exports from `NAMESPACE`
- [x] Remove legacy unit and integration tests that exercise old entry points
- [x] Confirm no retained code path references stale Python module handles
      (`py_birdnet_models`, `py_birdnet_audio_based_prediction`, etc.)


### Phase 6a: end-to-end integration tests

These tests run against a real Python environment with `birdnet` installed and
use `skip_if_not(is_full_test_env())`. They live in
`tests/testthat/test-integration-*.R`.

- [x] Bootstrap: Python importable, version within supported range
- [x] Model loading: acoustic and geo via `load_model()`
- [x] Model wrapper: S3 class vector, species list access
- [x] Acoustic predict: `predict()` on bundled `soundscape.mp3`, returns prediction object
- [x] Geo predict: `predict()` on a location/week, returns prediction object
- [x] Result conversion: `as.data.frame()` on acoustic and geo predictions
- [x] Result saving: `write_predictions()` round-trip for CSV (acoustic and geo)

### Phase 6b: documentation and namespace cleanup

- [x] Update `README.md` to use only the new API in primary examples
- [x] Add an upgrade guide section mapping old entry points to new ones
- [x] Update vignettes to use `load_model()` / `load_custom()` + `predict()`
- [x] Update roxygen docs for all exported functions
- [x] Regenerate `NAMESPACE`
- [x] Regenerate `.Rd` files
- [x] Update `NEWS.md` with breaking changes and upgrade instructions


### Phase 7: release-readiness checks

- [x] Confirm all exported functions work correctly
- [x] Confirm no retained code path relies on stale Python module layout
- [x] Confirm docs/examples match the exported API
- [x] Confirm integration tests cover the supported loading/prediction paths
- [x] Run `R CMD check` with no errors or warnings

## Initial implementation order

1. tests for the new API contract
2. runtime bootstrap alignment
3. `load_model()` / `load_custom()` alignment
4. `predict()` / `write_predictions()` alignment
5. legacy code removal
6. docs and namespace regeneration

## Open decisions to revisit during implementation

1. whether `install_arrow()` stays public or becomes internal/documented only
2. whether a diagnostic helper (`birdnet_status()` / `birdnet_diagnose()`)
   should be added in a follow-up release
3. whether `numpy` version ceiling (`<2.0.0`) in bootstrap is still needed