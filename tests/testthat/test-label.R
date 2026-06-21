# ============================================================
# label_* function family — BDD tests (assert rendered output)
# AGENTS.md §4.8: 断言行为而非内部状态
# ============================================================
library(plotit)

# ---- helpers ----
# Build the ggplot and return the plot-level labels list
.lbl <- function(p) ggplot2::ggplot_build(p@gg)$plot$labels

# ---- label_title ----
test_that("label_title sets rendered title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("Custom Title")
  expect_equal(.lbl(p)$title, "Custom Title")
})

test_that("label_title text=NULL preserves existing title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(text = NULL)
  expect_equal(.lbl(p)$title, "Old")
})

test_that("label_title reset=TRUE removes title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(reset = TRUE)
  expect_null(.lbl(p)$title)
})

test_that("label_title hide=TRUE removes title element from theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Visible") |>
    label_title(hide = TRUE)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$plot.title, "element_blank"))
})

test_that("label_title text=\"\" sets empty title (still present in labels)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title(text = "")
  expect_equal(.lbl(p)$title, "")
})

# ---- label_subtitle ----
test_that("label_subtitle sets rendered subtitle", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Sub")
  expect_equal(.lbl(p)$subtitle, "Sub")
})

test_that("label_subtitle text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(text = NULL)
  expect_equal(.lbl(p)$subtitle, "Old")
})

test_that("label_subtitle reset=TRUE removes subtitle", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(reset = TRUE)
  expect_null(.lbl(p)$subtitle)
})

test_that("label_subtitle hide=TRUE removes from theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_subtitle(hide = TRUE)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$plot.subtitle, "element_blank"))
})

# ---- label_caption ----
test_that("label_caption sets rendered caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Cap")
  expect_equal(.lbl(p)$caption, "Cap")
})

test_that("label_caption text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(text = NULL)
  expect_equal(.lbl(p)$caption, "Old")
})

test_that("label_caption reset=TRUE removes caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(reset = TRUE)
  expect_null(.lbl(p)$caption)
})

test_that("label_caption hide=TRUE removes from theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_caption(hide = TRUE)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$plot.caption, "element_blank"))
})

# ---- label_axis ----
test_that("label_axis sets x-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Axis", aes = "x")
  expect_equal(.lbl(p)$x, "X Axis")
})

test_that("label_axis sets y-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "Y Axis", aes = "y")
  expect_equal(.lbl(p)$y, "Y Axis")
})

test_that("label_axis partial update does not affect other axis", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Only", aes = "x")
  expect_equal(.lbl(p)$x, "X Only")
  expect_equal(.lbl(p)$y, "Sepal.Length")  # ggplot default: variable name
})

test_that("label_axis missing aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_axis invalid aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

test_that("label_axis hide=TRUE hides axis title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x")
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$axis.title.x, "element_blank"))
})

test_that("label_axis text=NULL preserves current label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(text = NULL, aes = "x")
  expect_equal(.lbl(p)$x, "Custom")
})

test_that("label_axis reset=TRUE restores variable name", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_equal(.lbl(p)$x, "Sepal.Width")
})

test_that("label_axis reset overrides previous custom", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_equal(.lbl(p)$x, "Sepal.Width")
})

# ---- label_legend ----
test_that("label_legend sets legend title by aesthetic", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "Species", aes = "colour")
  expect_equal(.lbl(p)$colour, "Species")
})

test_that("label_legend without aes affects all mapped aesthetics", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "All")
  expect_equal(.lbl(p)$colour, "All")
})

test_that("label_legend global mode discovers layer-level colour mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species)) |>
    label_legend(text = "Species")
  expect_equal(.lbl(p)$colour, "Species")
})

test_that("label_legend no warning when aesthetic exists in layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend hide=TRUE hides legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(hide = TRUE, aes = "colour")
  # guides(colour = guide_legend(title = NULL)) — verify via rendered guide
  built <- ggplot2::ggplot_build(p@gg)
  expect_null(built$plot$guides$colour$title)
})

test_that("label_legend reset=TRUE restores default title (waiver)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(reset = TRUE, aes = "colour")
  # After reset, ggplot renders the variable name as the legend title
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$colour, "Species")
})

test_that("label_legend warns on non-existent aes", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend works for fill", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point() |>
    label_legend(text = "Fill", aes = "fill")
  expect_equal(.lbl(p)$fill, "Fill")
})

test_that("label_legend works for shape", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    label_legend(text = "Shape", aes = "shape")
  expect_equal(.lbl(p)$shape, "Shape")
})

# ---- pipeline label composition ----
test_that("pipeline with multiple labels does not conflict", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Main") |>
    label_subtitle("Sub") |>
    label_caption("Cap") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  lbl <- .lbl(p)
  expect_equal(lbl$title, "Main")
  expect_equal(lbl$subtitle, "Sub")
  expect_equal(lbl$caption, "Cap")
  expect_equal(lbl$x, "X")
  expect_equal(lbl$y, "Y")
})

# ---- hide + reset combo ----
test_that("label_axis hide=TRUE then reset=TRUE restores", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  # After reset, label restores variable name
  expect_equal(.lbl(p)$x, "Sepal.Width")
})

# ---- text/reset mutual exclusion ----
test_that("label_axis text+reset mutual exclusion errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_axis(p, text = "X", reset = TRUE, aes = "x"),
    "mutually exclusive"
  )
})

test_that("label_title text+reset mutual exclusion errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_title(p, text = "T", reset = TRUE),
    "mutually exclusive"
  )
})

test_that("label_legend reset=TRUE for all aesthetics", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length,
           colour = Species, fill = Species)) |>
    mark_point() |>
    scale_color() |>
    scale_fill() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(text = "Custom", aes = "fill") |>
    label_legend(reset = TRUE)
  built <- ggplot2::ggplot_build(p@gg)
  # After reset, both legends show variable names
  expect_equal(built$plot$labels$colour, "Species")
  expect_equal(built$plot$labels$fill, "Species")
})
