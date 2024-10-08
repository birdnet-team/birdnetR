% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/module_map.R
\name{get_element_from_module_map}
\alias{get_element_from_module_map}
\title{Get an element from a module map regardless of nesting level}
\usage{
get_element_from_module_map(module_map, ...)
}
\arguments{
\item{module_map}{A list returned from \code{create_module_map()}.}

\item{...}{A sequence of keys that represent the path to the desired element in the module map.}
}
\value{
The element located at the specified path within the module map.
}
\description{
This function retrieves an element from a module map by traversing the nested structure.
It takes a variable number of arguments that represent the keys to navigate through the module map.
}
\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
module_map <- create_module_map("v2.4", "py_birdnet_models")
available_languages_path <- get_element_from_module_map(module_map, "misc", "available_languages")
\dontshow{\}) # examplesIf}
}
\keyword{internal}
