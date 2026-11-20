#' Collapse and compact model configurations data frame (internal)
#'
#' Groups and collapses specified columns of a model configurations data frame, combining all unique values in
#' \code{collapse_cols} for each group into a single string, separated by colons.
#'
#' @param opts_df A data frame of model configurations (as returned by \code{birdnet_list_models()}).
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


#' List the available BirdNET models
#'
#' Returns every model combination the installed `birdnet` Python package can
#' load: model type, version, backend, TFLite library and precision. Use it to
#' pick arguments for [birdnet_load()].
#'
#' @param compact logical. If `TRUE`, precisions and libraries of otherwise
#'   identical rows are collapsed into one colon-separated string.
#'
#' @return A data frame with columns `type`, `version`, `backend`, `library`,
#'   `precision` and `needs`. `needs` tells what a model requires on top of the
#'   default installation:
#'   * `"base"`: nothing, it runs out of the box.
#'   * `"tf"`: TensorFlow (`birdnet[tf]`), installed automatically on first use.
#'   * `"pt"`: PyTorch (`birdnet[pt]`), installed automatically on first use.
#'   * `"tf (2.18-2.19)"`: TensorFlow 2.18 or 2.19 (geo 3.0 on `tf`). The automatic
#'     install picks the newest TensorFlow, so this combination needs a
#'     Python environment you manage yourself.
#'
#' The `perch_v2` row is loaded with [birdnet_load_perch()], all other rows
#' with [birdnet_load()].
#' @importFrom stats aggregate na.omit
#' @examples
#' \dontrun{
#' birdnet_list_models()
#' birdnet_list_models(compact = TRUE)
#' }
#' @export
birdnet_list_models <- function(compact = FALSE) {
  rows <- as.data.frame(
    get_df_helper()$official_model_rows(),
    stringsAsFactors = FALSE
  )

  is_tf <- rows$backend == "tf"
  is_geo_30 <- rows$type == "geo" & rows$version == "3.0"
  # tf rows run on the TFLite interpreter (needs TensorFlow) or on LiteRT
  # (default installation); upstream refuses LiteRT for geo 3.0.
  litert <- rows[is_tf & !is_geo_30, , drop = FALSE]
  litert$library <- rep("litert", nrow(litert))
  rows$library <- ifelse(is_tf, "tflite", NA_character_)

  perch <- data.frame(
    type = "acoustic", version = "perch_v2", backend = "pb",
    precision = "fp32", library = NA_character_
  )
  grid <- rbind(rows, litert, perch)

  grid$needs <- ifelse(
    grid$backend == "onnx" | grid$library %in% "litert", "base",
    ifelse(
      grid$backend == "pt", "pt",
      ifelse(
        grid$type == "geo" & grid$version == "3.0" & grid$backend == "tf",
        "tf (2.18-2.19)",
        "tf"
      )
    )
  )

  grid <- grid[c("type", "version", "backend", "library", "precision", "needs")]
  grid <- grid[
    order(grid$type, grid$version, grid$backend, grid$library, grid$precision),
  ]
  rownames(grid) <- NULL

  if (compact) {
    grid <- format_model_options(grid)
  }
  grid
}


#' List the languages of a BirdNET model version
#'
#' Common species names are available in these languages. Pass one of them as
#' `language` to [birdnet_load()].
#'
#' @param version character. `"3.0"` (default) or `"2.4"`. The two versions
#'   support different languages.
#' @return Character vector of language codes (e.g. `"en_us"`, `"de"`).
#' @examples
#' \dontrun{
#' birdnet_list_languages()
#' birdnet_list_languages("2.4")
#' }
#' @export
birdnet_list_languages <- function(version = "3.0") {
  check_version(version)
  switch(
    version,
    "3.0" = py_birdnet_globals$VALID_MODEL_LANGUAGES_V3_0,
    "2.4" = py_birdnet_globals$VALID_MODEL_LANGUAGES_V2_4,
    stop(
      "`version` must be \"3.0\" or \"2.4\", not \"", version, "\".",
      call. = FALSE
    )
  )
}
