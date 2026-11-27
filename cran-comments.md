## R CMD check results

0 errors | 0 warnings | 1 note

* Maintainer email changed from felix.guenther@informatik.tu-chemnitz.de to
  felix.gnthr@gmail.com. Same maintainer, new address. The old address still
  receives mail, so the change can be confirmed from it.

## Test environments

* local Ubuntu 26.04, R 4.5.2
* win-builder (devel): TODO
* mac-builder (release): TODO
* R-hub: TODO

## Submission notes

* birdnetR 1.0.0 is a major release with breaking changes. It wraps version
  1.5 of the Python `birdnet` package, and all functions have new names.
  NEWS.md maps the old names to the new ones.
* There are no reverse dependencies on CRAN.
* As in 0.3.2, most examples are wrapped in `\dontrun{}`: they need the
  `birdnet` Python package and download model files. The package installs
  its Python dependencies on demand with `reticulate::py_require()`.
