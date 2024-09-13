#' Convert a list of predictions from python to a data frame
#'
#' This function processes a list of predictions from the python `birdnet` package, each containing time intervals, scientific names,
#' common names, and confidence levels, and converts them into a structured data frame. It handles
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
predictions_to_df <- function(predictions, keep_empty = FALSE) {
  # Validate input types
  if (!is.list(predictions)) {
    stop("The 'predictions' argument must be a list.")
  }

  if (!is.logical(keep_empty)) {
    stop("The 'keep_empty' argument must be a logical value.")
  }

  list_of_dfs <- lapply(seq_along(predictions), function(i) {
    # Check if the current prediction is empty
    if (length(predictions[i][[1]]) == 0) {
      if (keep_empty) {
        # Fill empty elements with NA if keep_empty is TRUE
        predictions[i][[1]] <- list("NA_NA" = NA_real_)
      } else {
        return() # Skip this element if keep_empty is FALSE
      }
    }
    # Convert the current prediction element to a data frame
    predictions_list_element_to_df(predictions[i])
  })

  # Combine all individual data frames into one
  do.call(rbind, list_of_dfs)
}

#' Convert a single prediction element to a data frame
#'
#' This helper function takes a single list element from the predictions list and parses it into
#' a data frame format, extracting the time interval, scientific name, common name, and confidence level.
#'
#' @param x A single list element from the predictions list. It is expected to be a named list
#'   with one or more elements where the names represent labels "scientificName_commonName" and
#'   the values are confidence scores.
#' @return A data frame with columns: `start`, `end`, `scientific_name`, `common_name`, and `confidence`.
#' @keywords internal
predictions_list_element_to_df <- function(x) {
  # Ensure the element has expected structure
  if (!is.list(x) || length(x) == 0 || !is.character(names(x))) {
    stop("Each element in the 'predictions' list should be a named list.")
  }

  # Extract and parse the time interval from the element's name
  time_interval_str <- names(x)
  time_interval_vec <- as.numeric(unlist(strsplit(
    gsub("[()]", "", time_interval_str), ","
  )))

  # Ensure the time interval is correctly parsed
  if (length(time_interval_vec) != 2) {
    stop("Time interval parsing failed; expected two numeric values.")
  }

  # Create a data frame for each label within the time interval
  do.call(rbind, lapply(names(x[[1]]), function(label) {
    labels <- strsplit(label, "_")[[1]]

    # Ensure labels are correctly parsed
    if (length(labels) != 2) {
      stop("Label parsing failed; expected two values separated by an underscore.")
    }

    # Extract confidence score
    confidence_score <- x[[1]][[label]]

    # Create a data frame row for each entry
    data.frame(
      start = time_interval_vec[1],
      end = time_interval_vec[2],
      scientific_name = labels[1],
      common_name = labels[2],
      confidence = confidence_score
    )
  }))
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
#' \dontrun{
#' is_valid_species_list(c("species1", "species2")) # TRUE
#' is_valid_species_list(list("species1", "species2")) # TRUE
#' is_valid_species_list(c(1, 2, 3)) # FALSE
#' is_valid_species_list(list(a = 1, b = 2)) # FALSE
#' }
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
