#' Set up GPU support
#'
#' Declares the Python packages BirdNET needs to run on a GPU. Call it once at
#' the top of a script, before Python starts (loading a model, [birdnet_sitrep()]
#' and the `birdnet_list_*()` functions that use Python all start it): the
#' packages are resolved when Python starts, so afterwards it is too late and
#' the function errors (restart R and call it first).
#'
#' Choose one backend per R session. TensorFlow (`"pb"`) and PyTorch (`"pt"`)
#' each bring their own CUDA libraries, and installing both can conflict, so
#' asking for the other backend later in the same session is an error.
#'
#' Requirements by platform:
#' * **Linux, `"pt"`** (default): installs `birdnet[pt]`. If the environment
#'   variable `UV_TORCH_BACKEND` is not set, it is set to `"auto"` so that uv
#'   picks the torch build matching your GPU driver. For AMD GPUs, set e.g.
#'   `Sys.setenv(UV_TORCH_BACKEND = "rocm7.2")` before calling
#'   `birdnet_use_gpu()` (ROCm support is experimental).
#' * **Linux, `"pb"`**: installs `birdnet[and-cuda]`. An NVIDIA driver and CUDA
#'   must already be installed on the system. TensorFlow 2.21.0 is left out,
#'   because it does not find the GPU.
#' * **macOS (Apple silicon), `"pb"`**: installs `birdnet[tf]` plus
#'   `tensorflow-metal`.
#'
#' Any other combination (for example Windows) has no automatic setup and
#' errors; `vignette("gpu", package = "birdnetR")` shows how to set up your own
#' Python environment instead, and covers everything else about GPUs.
#'
#' Afterwards, load a model for the chosen backend with
#' `birdnet_load(backend = "pt")` (or `birdnet_load_perch(device = "GPU")`) and
#' use `device = "GPU"` in [birdnet_predict()] and [birdnet_encode()].
#'
#' @param backend `"pt"` (PyTorch, default) or `"pb"` (TensorFlow).
#' @return Invisibly returns `TRUE`. If `RETICULATE_PYTHON` points at your own
#'   Python environment, birdnetR cannot install anything there: the function
#'   warns and returns `FALSE`.
#' @examples
#' \dontrun{
#' # at the top of a script, before loading any model
#' birdnet_use_gpu("pt")
#' model <- birdnet_load("acoustic", "3.0", backend = "pt")
#' audio_file <- system.file("extdata", "soundscape.mp3", package = "birdnetR")
#' pred <- birdnet_predict(model, audio_file, device = "GPU")
#'
#' # AMD GPU (experimental)
#' Sys.setenv(UV_TORCH_BACKEND = "rocm7.2")
#' birdnet_use_gpu("pt")
#' }
#' @export
birdnet_use_gpu <- function(backend = c("pt", "pb")) {
  backend <- match.arg(backend)

  if (Sys.getenv("RETICULATE_PYTHON") != "managed") {
    warning(
      "`RETICULATE_PYTHON` points at your own Python environment, so ",
      "birdnet_use_gpu() cannot install the GPU packages. ",
      "Install them there yourself; see vignette('gpu', package = 'birdnetR').",
      call. = FALSE
    )
    return(invisible(FALSE))
  }

  if (reticulate::py_available()) {
    stop(
      "birdnet_use_gpu() must be called before Python starts ",
      "(before loading a model or calling other birdnetR functions that use Python). ",
      "Restart R and call it first.",
      call. = FALSE
    )
  }

  if (!is.null(.gpu$backend) && .gpu$backend != backend) {
    stop(
      "birdnet_use_gpu(\"", .gpu$backend, "\") was already called in this R ",
      "session. Only one GPU backend can be set up per session; restart R to ",
      "use \"", backend, "\".",
      call. = FALSE
    )
  }

  p <- platform()
  if (p[["sysname"]] == "Linux" && backend == "pt") {
    require_birdnet_extra("pt")
    if (!nzchar(Sys.getenv("UV_TORCH_BACKEND"))) {
      Sys.setenv(UV_TORCH_BACKEND = "auto")
    }
  } else if (p[["sysname"]] == "Linux" && backend == "pb") {
    require_birdnet_extra("and-cuda")
    # The TensorFlow 2.21.0 wheel has no search path for libcusolver, so it
    # finds no GPU and runs on the CPU (tensorflow/tensorflow#113541). 2.20.0
    # and the 2.22 release candidates have it.
    reticulate::py_require("tensorflow!=2.21.0")
  } else if (
    p[["sysname"]] == "Darwin" && p[["machine"]] == "arm64" && backend == "pb"
  ) {
    require_birdnet_extra("tf")
    reticulate::py_require("tensorflow-metal")
  } else {
    stop(
      "No automatic GPU setup for ", p[["sysname"]], "/", p[["machine"]],
      " with backend '", backend, "'. ",
      "See vignette('gpu', package = 'birdnetR').",
      call. = FALSE
    )
  }

  .gpu$backend <- backend
  invisible(TRUE)
}


# The backend birdnet_use_gpu() set up in this R session.
.gpu <- new.env(parent = emptyenv())


#' Operating system and CPU architecture, as one mockable value
#' @noRd
platform <- function() {
  info <- Sys.info()
  c(sysname = info[["sysname"]], machine = info[["machine"]])
}
