#' @importFrom later run_now
#' @importFrom R6 R6Class
#' @useDynLib watcher, .registration = TRUE
#' @keywords internal
"_PACKAGE"

# for R CMD check note: All declared Imports should be used.
# rlang is not loaded unless used, later is loaded but used only at C level
.internal <- function() {
  if (FALSE) rlang::as_function(identity)(later::run_now())
}
