# Functions in relation to loading BirdNET models

#' Create a new BirdNET model object
#'
#' This function creates a new BirdNET model object by wrapping a Python model object and assigning
#' it a class and subclasses. The model is created as an R object that can be interacted with
#' using R's S3 method dispatch.
#'
#' @param py_model A Python object representing the BirdNET model
#' @param type Model type: "acoustic", "geo"
#' @param backend Backend type: "tf", "pb"
#' @param version Version of the model, e.g., "2.4"
#' @param custom Logical indicating if the model is a custom model
#' @param ... Additional arguments to be included in the model object
#'
#' @return An S3 object of class `birdnet_model` (and addtional subclass) containing the Python model object
#' and additional attributes.
#'
#' @noRd
construct_model_class <- function(
  py_model,
  type,
  backend,
  version,
  custom,
  ...
) {
  stopifnot(reticulate::is_py_object(py_model)) # Ensure that the input is a valid Python object

  cl <- c(
    paste0(
      "birdnet_model_",
      type,
      "_v",
      gsub("\\.", "_", version)
    ),
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
        model_version = version
      ),
      ...
    ),
    class = cl
  )
}

#' @title Load a BirdNET Model
#' @name load_birdnet_model
#' @description
#' Functions to load BirdNET models for sound identification or species prediction from location and time.
#' Models will be downloaded if not available locally.
#'
#' * [load_model()]: load a pre-trained BirdNET model or a geographic model.
#' * [load_custom()]: load a custom trained BirdNET model.
#'
#' @details
#'
#' The argument `type` specifies the type of model to load:
#' * `"acoustic"`: A model for species identification from audio recordings.
#' * `"geo"`: A model for species prediction based on geographic location and time.
#'
#' The argument `version` specifies the version of the model to load, e.g., `"2.4"`. Find all suported versions
#'
#' The argument `backend` specifies the backend to use:
#' * `"tf"`: TensorFlow backend, which supports different precisions and libraries but is CPU only.
#' * `"pb"`: Protobuf backend, which can be run on a GPU. TODO describe how to insall GPU backends.
#'
#' The argument `library` is only used for the TensorFlow backend and specifies the library to use:
#' * `"litert"`: The LiteRT library for running TensorFlow Lite models.
#' * `"tflite"`: The standard TensorFlow Lite library.
#'
#' The argument `precision` specifies the precision of the model:
#' * `"int8"`: 8-bit integer precision, which is the most efficient in terms of speed and memory usage.
#' * `"fp16"`: 16-bit floating point precision, which is a good balance between speed and accuracy.
#' * `"fp32"`: 32-bit floating point precision, which is the most accurate but also the slowest and most memory-intensive.
#' Protobuf and geographic models only support `"fp32"` precision.
#'
#' To get an overview of all valid model option combinations use [model_options()].
#'
#' @param type character. The type of model to load: `"acoustic"` or `"geo"`.
#' @param version character. The version of the model to load, e.g., `"2.4"`.
#' @param backend character. The backend to use: `"tf"` (TensorFlow) or `"pb"` (Protobuf).
#' @param library character or `NULL`. The TensorFlow library to use: `"litert"` or `"tflite"`. Only applies when `backend = "tf"`.
#' @param precision character. The precision of the model: `"int8"`, `"fp16"`, or `"fp32"`.
#'
#' @return A BirdNET model object, which is an S3 object of class `birdnet_model` and specific subclasses (e.g., `birdnet_model_acoustic_v2_4`, `birdnet_model_v2_4`). This object is a list containing:
#' \describe{
#'   \item{`py_model`}{The underlying Python BirdNET model object.}
#'   \item{`model_type`}{The type of the model, either "acoustic" or "geo".}
#'   \item{`model_version`}{The version string of the model (e.g., "v2.4").}
#'   \item{`precision`}{The precision of the model, e.g., "int8", "fp16", "fp32".}
#'   \item{...}{Additional elements specific to the model type:
#'     \itemize{
#'       \item \strong{For pretrained acoustic and geo models}:
#'         \itemize{
#'           \item `lang`: The language code used (e.g., "en_us").
#'           \item `library`: The library used for the model, if applicable.
#'         }
#'       \item \strong{For custom models}:
#'         \itemize{
#'           \item `model_path`: Path to custom model file (TensorFlow backend) or directory with model files (Protobuf backend).
#'           \item `species_list_path`: Path to the species list file.
#'         }
#'     }
#'   }
#' }
#'
#' @examples
#' # Load a pre-trained acoustic model
#' \dontrun{
#' model  <- load_model(type = "acoustic", version = "2.4", backend = "tf", precision = "int8")
#' }
NULL
#> NULL

#' @rdname load_birdnet_model
#' @param language character. Language code for the model to use e.g., "en_us".
#' Common species names are returned in the specified language if available. Use [available_languages()] to see all available languages.
#' @export
load_model <- function(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  language = "en_us"
) {
  args <- list(
    type,
    version,
    backend,
    precision = precision,
    lang = language
  )

  if (!is.null(library) && backend != "tf") {
    warning(sprintf(
      "Argument `library` = '%s' only applies if argument `backend = 'tf'`",
      library
    ))
  }

  if (!is.null(library) && backend == "tf") {
    args$library <- library
  }

  py_model <- do.call(py_birdnet$load, args)

  construct_model_class(
    py_model = py_model,
    type = type,
    backend = backend,
    version = version,
    custom = FALSE,
    # this excludes positional (unnamed) arguments and NULL values.
    args[names(args) != "" & sapply(args, Negate(is.null))]
  )
}


#' @rdname load_birdnet_model
#' @param model If backend is "tf", path to custom model file. If backend is "pb", path to model directory.
#' @param species_list Path to the species list file.
#' @param check_validity Checks if the model is loadable by loading the model twice.
#' @param classifier_type Advanced option for custom TensorFlow models. Controls how the custom classifier head is interpreted.
#' @param is_raven Advanced option for custom protobuf models. Indicates whether the model uses the Raven protobuf layout.
#' @export

load_custom <- function(
  type = "acoustic",
  version = "2.4",
  backend = "tf",
  library = NULL,
  precision = "fp32",
  model = NULL,
  species_list = NULL,
  check_validity = TRUE,
  classifier_type = NULL,
  is_raven = NULL
) {
  args <- list(
    type,
    version,
    backend,
    model,
    species_list,
    precision = precision,
    check_validity = check_validity
  )

  # Most of the arguments are validated in the Python function
  if (is.null(model) || is.null(species_list)) {
    stop("Both `model` and `species_list` must be provided.")
  }

  if (!is.null(library) && backend != "tf") {
    warning(sprintf(
      "Argument `library` = '%s' only applies if argument `backend = 'tf'`",
      library
    ))
  }

  if (!is.null(library) && backend == "tf") {
    args$library <- library
  }

  if (!is.null(classifier_type)) {
    args$classifier_type <- classifier_type
  }

  if (!is.null(is_raven)) {
    args$is_raven <- is_raven
  }

  py_model <- do.call(py_birdnet$load_custom, args)

  construct_model_class(
    py_model = py_model,
    type = type,
    backend = backend,
    version = version,
    custom = TRUE,
    model_path = model,
    species_list_path = species_list,
    # this excludes positional (unnamed) arguments and NULL values.
    args[names(args) != "" & sapply(args, Negate(is.null))]
  )
}
