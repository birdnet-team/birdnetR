# Load message and print method for model objects.

# One-line description of a loaded model, e.g.
# "BirdNET acoustic 3.0 \u00b7 onnx \u00b7 fp32 \u00b7 en_us \u00b7 11,725 classes"
model_description <- function(model) {
  runtime <- paste(c(model$backend, model$library), collapse = "/")
  classes <- paste(format(model$py_model$n_species, big.mark = ","), "classes")
  parts <- if (inherits(model, "birdnet_model_perch")) {
    c("Perch v2", runtime, model$device, classes)
  } else {
    label <- if (isTRUE(model$custom)) "Custom" else "BirdNET"
    c(
      paste(label, model$model_type, model$model_version),
      runtime, model$precision, model$language, classes
    )
  }
  paste(parts, collapse = " \u00b7 ")
}


# Tell the user which model was loaded.
announce_model <- function(model) {
  message(model_description(model))
  invisible(model)
}


#' Print a BirdNET model
#'
#' Prints a one-line description of a loaded model: model, version, backend,
#' precision, language and number of classes.
#'
#' @param x A BirdNET model object, see [birdnet_load()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' print(model)
#' }
#' @export
print.birdnet_model <- function(x, ...) {
  cat(model_description(x), "\n", sep = "")
  invisible(x)
}
