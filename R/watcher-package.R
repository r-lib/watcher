#' @importFrom later run_now
#' @importFrom R6 R6Class
#' @useDynLib watcher, .registration = TRUE
#' @keywords internal
"_PACKAGE"

# Silences R CMD check note: All declared Imports should be used
# rlang is not loaded unless used, later is loaded but used only at C level
# nocov start
.internal <- function() {
  if (FALSE) rlang::as_function(later::run_now)
}
# nocov end
