% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{is_valid_species_list}
\alias{is_valid_species_list}
\title{Check if an Object is a Valid Species List}
\usage{
is_valid_species_list(obj)
}
\arguments{
\item{obj}{The object to check. This can be either a character vector or a list.}
}
\value{
A logical value indicating whether the object is a valid species list:
\itemize{
\item \code{TRUE} if the object is a character vector of length > 0 or a list with each element being a single character string.
\item \code{FALSE} otherwise.
}
}
\description{
This internal function checks if an object is either a character vector of length greater than 0
or a list where each element is a single non-empty character string.
}
\note{
This function is intended for internal use and may not be exported or accessible for external users.
}
\examples{
\dontrun{
is_valid_species_list(c("species1", "species2")) # TRUE
is_valid_species_list(list("species1", "species2")) # TRUE
is_valid_species_list(c(1, 2, 3)) # FALSE
is_valid_species_list(list(a = 1, b = 2)) # FALSE
}
}
\keyword{internal}
