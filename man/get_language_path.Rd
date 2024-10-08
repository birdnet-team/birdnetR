% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/birdnet_interface.R
\name{get_language_path}
\alias{get_language_path}
\title{Helper function to retrieve the language path for a BirdNET model}
\usage{
get_language_path(model, language, downloader_key, subfolder)
}
\arguments{
\item{model}{A BirdNET model object containing the version information.}

\item{language}{Character. The language code for which to retrieve the path (e.g., "en_us").
Must be one of the available languages for the given model version.}

\item{downloader_key}{Character. The key in the module map that specifies the downloader
to use (e.g., "downloader_tflite", "downloader_protobuf").}

\item{subfolder}{Character. The subfolder in which the language files are stored (e.g., "TFLite", "Protobuf").}
}
\value{
A character string representing the path to the language file.
}
\description{
This function handles the common logic for retrieving the language path for a BirdNET model.
It validates the language, creates the necessary paths from the module map, and uses the appropriate
downloader to retrieve the path to the language file.
}
\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
model <- birdnet_model_tflite(version = "v2.4", language = "en_us")
language_path <- get_language_path(model, "en_us", "downloader_tflite", "TFLite")
\dontshow{\}) # examplesIf}
}
\keyword{internal}
