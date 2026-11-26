# Functions in relation to loading BirdNET models

#' Create a new BirdNET model object
#'
#' Wraps a Python model object in an S3 object whose class vector encodes type,
#' backend and version for method dispatch.
#'
#' @param py_model A Python object representing the BirdNET model
#' @param type Model type: "acoustic", "geo"
#' @param backend Backend: "tf", "pb", "pt", "onnx"
#' @param version Version of the model, e.g., "3.0"
#' @param custom Logical indicating if the model is a custom model
#' @param ... Additional fields stored in the model object (NULLs are dropped)
#'
#' @return An S3 object of class `birdnet_model` (and additional subclasses).
#' @noRd
construct_model_class <- function(
  py_model,
  type,
  backend,
  version,
  custom,
  ...
) {
  stopifnot(reticulate::is_py_object(py_model))

  cl <- c(
    paste0("birdnet_model_", type, "_v", gsub("\\.", "_", version)),
    paste0("birdnet_model_", type),
    paste0("birdnet_model_", backend),
    paste0("birdnet_model_v", gsub("\\.", "_", version)),
    if (custom) "birdnet_model_custom",
    "birdnet_model"
  )

  structure(
    c(
      list(
        py_model = py_model,
        model_type = type,
        model_version = version,
        backend = backend,
        custom = custom
      ),
      compact_nulls(list(...))
    ),
    class = cl
  )
}


# `switch()` matches numbers by position, so `version = 3.0` would silently
# become "3"; refuse anything that is not a single string.
check_version <- function(version) {
  if (!is_string(version)) {
    stop(
      "`version` must be a string, e.g. \"3.0\" or \"2.4\".",
      call. = FALSE
    )
  }
  invisible(version)
}


# Default backend for an official model version: 3.0 runs on the base
# install via ONNX, 2.4 via the tf backend (LiteRT where available).
resolve_backend <- function(version, backend) {
  check_arg(
    is.null(backend) || is_string(backend),
    "backend", "a string or `NULL`"
  )
  if (!is.null(backend)) {
    return(backend)
  }
  switch(
    version,
    "3.0" = "onnx",
    "2.4" = "tf",
    stop(
      "`version` must be \"3.0\" or \"2.4\", not \"", version, "\".",
      call. = FALSE
    )
  )
}


# Is LiteRT part of the default installation? Never starts Python: before it runs,
# decide by platform (mirrors the wheel marker of `ai-edge-litert` in birdnet
# 1.5: Linux, macOS arm64, Windows x86-64); afterwards, look the module up
# without importing it.
litert_available <- function() {
  if (reticulate::py_available()) {
    return(!is.null(reticulate::import("importlib.util")$find_spec("ai_edge_litert")))
  }
  p <- platform()
  switch(
    p[["sysname"]],
    Linux = TRUE,
    Darwin = p[["machine"]] == "arm64",
    Windows = p[["machine"]] == "x86-64",
    FALSE
  )
}


# The TFLite interpreter for the tf backend: LiteRT ships with the base
# install where it has wheels; the default TFLite interpreter needs birdnet[tf].
resolve_library <- function(backend, library) {
  if (backend != "tf") {
    return(NULL)
  }
  if (!is.null(library)) {
    return(library)
  }
  if (litert_available()) "litert" else "tflite"
}


# Which birdnet extra a backend needs on top of the default installation, if any.
needed_extra <- function(backend, library, is_raven = NULL) {
  if (backend == "pb" || identical(library, "tflite") || isTRUE(is_raven)) {
    return("tf")
  }
  if (backend == "pt") {
    return("pt")
  }
  NULL
}


require_extra_for <- function(backend, library, is_raven = NULL) {
  extra <- needed_extra(backend, library, is_raven)
  if (!is.null(extra)) {
    require_birdnet_extra(extra)
  }
  invisible(extra)
}


#' @title Load a BirdNET Model
#' @name birdnet_load
#' @description
#' Load BirdNET models for sound identification or for species prediction from
#' location and time. Models are downloaded on first use.
#'
#' * [birdnet_load()]: an official BirdNET model (acoustic or geographic).
#' * [birdnet_load_perch()]: the Perch v2 acoustic model.
#' * [birdnet_load_custom()]: a custom classifier trained with BirdNET-Analyzer.
#' * [birdnet_inspect_custom()]: describe a custom TFLite classifier without loading it.
#'
#' Every successful load prints one line naming the loaded model; silence it
#' with [suppressMessages()].
#'
#' @details
#' `type`:
#' * `"acoustic"`: identify species in audio recordings.
#' * `"geo"`: predict which species occur at a location and week of the year.
#'
#' `version`: `"3.0"` (BirdNET+ V3.0, the default) or `"2.4"`.
#'
#' `backend`:
#' * `"onnx"`: ONNX Runtime (3.0 only). Part of the default installation; the default for 3.0.
#' * `"tf"`: TensorFlow Lite (TFLite) model, CPU only. The default for 2.4.
#' * `"pt"`: PyTorch (3.0 only), CPU or GPU. Installs `birdnet[pt]` on first use.
#' * `"pb"`: TensorFlow SavedModel (Protobuf), CPU or GPU. Installs `birdnet[tf]` on first use.
#'
#' If `backend` is `NULL`, it follows the version: `"onnx"` for 3.0 and `"tf"` for 2.4.
#'
#' `library` only applies to `backend = "tf"`:
#' * `"litert"`: the LiteRT interpreter, part of the default installation on the platforms listed below.
#' * `"tflite"`: TensorFlow's own interpreter. Installs `birdnet[tf]` on first use.
#'
#' If `library` is `NULL`, LiteRT is used where it is available (Linux, macOS on
#' Apple silicon, Windows on x86-64), otherwise `"tflite"`. The geo 3.0 model
#' always uses `"tflite"`.
#'
#' `precision`: `"fp32"`, `"fp16"` or `"int8"`; not every model supports every precision.
#'
#' Heavy runtimes (TensorFlow for `"pb"`, `"tflite"` and Perch; PyTorch for `"pt"`)
#' are not part of the default installation. They are added automatically the
#' first time a model needs them, which can take a while.
#'
#' The Perch v2 model is not supported on Intel Macs.
#'
#' Use [birdnet_list_models()] for all valid combinations and which ones need
#' an extra download.
#'
#' @param type character. `"acoustic"` or `"geo"`.
#' @param version character. Model version, `"3.0"` or `"2.4"`. For custom classifiers `"auto"` reads it from the file (TFLite only).
#' @param backend character or `NULL`. `"onnx"`, `"tf"`, `"pt"` or `"pb"`.
#' @param library character or `NULL`. `"litert"` or `"tflite"`. Only applies to `backend = "tf"`.
#' @param precision character. `"fp32"`, `"fp16"` or `"int8"`.
#'
#' @return A BirdNET model object (S3 class `birdnet_model` with type-, backend- and version-specific subclasses).
#' Use it with [birdnet_predict()], [birdnet_encode()] (acoustic models) and [birdnet_list_species()].
#' Internal list fields are implementation details and should not be relied upon.
#'
#' `birdnet_inspect_custom()` returns a named list describing a custom TFLite
#' classifier: `version` (base model, `"2.4"` or `"3.0"`), `mode` (`"replace"`
#' or `"append"`), `n_species`, `applies_sigmoid`, `supports_encoding` and
#' `input_samples` (`NULL` if any input length is accepted).
#'
#' @examples
#' \dontrun{
#' # BirdNET+ V3.0 acoustic model (default)
#' model <- birdnet_load()
#'
#' # BirdNET V2.4 and the V3.0 geo model
#' model_24 <- birdnet_load(version = "2.4")
#' geo <- birdnet_load(type = "geo")
#'
#' # Perch v2
#' perch <- birdnet_load_perch()
#'
#' # A custom classifier trained with BirdNET-Analyzer: describe it, then load it
#' birdnet_inspect_custom("path/to/CustomClassifier.tflite")
#' custom <- birdnet_load_custom(
#'   model = "path/to/CustomClassifier.tflite",
#'   species_list = "path/to/CustomClassifier_Labels.txt"
#' )
#' }
NULL


#' @rdname birdnet_load
#' @param language character. Language of the common species names, e.g. `"en_us"`. See [birdnet_list_languages()].
#' @export
birdnet_load <- function(
  type = "acoustic",
  version = "3.0",
  backend = NULL,
  library = NULL,
  precision = "fp32",
  language = "en_us"
) {
  check_version(version)
  backend <- resolve_backend(version, backend)
  if (is.null(library) && identical(c(type, version, backend), c("geo", "3.0", "tf"))) {
    # the birdnet Python package refuses LiteRT for this model
    library <- "tflite"
  }
  library <- resolve_library(backend, library)
  require_extra_for(backend, library)

  args <- c(
    list(type, version, backend, precision = precision, lang = language),
    compact_nulls(list(library = library))
  )
  py_model <- do.call(py_birdnet$load, args)

  model <- construct_model_class(
    py_model = py_model,
    type = type,
    backend = backend,
    version = version,
    custom = FALSE,
    library = library,
    precision = precision,
    language = language
  )
  announce_model(model)
}


#' @rdname birdnet_load
#' @param device character. `"CPU"` (default) or `"GPU"` (see [birdnet_use_gpu()]).
#' @export
birdnet_load_perch <- function(device = "CPU") {
  if (is_intel_mac()) {
    stop("The Perch v2 model is not supported on Intel Macs.", call. = FALSE)
  }
  require_birdnet_extra("tf")
  py_model <- py_birdnet$load_perch_v2(device)
  stopifnot(reticulate::is_py_object(py_model))

  model <- structure(
    list(
      py_model = py_model,
      model_type = "acoustic",
      model_version = "perch_v2",
      backend = "pb",
      precision = "fp32",
      device = device,
      custom = FALSE
    ),
    class = c(
      "birdnet_model_perch_v2",
      "birdnet_model_perch",
      "birdnet_model_acoustic",
      "birdnet_model"
    )
  )
  announce_model(model)
}


#' @rdname birdnet_load
#' @param model character. Path to the custom classifier: a `.tflite` file for `backend = "tf"`, a directory for `backend = "pb"`.
#' @param species_list character. Path to the label file of the custom classifier.
#' @param check_validity logical. Check that the model can be loaded before using it.
#' @param is_raven logical or `NULL`. Only for `backend = "pb"`: is the classifier a Raven export? `NULL` (default) uses the default of the `birdnet` Python package: `TRUE` for a 2.4 classifier, `FALSE` for a 3.0 one. Set `FALSE` for a 2.4 classifier that is not a Raven export.
#' @export
birdnet_load_custom <- function(
  model,
  species_list,
  type = "acoustic",
  version = "auto",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  check_validity = TRUE,
  is_raven = NULL
) {
  if (missing(model) || missing(species_list)) {
    stop("Both `model` and `species_list` must be provided.", call. = FALSE)
  }
  check_version(version)
  check_arg(is_string(backend), "backend", "a string")
  # Python does not expand `~`
  model <- path.expand(model)
  species_list <- path.expand(species_list)

  library <- resolve_library(backend, library)
  require_extra_for(backend, library, is_raven)

  args <- c(
    list(type, version, backend, model, species_list),
    list(precision = precision, check_validity = check_validity),
    compact_nulls(list(library = library, is_raven = is_raven))
  )
  py_model <- do.call(py_birdnet$load_custom, args)

  if (identical(version, "auto")) {
    version <- py_model$get_version()
  }

  obj <- construct_model_class(
    py_model = py_model,
    type = type,
    backend = backend,
    version = version,
    custom = TRUE,
    library = library,
    precision = precision,
    model_path = model,
    species_list_path = species_list
  )
  announce_model(obj)
}


#' @rdname birdnet_load
#' @export
birdnet_inspect_custom <- function(model, library = NULL) {
  model <- path.expand(model)
  library <- resolve_library("tf", library)
  require_extra_for("tf", library)
  info <- py_birdnet$inspect_custom_tflite(model, library = library)
  fields <- c(
    "version", "mode", "n_species",
    "applies_sigmoid", "supports_encoding", "input_samples"
  )
  out <- lapply(fields, function(f) info[[f]])
  names(out) <- fields
  out
}
