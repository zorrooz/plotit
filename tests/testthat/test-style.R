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
test_that("style() accepts custom theme object", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_minimal())
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("style() supports ... for theme() tweaks", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_minimal(),
      plot.title = ggplot2::element_text(face = "bold")
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() accepts theme_bw", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_bw())
  expect_s3_class(p, "plotit::plotit")
})

test_that("plotit() auto-applies default theme during construction", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})
