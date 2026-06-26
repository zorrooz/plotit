#' @include class.R
NULL

# ---- Package options ----
# Default values registered in .onLoad so they appear in options().
.plotit_options <- list(
  plotit.device = "default",
  plotit.default_width = 7,
  plotit.default_height = 5,
  plotit.default_unit = "in"
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(.plotit_options) %in% names(op))
  if (any(toset)) options(.plotit_options[toset])
  invisible()
}

# ---- Unsupported operations on composites ----
# Registered here (loaded last) so all S7 generics exist.
for (.generic_name in c(
  "mark_point", "mark_line", "mark_bar", "mark_boxplot",
  "mark_histogram", "mark_density",
  "scale_color", "scale_fill", "scale_size", "scale_alpha",
  "scale_shape", "scale_linetype", "scale_x", "scale_y",
  "project_cartesian", "project_polar", "project_parallel",
  "project_map", "split_wrap", "split_grid",
  "label_axis", "label_legend"
)) {
  if (!exists(.generic_name, mode = "function")) next
  .generic <- get(.generic_name)
  local({
    .name <- .generic_name
    S7::method(.generic, plotit_composite) <<- function(plot, ...) {
      cli::cli_abort(c(
        "{.fn {.name}} is not supported for {.cls plotit_composite} objects.",
        "i" = "Apply it to individual sub-plots before composing."
      ))
    }
  })
}
