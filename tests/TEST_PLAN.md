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
- Are skipped when not in a full test environment

## Running Tests

### Standard Test Run
```r
devtools::test()
```
This runs all tests, but integration tests are skipped if not in a full test environment.

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

The function `is_full_test_env()` in `test_testing_environment.R` determines whether the environment supports integration tests by checking:
1. BirdNET Python package is available
2. Internet connection is available
3. Optional: explicit environment flag is set
