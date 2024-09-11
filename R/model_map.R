#' Create a model map based on version and base Python module
#'
#' This function returns a list of model constructors for a specific version and base Python module.
#'
#' @param version Character. The version of the model (e.g., "v2.4").
#' @param base_module Character. The base Python module path as a string (e.g., "py_birdnet_models").
#'
#' @keywords internal
#' @return A list of model constructors represented as strings, specific to the version and base module.
#' @examplesIf interactive()
#' py_birdnet_models <- reticulate::import("birdnet.models")
#' model_map <- create_model_map("v2.4", "py_birdnet_models")
create_model_map <- function(version, base_module) {
  switch(
    version,
    "v2.4" = list(
      "tflite_v2.4" = paste0(base_module, "$v2m4$AudioModelV2M4TFLite"),
      "protobuf_v2.4" = paste0(base_module, "$v2m4$AudioModelV2M4Protobuf"),
      "custom_v2.4" = paste0(base_module, "$v2m4$CustomAudioModelV2M4TFLite"),
      "raven_v2.4" = paste0(base_module, "$v2m4$CustomAudioModelV2M4Raven"),
      "meta_v2.4" = paste0(base_module, "$v2m4$MetaModelV2M4TFLite")
    ),
    stop("Unsupported version")
  )
}
