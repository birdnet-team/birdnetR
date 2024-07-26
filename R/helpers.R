#' This file contains helper functions used to process and manage data returned
#' from other functions. These functions are exported and available for user access.



#' Get the top prediction by confidence within time intervals
#'
#' This convenience function retrieves the row(s) with the highest confidence value within each time interval.
#' It can also limit the results to a specific time interval if specified.
#'
#' @param data A data frame with columns 'start', 'end', 'scientific_name', 'common_name', and 'confidence'.
#'             This data frame is typically the output from `predictions_to_df`.
#' @param filter A list containing 'start' and 'end' values to filter the data before calculation.
#'               If `NULL`, the function processes all time intervals.
#' @return A data frame containing the rows with the highest confidence per group or for the specified interval.
#' @examples
#' # Example data
#' data <- data.frame(
#'   start = c(0, 0, 1, 1, 2, 2),
#'   end = c(1, 1, 2, 2, 3, 3),
#'   scientific_name = c(
#'     "Species A",
#'     "Species B",
#'     "Species A",
#'     "Species B",
#'     "Species A",
#'     "Species B"
#'   ),
#'   common_name = c(
#'     "Common A",
#'     "Common B",
#'     "Common A",
#'     "Common B",
#'     "Common A",
#'     "Common B"
#'   ),
#'   confidence = c(0.1, 0.2, 0.5, 0.3, 0.7, 0.8)
#' )
#' # Get top prediction for each time interval
#' get_top_prediction(data)
#'
#' # Get top prediction for a specific time interval
#' get_top_prediction(data, filter = list(start = 1, end = 2))
#'
#' # The same thing can be done using dplyr
#' data |>
#'   group_by(start, end) |>
#'   slice_max(order_by = confidence)
#'
#' @export
get_top_prediction <- function(data, filter = NULL) {
  # Validate input
  if (!is.data.frame(data)) {
    stop("The 'data' argument must be a data frame.")
  }
  required_columns <- c("start",
                        "end",
                        "scientific_name",
                        "common_name",
                        "confidence")
  if (!all(required_columns %in% names(data))) {
    stop(paste(
      "Data frame must contain the following columns:",
      paste(required_columns, collapse = ", ")
    ))
  }
  if (!is.null(filter) &&
      (!is.list(filter) || !all(c("start", "end") %in% names(filter)))) {
    stop("The 'filter' must be a list containing 'start' and 'end'.")
  }

  # Function to find the row with the maximum confidence value
  find_max_confidence <- function(df) {
    df[which.max(df$confidence), ]
  }

  if (!is.null(filter)) {
    # Apply the filter condition if specified
    data <- data[data$start == filter$start &
                   data$end == filter$end, ]
  }

  # Split data by start and end columns to find the max confidence in each interval
  split_data <- split(data, list(data$start, data$end))
  result <- do.call(rbind, lapply(split_data, find_max_confidence))

  # Reset row names for clarity
  rownames(result) <- NULL
  return(result)
}
