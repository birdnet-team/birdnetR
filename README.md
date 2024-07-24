# BirdNET-R
This will include diffrent analytics functions and packages for using BirdNET in R as standalone.

## Dev setup

run in R console:

```
install.packages("reticulate")

library(reticulate)
reticulate::virtualenv_create("r-reticulate")
reticulate::virtualenv_install("r-reticulate", packages = "birdnet")
reticulate::use_virtualenv("r-reticulate", required = TRUE)
```


run for docs:

```
usethis::use_roxygen_md()
devtools::document()
```
