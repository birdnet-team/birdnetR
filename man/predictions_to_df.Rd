% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{predictions_to_df}
\alias{predictions_to_df}
\title{Convert a list of predictions from python to a data frame}
\usage{
predictions_to_df(predictions, keep_empty = FALSE)
}
\arguments{
\item{predictions}{A list where each element is expected to be a named list. The names of the
elements represent time intervals in the format "(start,end)", and each element contains
another list where the names are of the form "scientificName_commonName" and values are
confidence scores.}

\item{keep_empty}{A logical flag indicating whether to include empty elements as rows in the output
data frame. If \code{TRUE}, empty elements are filled with \code{NA}. If \code{FALSE}, empty elements are excluded.}
}
\value{
A data frame with columns: \code{start}, \code{end}, \code{scientific_name}, \code{common_name}, and \code{confidence}.
Each row represents a single prediction.
}
\description{
This function processes a list of predictions from the python \code{birdnet} package, each containing time intervals, scientific names,
common names, and confidence levels, and converts them into a structured data frame. It handles
cases where some elements in the list might be empty.
}
\keyword{internal}
