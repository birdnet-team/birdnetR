# Set up GPU support

Declares the Python packages BirdNET needs to run on a GPU. Call it once
at the top of a script, before Python starts (loading a model,
[`birdnet_sitrep()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_sitrep.md)
and the `birdnet_list_*()` functions that use Python all start it): the
packages are resolved when Python starts, so afterwards it is too late
and the function errors (restart R and call it first).

## Usage

``` r
birdnet_use_gpu(backend = c("pt", "pb"))
```

## Arguments

- backend:

  `"pt"` (PyTorch, default) or `"pb"` (TensorFlow).

## Value

Invisibly returns `TRUE`. If `RETICULATE_PYTHON` points at your own
Python environment, birdnetR cannot install anything there: the function
warns and returns `FALSE`.

## Details

Choose one backend per R session. TensorFlow (`"pb"`) and PyTorch
(`"pt"`) each bring their own CUDA libraries, and installing both can
conflict, so asking for the other backend later in the same session is
an error.

Requirements by platform:

- **Linux, `"pt"`** (default): installs `birdnet[pt]`. If the
  environment variable `UV_TORCH_BACKEND` is not set, it is set to
  `"auto"` so that uv picks the torch build matching your GPU driver.
  For AMD GPUs, set e.g. `Sys.setenv(UV_TORCH_BACKEND = "rocm7.2")`
  before calling `birdnet_use_gpu()` (ROCm support is experimental).

- **Linux, `"pb"`**: installs `birdnet[and-cuda]`. An NVIDIA driver and
  CUDA must already be installed on the system. TensorFlow 2.21.0 is
  left out, because it does not find the GPU.

- **macOS (Apple silicon), `"pb"`**: installs `birdnet[tf]` plus
  `tensorflow-metal`.

Any other combination (for example Windows) has no automatic setup and
errors;
[`vignette("gpu", package = "birdnetR")`](https://birdnet-team.github.io/birdnetR/dev/articles/gpu.md)
shows how to set up your own Python environment instead, and covers
everything else about GPUs.

Afterwards, load a model for the chosen backend with
`birdnet_load(backend = "pt")` (or `birdnet_load_perch(device = "GPU")`)
and use `device = "GPU"` in
[`birdnet_predict()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_predict.md)
and
[`birdnet_encode()`](https://birdnet-team.github.io/birdnetR/dev/reference/birdnet_encode.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# at the top of a script, before loading any model
birdnet_use_gpu("pt")
model <- birdnet_load("acoustic", "3.0", backend = "pt")
audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
pred <- birdnet_predict(model, audio_file, device = "GPU")

# AMD GPU (experimental)
Sys.setenv(UV_TORCH_BACKEND = "rocm7.2")
birdnet_use_gpu("pt")
} # }
```
