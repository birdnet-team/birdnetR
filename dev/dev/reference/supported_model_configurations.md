# List supported BirdNET model configurations

Returns a data frame of valid combinations of model types, versions,
backends, libraries, and precisions supported by the underlying BirdNET
Python backend. Use this to explore which model settings are available
for use in
[`load_birdnet()`](https://birdnet-team.github.io/birdnetR/dev/reference/load_birdnet_model.md)
and related functions.

## Usage

``` r
supported_model_configurations(compact = FALSE)
```

## Arguments

- compact:

  Logical. If `TRUE`, returns a compacted version of the configurations
  table.

## Value

A data frame of valid model configuration combinations. Each row
represents a supported configuration.

## Details

Not all combinations of arguments are valid. For example, the `library`
argument is only relevant for TensorFlow backends, and some backends or
model types only support specific precisions. Use the output to guide
valid choices for loading models.

## Examples

``` r
supported_model_configurations()                     # Show all supported combinations
#>        type version backend library precision
#> 2  acoustic     2.4      pb    <NA>      fp32
#> 1  acoustic     2.4      tf  tflite      int8
#> 3  acoustic     2.4      tf  litert      int8
#> 5  acoustic     2.4      tf  tflite      fp16
#> 7  acoustic     2.4      tf  litert      fp16
#> 9  acoustic     2.4      tf  tflite      fp32
#> 11 acoustic     2.4      tf  litert      fp32
#> 14      geo     2.4      pb    <NA>      fp32
#> 13      geo     2.4      tf  tflite      fp32
#> 15      geo     2.4      tf  litert      fp32
supported_model_configurations(compact = TRUE)       # Show compacted version
#>       type version backend      precision       library
#> 1 acoustic     2.4      pb           fp32          <NA>
#> 3 acoustic     2.4      tf fp16:fp32:int8 litert:tflite
#> 2      geo     2.4      pb           fp32          <NA>
#> 4      geo     2.4      tf           fp32 litert:tflite
```
