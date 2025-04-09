#' Convert a list of predictions from python to a data frame
#'
#' This function processes a list of predictions from the python `birdnet` package, each containing time intervals,
#' scientific names, common names, and confidence levels, and converts them into a structured data frame. It handles
#' cases where some elements in the list might be empty.
#'
#' @param predictions A list where each element is expected to be a named list. The names of the
#'   elements represent time intervals in the format "(start,end)", and each element contains
#'   another list where the names are of the form "scientificName_commonName" and values are
#'   confidence scores.
#' @param keep_empty A logical flag indicating whether to include empty elements as rows in the output
#'   data frame. If `TRUE`, empty elements are filled with `NA`. If `FALSE`, empty elements are excluded.
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`.
#'   Each row represents a single prediction.
#' @keywords internal
#' @importFrom stats complete.cases
predictions_to_df <- function(predictions, keep_empty = FALSE) {
  # Validate inputs
  if (!is.list(predictions)) {
    stop("The 'predictions' argument must be a list.")
  }
  if (!is.logical(keep_empty) || length(keep_empty) != 1) {
    stop("The 'keep_empty' argument must be a single logical value.")
  }

  # Pre-calculate total detections (inner list lengths)
  detection_counts <- vapply(predictions, function(pred) {
    n <- length(pred)
    if (n == 0L) {
      if (keep_empty) 1L else 0L
    } else {
      n
    }
  }, FUN.VALUE = integer(1))

  total_detections <- sum(detection_counts)

  # Pre-allocate vectors for time values, raw label strings, and confidence scores.
  starts      <- numeric(total_detections)
  ends        <- numeric(total_detections)
  labels_all  <- character(total_detections)
  confidences <- numeric(total_detections)

  idx <- 1L
  # Iterate over each time interval in predictions
  for (interval in names(predictions)) {
    preds <- predictions[[interval]]
    num_preds <- length(preds)

    if (num_preds == 0L) {
      if (!keep_empty) next
      # If there are no predictions and we want to keep empty entries,
      # insert a placeholder.
      preds <- list("NA_NA" = NA_real_)
      num_preds <- 1L
    }

    # Parse the time interval (e.g. "(0.0, 3.0)") into numeric start and end.
    time_vals <- as.numeric(strsplit(gsub("[()]", "", interval), ",")[[1]])
    if (length(time_vals) != 2L) {
      stop("Time interval '", interval, "' does not contain exactly two numeric values.")
    }

    # Store the labels as they are (e.g., "Poecile atricapillus_Black-capped Chickadee").
    current_labels <- names(preds)

    idx_range <- idx:(idx + num_preds - 1L)
    starts[idx_range]      <- time_vals[1]
    ends[idx_range]        <- time_vals[2]
    labels_all[idx_range]  <- current_labels
    confidences[idx_range] <- unlist(preds, use.names = FALSE)

    idx <- idx + num_preds
  }

  # Now, vectorized splitting of the full labels vector
  scientific_name <- sub("_.*", "", labels_all)
  common_name <- sub("^[^_]+_", "", labels_all)

  # Create a data frame using the collected time values, labels, and confidence scores.
  df <- data.frame(
    start = starts,
    end = ends,
    scientific_name = scientific_name,
    common_name = common_name,
    confidence = confidences,
    stringsAsFactors = FALSE
  )

  # conbvert NA strings to actual NA values
  na_rows <- df$scientific_name == "NA"
  df$scientific_name[na_rows] <- NA_character_
  df$common_name[na_rows] <- NA_character_

  # When not keeping empty predictions, remove rows with missing values.
  if (!keep_empty) {
    df <- df[complete.cases(df), , drop = FALSE]
  }

  df
}



#' Check if an Object is a Valid Species List
#'
#' This internal function checks if an object is either a character vector of length greater than 0
#' or a list where each element is a single non-empty character string.
#'
#' @param obj The object to check. This can be either a character vector or a list.
#' @return A logical value indicating whether the object is a valid species list:
#' \itemize{
#'   \item `TRUE` if the object is a character vector of length > 0 or a list with each element being a single character string.
#'   \item `FALSE` otherwise.
#' }
#' @keywords internal
#' @note This function is intended for internal use and may not be exported or accessible for external users.
#' @examples
#' birdnetR:::is_valid_species_list(c("species1", "species2")) # TRUE
#' birdnetR:::is_valid_species_list(list("species1", "species2")) # TRUE
#' birdnetR:::is_valid_species_list(c(1, 2, 3)) # FALSE
#' birdnetR:::is_valid_species_list(list(a = 1, b = 2)) # FALSE
#'
is_valid_species_list <- function(obj) {
  # Check if the object is a character vector of length > 0 and not a list
  is_vector <- is.vector(obj) &&
    length(obj) > 0 && !is.list(obj) && is.character(obj)

  # Check if the object is a non-empty list where each element is a single character string
  is_list_single_elements <- is.list(obj) &&
    length(obj) > 0 &&
    all(sapply(obj, function(x) {
      is.character(x) && length(x) == 1 && length(x) != 0
    }))

  # Return TRUE if either condition is met
  return(is_vector || is_list_single_elements)
}
