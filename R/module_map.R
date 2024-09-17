#' Create a module map based on version and base Python module
#'
#' This function returns a list of model constructors and miscellaneous paths for a specific version and base Python module.
#'
#' @param version Character. The version of the module (e.g., "v2.4").
#' @param base_module Character. The base Python module path as a string (e.g., "py_birdnet_models").
#'
#' @keywords internal
#' @return A list containing 'models' (a list of model constructors) and 'misc' (a list of miscellaneous paths), specific to the version and base module.
#' @examplesIf interactive()
#' py_birdnet_models <- reticulate::import("birdnet.models")
#' module_map <- create_module_map("v2.4", "py_birdnet_models")
create_module_map <- function(version, base_module) {
  switch(version,
    "v2.4" = list(
      "models" = list(
        "tflite" = paste0(base_module, "$v2m4$AudioModelV2M4TFLite"),
        "protobuf" = paste0(base_module, "$v2m4$AudioModelV2M4Protobuf"),
        "custom" = paste0(base_module, "$v2m4$CustomAudioModelV2M4TFLite"),
        "raven" = paste0(base_module, "$v2m4$CustomAudioModelV2M4Raven"),
        "meta" = paste0(base_module, "$v2m4$MetaModelV2M4TFLite")
      ),
      "misc" = list(
        "available_languages" = paste0(base_module, "$v2m4$model_v2m4_base$AVAILABLE_LANGUAGES"),
        "version_app_data_folder" = paste0(base_module, "$v2m4$model_v2m4_base$get_internal_version_app_data_folder"),
        "downloader_tflite" = paste0(base_module, "$v2m4$model_v2m4_tflite$DownloaderTFLite"),
        "downloader_protobuf" = paste0(base_module, "$v2m4$model_v2m4_protobuf$DownloaderProtobuf"),
        "parser_custom_tflite" = paste0(base_module, "$v2m4$model_v2m4_tflite_custom$CustomTFLiteParser")
      )
    ),
    stop("Unsupported version")
  )
}

#' Get an element from a module map regardless of nesting level
#'
#' This function retrieves an element from a module map by traversing the nested structure.
#' It takes a variable number of arguments that represent the keys to navigate through the module map.
#'
#' @param module_map A list returned from \code{create_module_map()}.
#' @param ... A sequence of keys that represent the path to the desired element in the module map.
#'
#' @return The element located at the specified path within the module map.
#' @keywords internal
#' @examplesIf interactive()
#' module_map <- create_module_map("v2.4", "py_birdnet_models")
#' available_languages_path <- get_element_from_module_map(module_map, "misc", "available_languages")
get_element_from_module_map <- function(module_map, ...) {
  # Extract the nested keys
  keys <- list(...)

  # Start from the top-level module map
  element <- module_map

  # Traverse the nested structure using the provided keys
  for (key in keys) {
    if (!is.null(element[[key]])) {
      element <- element[[key]]
    } else {
      stop(paste("Element", key, "not found in the module map"))
    }
  }

  return(element)
}


#' Evaluate a Python path string and return the corresponding Python object
#'
#' This function takes a string representing a Python path (e.g., from \code{get_model_from_module_map()})
#' and evaluates it to return the corresponding Python object.
#'
#' @param path_string Character. The string representing the Python path (e.g., "py_birdnet_models$v2m4$AudioModelV2M4TFLite").
#'
#' @return The evaluated Python object or value.
#' @keywords internal
#' @examplesIf interactive()
#' py_birdnet_models <- reticulate::import("birdnet.models")
#' module_map <- create_module_map("v2.4", "py_birdnet_models")
#' model_string <- get_model_from_module_map(module_map, "tflite_v2.4")
#' model_object <- evaluate_python_path(model_string)
evaluate_python_path <- function(path_string) {
  tryCatch(
    eval(parse(text = path_string)),
    error = function(e) {
      stop("Failed to evaluate Python path: ", conditionMessage(e))
    }
  )
}
