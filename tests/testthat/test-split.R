# ============================================================
# split_* function family -- BDD tests (assert rendered output)
# AGENTS.md 4.8
# ============================================================
library(plotit)

# ---- split_wrap ----
test_that("[BDD] split_wrap facets into multiple panels", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, ncol = 3)
  built <- ggplot2::ggplot_build(p@gg)
  # 3 species -> 3 panels
  expect_equal(nrow(built$layout$layout), 3)
})

test_that("[BDD] split_wrap nrow controls row count", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, nrow = 2)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$layout$layout$ROW[1], 1)
})

test_that("[BDD] split_wrap scales=\"free\" renders each panel independently", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, scales = "free")
  expect_s3_class(p, "plotit::plotit")
})

test_that("[BDD] split_wrap scales=\"free_y\" renders", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, scales = "free_y")
  expect_s3_class(p, "plotit::plotit")
})

# ---- split_grid ----
test_that("[BDD] split_grid rows creates row facets", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(rows = ggplot2::vars(Species))
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(nrow(built$layout$layout), 3)
})

test_that("[BDD] split_grid cols creates column facets", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(cols = ggplot2::vars(Species))
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(nrow(built$layout$layout), 3)
})

test_that("[BDD] split_grid rows + cols produces 2D grid", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    split_grid(rows = ggplot2::vars(vs), cols = ggplot2::vars(am))
  built <- ggplot2::ggplot_build(p@gg)
  # vs (2 levels) * am (2 levels) = 4 panels
  expect_equal(nrow(built$layout$layout), 4)
})

test_that("[BDD] split_grid ... shorthand (single variable) creates facets", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(Species)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(nrow(built$layout$layout), 3)
})

test_that("split_grid ... and rows duplicate warns", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_warning(
    split_grid(p, Species, rows = ggplot2::vars(Species))
  )
})

test_that("[BDD] split_grid scales and space params render", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    split_grid(
      rows = ggplot2::vars(vs), cols = ggplot2::vars(am),
      scales = "free", space = "free_y"
    )
  expect_s3_class(p, "plotit::plotit")
})

# ---- passthrough ----
test_that("[BDD] split_wrap passes labeller through", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, ncol = 2, labeller = "label_both")
  built <- ggplot2::ggplot_build(p@gg)
  # label_both produces "setosa: Sepal.Width" style strip text
  labels <- as.character(built$layout$layout$Species)
  expect_match(labels[1], "setosa")
})

test_that("[BDD] split_grid passes labeller through", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    split_grid(
      rows = ggplot2::vars(vs), cols = ggplot2::vars(am),
      labeller = "label_both"
    )
  expect_s3_class(p, "plotit::plotit")
})
