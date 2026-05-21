# Troubleshoot

## Long Pause After Prediction

If you notice a significant pause after BirdNET has finished processing
your audio file but before returning the results, this is likely due to
data conversion overhead between Python and R when calling
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). This is
particularly noticeable when:

- Processing long audio files (\>20 minutes)
- Using low confidence thresholds that generate many predictions
  (`min_confidence < 0.1`)
- Working with memory-constrained environments

### Solution: Use `write_predictions()`

For large prediction results, prefer
[`write_predictions()`](https://birdnet-team.github.io/birdnetR/dev/reference/write_predictions.md)
to write results directly from Python to a file (CSV, Parquet, or NumPy)
without crossing the R boundary. This avoids the memory overhead of
converting large result sets to R data frames.

``` r

model <- load_birdnet()
predictions <- predict(model, audio_path)

# Write directly from Python - no R conversion needed
write_predictions(predictions, "results.csv")
```

For tips on processing many files efficiently, see the [Get started with
birdnetR](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.md)
vignette.
