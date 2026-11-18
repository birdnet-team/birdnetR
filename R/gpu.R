#' Set up GPU support
#'
#' Declares the Python packages BirdNET needs to run on a GPU. Call it once at
#' the top of a script, before any model is loaded: the packages are resolved
#' when Python starts, so afterwards it is too late and the function errors
#' (restart R and call it first).
#'
#' Choose one backend per call. TensorFlow (`"pb"`) and PyTorch (`"pt"`) each
#' pull their own CUDA wheels, and installing both can conflict.
#'
#' Requirements by platform:
#' * **Linux, `"pt"`** (default): installs `birdnet[pt]`. If the environment
#'   variable `UV_TORCH_BACKEND` is not set, it is set to `"auto"` so that uv
#'   picks the torch build matching your GPU driver. For AMD GPUs, set e.g.
#'   `Sys.setenv(UV_TORCH_BACKEND = "rocm6.4")` before calling
#'   `birdnet_use_gpu()` (ROCm support is experimental).
#' * **Linux, `"pb"`**: installs `birdnet[and-cuda]`. An NVIDIA driver and CUDA
#'   must already be installed on the system.
#' * **macOS (Apple silicon), `"pb"`**: installs `birdnet[tf]` plus
#'   `tensorflow-metal`.
#'
#' Any other combination (for example Windows) has no automatic setup and
#' errors; see `vignette("Troubleshoot", package = "birdnetR")`, which also
#' covers everything else that can go wrong with GPUs.
#'
#' Afterwards, load a model for the chosen backend with
#' `birdnet_load(backend = "pt")` (or `birdnet_load_perch(device = "GPU")`) and
#' use `device = "GPU"` in [birdnet_predict()] and [birdnet_encode()].
#'
#' @param backend `"pt"` (PyTorch, default) or `"pb"` (TensorFlow).
#' @return Invisibly returns `TRUE`.
#' @examples
#' \dontrun{
#' # at the top of a script, before loading any model
#' birdnet_use_gpu("pt")
#' model <- birdnet_load("acoustic", "3.0", backend = "pt")
#' pred <- birdnet_predict(model, "soundscape.wav", device = "GPU")
#'
#' # AMD GPU (experimental)
#' Sys.setenv(UV_TORCH_BACKEND = "rocm6.4")
#' birdnet_use_gpu("pt")
#' }
#' @export
birdnet_use_gpu <- function(backend = c("pt", "pb")) {
  backend <- match.arg(backend)

  if (reticulate::py_available()) {
    stop(
      "birdnet_use_gpu() must be called before any model is loaded. ",
      "Restart R and call it first.",
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
  } else if (
    p[["sysname"]] == "Darwin" && p[["machine"]] == "arm64" && backend == "pb"
  ) {
    require_birdnet_extra("tf")
    reticulate::py_require("tensorflow-metal")
  } else {
    stop(
      "No automatic GPU setup for ", p[["sysname"]], "/", p[["machine"]],
      " with backend '", backend, "'. ",
      "See vignette('Troubleshoot', package = 'birdnetR').",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


#' Operating system and CPU architecture, as one mockable value
#' @noRd
platform <- function() {
  info <- Sys.info()
  c(sysname = info[["sysname"]], machine = info[["machine"]])
}
