# ============================================================
# style function family -- BDD tests (assert rendered theme)
# AGENTS.md 4.8
# ============================================================
library(plotit)

# ---- style_default ----
test_that("[BDD] style_default() renders with white panel background", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default()
  built <- ggplot2::ggplot_build(p@gg)
  # Default theme should have white panel (not grey)
  fill <- built$plot$theme$panel.background$fill
  expect_true(is.null(fill) || fill == "white" || identical(fill, "#FFFFFF"))
})

test_that("[BDD] style_default(base_size) changes text size", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_size = 14)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$theme$text$size, 14)
})

test_that("[BDD] style_default(base_family) changes font", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_family = "serif")
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$theme$text$family, "serif")
})

test_that("[BDD] style_default multiple calls use last setting", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default() |>
    style_default(base_size = 16)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$theme$text$size, 16)
})

# ---- style ----
test_that("[BDD] style() with no args applies clean theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style()
  built <- ggplot2::ggplot_build(p@gg)
  # Legend position should be "right" (default)
  expect_equal(built$plot$theme$legend.position, "right")
})

test_that("[BDD] style() element overrides are reflected in rendered theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(plot.title = ggplot2::element_text(face = "bold"))
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$theme$plot.title$face, "bold")
})

test_that("[BDD] style() base_theme switches to different base", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(base_theme = ggplot2::theme_bw())
  built <- ggplot2::ggplot_build(p@gg)
  # theme_bw has grey panel border
  expect_false(is.null(built$plot$theme$panel.border))
})

test_that("[BDD] style() base_theme + overrides combine", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(
      base_theme = ggplot2::theme_bw(),
      plot.title = ggplot2::element_text(face = "bold")
    )
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$theme$plot.title$face, "bold")
})

test_that("[BDD] plotit() applies default theme automatically", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  built <- ggplot2::ggplot_build(p@gg)
  fill <- built$plot$theme$panel.background$fill
  expect_true(is.null(fill) || fill == "white" || identical(fill, "#FFFFFF"))
})
