#' List the species of a loaded model
#'
#' Returns all classes a loaded model can predict, in model order. Works for
#' official, Perch and custom models. Use entries of this list for the
#' `species_list` argument of [birdnet_predict()].
#'
#' @param model A BirdNET model object, see [birdnet_load()].
#' @return A character vector of species names (`"<scientific>_<common>"` for
#'   BirdNET models).
#' @export
#' @examples
#' \dontrun{
#' model <- birdnet_load()
#' species <- birdnet_list_species(model)
#' head(species)
#' }
birdnet_list_species <- function(model) {
  if (!inherits(model, "birdnet_model")) {
    stop("`model` must be a BirdNET model object.")
  }
  # Convert OrderedSet to Python list first so reticulate returns a character
  # vector instead of the repr string.
  as.character(py_builtins$list(model$py_model$species_list))
}
