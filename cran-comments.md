## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Resubmission
This is a resubmission. In this version I have:
- Fixed the issue with the `keras` Python package writting to the user home directory.
  The packag now uses `tools::R_user_dir()` to set the environemntal variable 'KERAS_HOME'.
  The package now depends on R >= 4.0
