# Testing Plan for birdnetR

## Test Types

### Unit Tests
Files with prefix `test-unit-*` contain tests that:
- Don't require the Python BirdNET package
- Use mocking when needed
- Run quickly without downloading models

### Integration Tests  
Files with prefix `test-integration-*` contain tests that:
- Require the full Python BirdNET package
- May download and initialize real models
- Are skipped unless `BIRDNETR_RUN_INTEGRATION_TESTS` is `"true"`

## Running Tests

### Standard Test Run
```r
devtools::test()
```
This runs all tests; integration tests are skipped unless the environment variable below is set.

### Unit Tests Only
```r
devtools::test(filter = "^unit")
```

### Integration Tests
```r
Sys.setenv(BIRDNETR_RUN_INTEGRATION_TESTS = "true")
devtools::test(filter = "^integration") 
```

## Test Environment Detection

`is_full_test_env()` in `tests/testthat/helper-test-env.R` is `TRUE` when
`BIRDNETR_RUN_INTEGRATION_TESTS` is set to `"true"`. Nothing else is checked:
once the variable is set, a missing Python environment, a failed download or a
model that does not load fails the tests instead of skipping them.

The custom-classifier test needs `dev/rc_20240214/`, which is not part of the
built package. It runs with `devtools::test()` in a source checkout and skips
under `R CMD check`.
