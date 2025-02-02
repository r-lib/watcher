#' @importFrom later run_now
#' @importFrom R6 R6Class
#' @useDynLib watcher, .registration = TRUE
#' @keywords internal
"_PACKAGE"

# To silence R CMD check note: All declared Imports should be used.
# rlang is not loaded unless used, later is loaded but used only at C level
.internal <- function() {
  if (FALSE) later::run_now(rlang::as_function(identity))
}
