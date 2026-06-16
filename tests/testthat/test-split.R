# ============================================================
# split_* function family — facet layouts
# ============================================================
library(plotit)

# ---- split_wrap ----
test_that("split_wrap 基础分面", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, ncol = 3)
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetWrap"))
})

test_that("split_wrap nrow", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, nrow = 2)
  expect_s3_class(p, "plotit::plotit")
})

test_that("split_wrap scales=\"free\"", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, scales = "free")
  expect_s3_class(p, "plotit::plotit")
})

test_that("split_wrap scales=\"free_y\"", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_wrap(Species, scales = "free_y")
  expect_s3_class(p, "plotit::plotit")
})

# ---- split_grid ----
test_that("split_grid rows", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(rows = ggplot2::vars(Species))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetGrid"))
})

test_that("split_grid cols", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(cols = ggplot2::vars(Species))
  expect_s3_class(p, "plotit::plotit")
})

test_that("split_grid rows + cols", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    split_grid(rows = ggplot2::vars(vs), cols = ggplot2::vars(am))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetGrid"))
})

test_that("split_grid ... 简写（单变量）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    split_grid(Species)
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetGrid"))
})

test_that("split_grid ... 与 rows 重复时报警告并以 ... 为准", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_warning(
    split_grid(p, Species, rows = ggplot2::vars(Species))
  )
})

test_that("split_grid scales 和 space 参数", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    split_grid(
      rows = ggplot2::vars(vs), cols = ggplot2::vars(am),
      scales = "free", space = "free_y"
    )
  expect_s3_class(p, "plotit::plotit")
})
