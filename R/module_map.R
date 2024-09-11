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
        "tflite_v2.4" = paste0(base_module, "$v2m4$AudioModelV2M4TFLite"),
        "protobuf_v2.4" = paste0(base_module, "$v2m4$AudioModelV2M4Protobuf"),
        "custom_v2.4" = paste0(base_module, "$v2m4$CustomAudioModelV2M4TFLite"),
        "raven_v2.4" = paste0(base_module, "$v2m4$CustomAudioModelV2M4Raven"),
        "meta_v2.4" = paste0(base_module, "$v2m4$MetaModelV2M4TFLite")
      ),
      "misc" = list(
        "available_languages_v2.4" = paste0(base_module, "$v2m4$model_v2m4_base$AVAILABLE_LANGUAGES")
      )
    ),
    stop("Unsupported version")
  )
}


#' Get a model constructor from the module map
#'
#' This function extracts the model constructor from the module map.
#'
#' @param module_map A list returned from \code{create_module_map()}.
#' @param model_name Character. The name of the model to retrieve (e.g., "tflite_v2.4").
#'
#' @return A string representing the Python path to the model constructor.
#' @keywords internal
#' @examplesIf interactive()
#' module_map <- create_module_map("v2.4", "py_birdnet_models")
#' tflite_model_path <- get_model_from_module_map(module_map, "tflite_v2.4")
get_model_from_module_map <- function(module_map, model_name) {
  models <- module_map$models

  if (!model_name %in% names(models)) {
    stop("Invalid model name. Available models are: ", paste(names(models), collapse = ", "))
  }

  return(models[[model_name]])
}



#' Get miscellaneous information from the module map
#'
#' This function extracts miscellaneous information (e.g., available languages) from the module map.
#'
#' @param module_map A list returned from \code{create_module_map()}.
#' @param misc_name Character. The name of the miscellaneous information to retrieve (e.g., "available_languages_v2.4").
#'
#' @return A string representing the Python path to the miscellaneous information.
#' @keywords internal
#' @examplesIf interactive()
#' module_map <- create_module_map("v2.4", "py_birdnet_models")
#' available_languages_path <- get_misc_from_module_map(module_map, "available_languages_v2.4")
get_misc_from_module_map <- function(module_map, misc_name) {
  misc <- module_map$misc

  if (!misc_name %in% names(misc)) {
    stop("Invalid misc name. Available misc items are: ", paste(names(misc), collapse = ", "))
  }

  return(misc[[misc_name]])
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
