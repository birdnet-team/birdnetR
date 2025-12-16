#' Collapse and compact model options data frame (internal)
#'
#' Groups and collapses specified columns of a model options data frame, combining all unique values in
#' \code{collapse_cols} for each group into a single string, separated by colons.
#'
#' @param opts_df A data frame of model options (as returned by \code{model_options()}).
#' @param collapse_cols Character vector of column names to collapse (default: \code{c("precision", "library")}).
#' @param na_string String to use for replacing \code{NA} values during grouping (default: \code{"<NA>"}).
#'
#' @return A compacted data frame, grouped by all columns except those listed in \code{collapse_cols}, with collapsed columns as colon-separated strings.
#' @noRd
format_model_options <- function(
  opts_df,
  collapse_cols = c("precision", "library"),
  na_string = "<NA>"
) {
  # Replace NA with a string for grouping/collapsing
  for (col in names(opts_df)) {
    opts_df[[col]] <- as.character(opts_df[[col]])
    opts_df[[col]][is.na(opts_df[[col]])] <- na_string
  }
  group_cols <- setdiff(names(opts_df), collapse_cols)
  agg_fun <- function(x) paste(sort(unique(na.omit(x))), collapse = ":")
  result <- aggregate(
    opts_df[[collapse_cols[1]]],
    by = opts_df[group_cols],
    FUN = agg_fun
  )
  names(result)[ncol(result)] <- collapse_cols[1]
  if (length(collapse_cols) > 1) {
    for (cc in collapse_cols[-1]) {
      temp <- aggregate(
        opts_df[[cc]],
        by = opts_df[group_cols],
        FUN = agg_fun
      )
      names(temp)[ncol(temp)] <- cc
      result <- merge(result, temp, by = group_cols, all = TRUE, sort = FALSE)
    }
  }
  for (col in c(group_cols, collapse_cols)) {
    result[[col]][result[[col]] == na_string] <- NA
  }
  # Sort by all columns (except collapse_cols at the end)
  sort_cols <- group_cols
  result <- result[do.call(order, result[sort_cols]), , drop = FALSE]
  result
}


#' List available BirdNET model options
#'
#' Returns a data frame of valid combinations of model types, versions, backends, libraries, and precisions
#' supported by the underlying BirdNET Python backend. Use this to explore which model settings are available
#' for use in \code{load_model()} and related functions.
#'
#' @param compact Logical. If \code{TRUE}, returns a compacted version of the options table.
#'
#' @return A data frame of valid model option combinations. Each row represents a supported configuration.
#' @details
#' Not all combinations of arguments are valid. For example, the \code{library} argument is only relevant for TensorFlow backends,
#' and some backends or model types only support specific precisions. Use the output to guide valid choices for loading models.
#'
#' @examples
#' model_options()                     # Show all supported combinations
#' model_options(compact = TRUE)       # Show compacted version
#' @export
model_options <- function(
  compact = FALSE
) {
  # Extract valid options from Python
  valid_model_types <- py_birdnet_globals$VALID_MODEL_TYPES
  valid_model_versions_acoustic <- py_birdnet_globals$VALID_ACOUSTIC_MODEL_VERSIONS
  valid_model_versions_geo <- py_birdnet_globals$VALID_GEO_MODEL_VERSIONS
  valid_model_backends <- py_birdnet_globals$VALID_MODEL_BACKENDS
  valid_library_types <- py_birdnet_globals$VALID_LIBRARY_TYPES
  valid_precisions <- py_birdnet_globals$VALID_MODEL_PRECISIONS

  # Build grid for each type with the right versions
  grid_acoustic <- expand.grid(
    type = "acoustic",
    version = valid_model_versions_acoustic,
    backend = valid_model_backends,
    library = valid_library_types,
    precision = valid_precisions,
    stringsAsFactors = FALSE
  )
  grid_geo <- expand.grid(
    type = "geo",
    version = valid_model_versions_geo,
    backend = valid_model_backends,
    library = valid_library_types,
    precision = valid_precisions,
    stringsAsFactors = FALSE
  )

  grid <- rbind(grid_acoustic, grid_geo)

  # Prune: library is only for backend == "tf"
  grid$library[grid$backend != "tf"] <- NA

  # Prune: pb/geo only supports precision fp32
  grid$precision[
    (grid$backend == "pb" | grid$type == "geo")
  ] <- py_birdnet_globals$MODEL_PRECISION_FP32

  # Remove rows with NA in library or precision (where not allowed)
  grid <- grid[
    is.na(grid$precision) |
      grid$precision == py_birdnet_globals$MODEL_PRECISION_FP32 |
      grid$backend == "tf",
  ]
  grid <- grid[order(grid$type, grid$version, grid$backend), ]
  grid <- unique(grid)

  if (compact) {
    grid <- format_model_options(grid)
  }
  grid
}


#' List available BirdNET model languages
#'
#' Returns a character vector of supported language codes for BirdNET models, as provided by the Python backend.
#'
#' @return Character vector of supported language codes (e.g., \code{"en_us"}, \code{"de"}, \code{"es"}).
#' @examples
#' available_languages()
#' @export
available_languages <- function() {
  py_birdnet_globals$VALID_MODEL_LANGUAGES
}
