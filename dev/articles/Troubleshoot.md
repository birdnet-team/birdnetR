# Troubleshoot

For problems with the Python setup, extra downloads or your own Python
environment, see [Installation and
setup](https://birdnet-team.github.io/birdnetR/dev/articles/installation.md).
For GPUs, see the
[GPU](https://birdnet-team.github.io/birdnetR/dev/articles/gpu.md)
article.

## Reporting a problem

[`birdnet_sitrep()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_sitrep.md)
shows which Python environment birdnetR uses:

``` r

birdnet_sitrep()
#> python_version: 3.12.14
#> python_executable: /home/user/.cache/uv/archive-v0/0MLD8yprGexELXHg/bin/python
#> birdnet_version: 1.5.0
#> runtimes: onnxruntime, ai_edge_litert
```

- `python_version`, `python_executable`: the Python that birdnetR runs
  on.
- `birdnet_version`: the version of the `birdnet` Python package.
- `runtimes`: the installed inference runtimes (any of `onnxruntime`,
  `ai_edge_litert` (LiteRT), `tensorflow` and `torch`).

Please include this output when you [report a
bug](https://github.com/birdnet-team/birdnetR/issues).

After birdnetR has installed TensorFlow or PyTorch during a session (see
[Extra
downloads](https://birdnet-team.github.io/birdnetR/dev/articles/installation.html#extra-downloads)),
`python_executable` points to a different folder than before. That is
expected: reticulate adds the new packages as an extra layer on top of
the existing environment.

## Long wait on the first load

The first load of a model can take several minutes without visible
progress: birdnetR is downloading Python packages, and for TensorFlow or
PyTorch that is 600 MB to several GB. See [Download
progress](https://birdnet-team.github.io/birdnetR/dev/articles/installation.html#download-progress).

## `as.data.frame()` is slow on large results

[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
keeps its results in Python.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) copies
them into R, which takes time and memory when there are many detections,
for example with many hours of audio, a low `min_confidence` or
`top_k = NULL`.

If you don’t need the results in R right away, write them to a file
instead.
[`birdnet_write()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_write.md)
writes CSV, Parquet or NumPy files straight from Python:

``` r

birdnet_write(predictions, "results.csv")
```

For tips on processing many files, see [Process many
files](https://birdnet-team.github.io/birdnetR/dev/articles/birdnetR.html#process-many-files).

## High memory or CPU use

[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
and
[`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)
start several worker processes, and each loads its own copy of the
model. On the CPU, birdnet starts one worker per physical core (fewer
when memory is short) and keeps all cores busy. Full CPU load during a
run is expected.

If memory runs out, or the computer becomes unresponsive, lower
`n_workers` and `batch_size`:

``` r

predictions <- birdnet_predict(model, files, n_workers = 2L, batch_size = 1L)
```

- `n_workers` is the number of model copies in memory. TensorFlow and
  PyTorch workers need more memory than ONNX Runtime ones.
- `batch_size` is the number of segments each worker processes at once.
  Larger values need more memory.

Fewer workers mainly save memory: birdnet gives each worker more CPU
threads, so the CPU stays busy. If a worker is killed because memory ran
out, birdnet stops with an error that names the worker.

With `device = "GPU"`, birdnetR starts one worker per GPU. A larger
`n_workers` puts another copy of the model on the GPU for each extra
worker; see [Workers and batch
size](https://birdnet-team.github.io/birdnetR/dev/articles/gpu.html#workers-and-batch-size).

## Parallel processing

Don’t run birdnetR inside `parallel` or `future` workers (for example
with
[`parallel::parLapply()`](https://rdrr.io/r/parallel/clusterApply.html),
`future.apply::future_lapply()` or `furrr`). Each worker is a fresh R
session without birdnetR’s Python setup, so birdnet does not work
reliably there (see
[\#56](https://github.com/birdnet-team/birdnetR/issues/56)).

[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
and
[`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md)
already run in parallel. Pass all files in one call and set the number
of parallel workers with `n_workers`:

``` r

predictions <- birdnet_predict(model, files, n_workers = 8L)
```

## Harmless console messages

- Decoding MP3 files (for example the bundled `soundscape.mp3`) can
  print libmpg123 errors such as `part2_3_length ... too large`. The
  results are not affected.
- TensorFlow prints CUDA or XLA log lines on computers without an NVIDIA
  GPU, for example `failed call to cuInit`. You can ignore them.
- uv prints `warning: The --torch-backend option is experimental` when
  it installs PyTorch for a GPU.
- With PyTorch, each worker prints a `FutureWarning` that
  `torch.jit.load` is deprecated.
- The ROCm build of PyTorch (AMD GPUs) prints
  `(null): No such file or directory`, in your system’s language, when
  it starts.
