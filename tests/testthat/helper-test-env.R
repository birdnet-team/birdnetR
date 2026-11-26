# Global testing environment helpers

#' Should the integration tests run?
#'
#' Only the environment variable decides. Once it is set, a missing Python
#' environment, a failed download or a model that does not load must fail the
#' tests, not skip them: otherwise a broken platform would pass CI.
#'
#' @return `TRUE` if `BIRDNETR_RUN_INTEGRATION_TESTS` is set to a true value.
is_full_test_env <- function() {
  isTRUE(as.logical(Sys.getenv("BIRDNETR_RUN_INTEGRATION_TESTS", "false")))
}
