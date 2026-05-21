# Get the top prediction by confidence within time intervals

This convenience function retrieves the row(s) with the highest
confidence value within each time interval. It can also limit the
results to a specific time interval if specified.

## Usage

``` r
get_top_prediction(data, filter = NULL)
```

## Arguments

- data:

  A data frame with columns 'start', 'end', 'scientific_name',
  'common_name', and 'confidence'. This data frame is typically the
  output from `predictions_to_df`.

- filter:

  A list containing 'start' and 'end' values to filter the data before
  calculation. If `NULL`, the function processes all time intervals.

## Value

A data frame containing the rows with the highest confidence per group
or for the specified interval.

## Examples

``` r
# Example data
data <- data.frame(
  start = c(0, 0, 1, 1, 2, 2),
  end = c(1, 1, 2, 2, 3, 3),
  scientific_name = c(
    "Species A",
    "Species B",
    "Species A",
    "Species B",
    "Species A",
    "Species B"
  ),
  common_name = c(
    "Common A",
    "Common B",
    "Common A",
    "Common B",
    "Common A",
    "Common B"
  ),
  confidence = c(0.1, 0.2, 0.5, 0.3, 0.7, 0.8)
)
data
#>   start end scientific_name common_name confidence
#> 1     0   1       Species A    Common A        0.1
#> 2     0   1       Species B    Common B        0.2
#> 3     1   2       Species A    Common A        0.5
#> 4     1   2       Species B    Common B        0.3
#> 5     2   3       Species A    Common A        0.7
#> 6     2   3       Species B    Common B        0.8

# Get top prediction for each time interval
get_top_prediction(data)
#>   start end scientific_name common_name confidence
#> 1     0   1       Species B    Common B        0.2
#> 2     1   2       Species A    Common A        0.5
#> 3     2   3       Species B    Common B        0.8

# Get top prediction for a specific time interval
get_top_prediction(data, filter = list(start = 1, end = 2))
#>   start end scientific_name common_name confidence
#> 1     1   2       Species A    Common A        0.5

# The same thing can be done using dplyr
if (FALSE) { # \dontrun{
 data |>
    dplyr::group_by(start, end) |>
    dplyr::slice_max(order_by = confidence)
} # }

```
