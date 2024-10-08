% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/module_map.R
\name{create_module_map}
\alias{create_module_map}
\title{Create a module map based on version and base Python module}
\usage{
create_module_map(version, base_module)
}
\arguments{
\item{version}{Character. The version of the module (e.g., "v2.4").}

\item{base_module}{Character. The base Python module path as a string (e.g., "py_birdnet_models").}
}
\value{
A list containing 'models' (a list of model constructors) and 'misc' (a list of miscellaneous paths), specific to the version and base module.
}
\description{
This function returns a list of model constructors and miscellaneous paths for a specific version and base Python module.
}
\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
py_birdnet_models <- reticulate::import("birdnet.models")
module_map <- create_module_map("v2.4", "py_birdnet_models")
\dontshow{\}) # examplesIf}
}
\keyword{internal}
