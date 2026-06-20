# ============================================================
# style function family — theme application
# ============================================================
library(plotit)

# ---- style_default ----
test_that("style_default() applies default theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default()
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("style_default(base_size) no error", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_size = 14)
  expect_s3_class(p, "plotit::plotit")
})

test_that("style_default(base_family) no error", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_family = "serif")
  expect_s3_class(p, "plotit::plotit")
})

test_that("style_default multiple calls do not stack default theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default() |>
    style_default(base_size = 16)
  expect_s3_class(p, "plotit::plotit")
})

# ---- style ----
test_that("style() with no args applies default theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style()
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("style() supports ... for individual theme element overrides", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(plot.title = ggplot2::element_text(face = "bold"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() accepts base_theme to switch base theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(base_theme = ggplot2::theme_bw())
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() base_theme + overrides work together", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(base_theme = ggplot2::theme_bw(),
          plot.title = ggplot2::element_text(face = "bold"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("plotit() auto-applies default theme during construction", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})
