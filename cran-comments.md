## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Resubmission 0.3.2
* **Missing Rd-Tags:**
  all exported functions document their return value.
* **Examples for unexported function:**
  internal functions use the `@noRd` tag. The use of tripple colons (`foo:::function`) in `@examples` was omitted. 
* **Please do not install packages in your functions, examples or vignette:**
  Function examples that would install additional software are wrapped in `\dontrun{}` as recommended in
  [CRAN Cookbook](https://contributor.r-project.org/cran-cookbook/general_issues.html).
  This applies to most examples because this package is a wrapper around the `birdnet` Python package.
  Here we use `reticulate::py_require()` (the recommended approach) to install the `birdnet` Python package in a virtual environment.
  Because this happens on demand, any interaction either installs the Python packag plus its dependencies, or downloads the 
  BirdNET model.

## Resubmission 0.3.1
This is a resubmission. In this version I have:
- Fixed the issue with the `keras` Python package writting to the user home directory.
  The packag now uses `tools::R_user_dir()` to set the environemntal variable 'KERAS_HOME'.
  The package now depends on R >= 4.0
