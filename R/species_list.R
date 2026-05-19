#' Get the species list from a loaded BirdNET model
#'
#' Returns the full species list from a loaded model as a character vector.
#' Works for both pretrained and custom models.
#'
#' @param model A BirdNET model object returned by [load_birdnet()] or [load_custom()].
#' @return A character vector of species names in model order.
#' @export
#' @examples
#' \dontrun{
#' model <- load_birdnet(type = "acoustic")
#' species <- get_species_list(model)
#' head(species)
#' }
get_species_list <- function(model) {
  if (!inherits(model, "birdnet_model")) {
    stop("`model` must be a BirdNET model object.")
  }
  # Convert OrderedSet to Python list first so reticulate returns a character
  # vector instead of the repr string.
  as.character(py_builtins$list(model$py_model$species_list))
}
