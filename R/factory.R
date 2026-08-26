#' @include class.R mark.R
NULL

# ---- make_mark ----
#' Create a custom mark
#'
#' Registers a new S7 generic + method from any ggplot2 geom function,
#' making it available in the plotit pipeline. The new mark behaves
#' identically to built-in marks: it supports `mapping`, `data`,
#' `position`, auto-dodge, and rasterization.
#'
#' @param name Mark name as a string (e.g. `"mark_spoke"`).
#'   Should start with `"mark_"`.
#' @param geom_fun A ggplot2 geom function
#'   (e.g. `ggplot2::geom_spoke`).
#' @return Invisibly returns the registered S7 generic.
#' @examples
#' make_mark("mark_spoke", ggplot2::geom_spoke)
#' df <- data.frame(
#'   x = 1:5, y = 1:5,
#'   angle = seq(0, 2 * pi, length.out = 5),
#'   radius = rep(0.3, 5)
#' )
#' # Now usable in the pipeline:
#' df |>
#'   plotit(encode(x = x, y = y, angle = angle, radius = radius)) |>
#'   mark_spoke()
#' @export
make_mark <- function(name, geom_fun) {
  if (!is.character(name) || length(name) != 1) {
    cli::cli_abort("{.arg name} must be a single string.")
  }
  if (!grepl("^mark_", name)) {
    cli::cli_warn(
      "{.arg name} should start with 'mark_', got {.val {name}}."
    )
  }

  generic <- S7::new_generic(
    name, "plot",
    function(plot, mapping = NULL, data = NULL, position = NULL, ...,
             rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
      S7::S7_dispatch()
    }
  )
  ._register_mark_method(generic, geom_fun)
  # Make the new mark callable from the calling environment (same pattern
  # as make_theme), so it works inside pipelines right away.
  assign(name, generic, envir = parent.frame())
  invisible(generic)
}

# ---- make_theme ----
#' Create a reusable theme preset
#'
#' Builds a theme function from `ggplot2::theme()` elements and
#' an optional base theme. The returned function applies the theme
#' to a plotit object and can be used anywhere `style()` is used.
#'
#' @param name Name for the theme function as a string
#'   (e.g. `"style_dark"`).
#' @param ... Theme elements passed to [ggplot2::theme()].
#' @param base_theme A base ggplot2 theme function
#'   (default: [ggplot2::theme_minimal]).
#' @return Invisibly returns the created function.
#' @details
#' The theme function is assigned to `name` in the calling environment
#' (`parent.frame()`) and also returned invisibly.  When calling
#' `make_theme()` inside another function, assign the return value
#' explicitly -- the `parent.frame()` assignment is lost when that
#' function returns.
#' @examples
#' style_dark <- make_theme("style_dark",
#'   plot.background = ggplot2::element_rect(fill = "#1a1a1a"),
#'   text = ggplot2::element_text(colour = "white")
#' )
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   style_dark()
#' @export
make_theme <- function(name, ..., base_theme = ggplot2::theme_minimal) {
  force(name)
  force(base_theme)
  dots <- rlang::list2(...)

  fun <- function(plot, base_size = NULL, base_family = NULL) {
    thm <- base_theme(
      base_size = base_size %||% ._STYLE_TOKENS$base_size,
      base_family = base_family %||% ""
    ) + do.call(ggplot2::theme, dots)
    plot@gg <- plot@gg + thm
    plot
  }
  assign(name, fun, envir = parent.frame())
  invisible(fun)
}
