# ============================================================
# style 函数族测试 — 主题应用
# ============================================================
library(plotit)

# ---- style_default ----
test_that("style_default() 应用默认主题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default()
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("style_default(base_size) 不报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_size = 14)
  expect_s3_class(p, "plotit::plotit")
})

test_that("style_default(base_family) 不报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default(base_family = "serif")
  expect_s3_class(p, "plotit::plotit")
})

test_that("style_default 多次调用不叠加默认主题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_default() |>
    style_default(base_size = 16)
  expect_s3_class(p, "plotit::plotit")
})

# ---- style ----
test_that("style() 接受自定义 theme 对象", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_minimal())
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("style() 支持 ... 传递 theme() 微调", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_minimal(),
      plot.title = ggplot2::element_text(face = "bold")
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() 接受 theme_bw", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_bw())
  expect_s3_class(p, "plotit::plotit")
})

test_that("plotit() 构造时自动应用默认主题并设置标记", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})
