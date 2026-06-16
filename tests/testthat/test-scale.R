# ============================================================
# scale_* function family — all 8 scales, full coverage
# ============================================================
library(plotit)

# ============================================================
# scale_color
# ============================================================

test_that("scale_color 对连续变量自动使用连续尺度", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(name = "马力")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 对离散变量自动使用离散尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(name = "物种")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 清除 default_color 注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  )
  p <- scale_color(p, name = "测试")
  expect_null(p@gg$mapping$colour)
  expect_null(p@meta@default_color)
})

test_that("scale_color range=viridis（离散）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "viridis")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=brewer（离散）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "brewer")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=grey（离散）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "grey")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=hue（离散，显式默认）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "hue")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=c(blue,red) 连续渐变", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=c(blue,white,red) 三色渐变", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(range = c("blue", "white", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=reverse", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=reverse + range=c(blue,red) 连续渐变翻转", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "reverse", range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=binned + range=viridis", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "binned", range = "viridis")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=binned + range=c(blue,red) 两步渐变", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "binned", range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 连续变量 + limits 参数", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(limits = c(50, 300))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 离散变量 + breaks 参数", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(breaks = c("setosa", "virginica"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=identity 显式连续", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "identity")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 未知 scheme 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point()
  expect_error(
    scale_color(p, range = "unknown_scheme"),
    "Unknown colour scheme"
  )
})

test_that("scale_color 非法 trans 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point()
  expect_error(
    scale_color(p, trans = "log"),
    "must be one of"
  )
})

# ============================================================
# scale_fill
# ============================================================

test_that("scale_fill 对连续变量自动使用连续尺度", {
  p <- plotit(mtcars, encode(x = factor(cyl), fill = hp)) |>
    mark_bar() |>
    scale_fill(name = "马力")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill 对离散变量自动使用离散尺度", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(name = "物种")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill 清除 default_color 注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  )
  p <- scale_fill(p, name = "测试")
  expect_null(p@gg$mapping$colour)
  expect_null(p@meta@default_color)
})

test_that("scale_fill range=viridis（离散）", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(range = "viridis")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill range=brewer（离散）", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(range = "brewer")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill range=c(blue,red) 连续渐变", {
  p <- plotit(mtcars, encode(x = factor(cyl), fill = hp)) |>
    mark_bar() |>
    scale_fill(range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill trans=reverse", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill trans=binned + range=brewer", {
  p <- plotit(mtcars, encode(x = factor(cyl), fill = hp)) |>
    mark_bar() |>
    scale_fill(trans = "binned", range = "brewer")
  expect_s3_class(p, "plotit::plotit")
})

# ============================================================
# scale_size
# ============================================================

test_that("scale_size 连续变量", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size(trans = "identity", range = c(1, 10))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_size 离散变量", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, size = Species)) |>
    mark_point()
  expect_no_error(suppressWarnings(scale_size(p, trans = "discrete")))
})

test_that("scale_size trans=binned", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size(trans = "binned")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_size auto-detect 连续变量（trans=NULL）", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_size trans=reverse", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

# ============================================================
# scale_alpha
# ============================================================

test_that("scale_alpha 连续变量", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha(trans = "identity", range = c(0.1, 0.8))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_alpha auto-detect", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_alpha trans=binned", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha(trans = "binned")
  expect_s3_class(p, "plotit::plotit")
})

# ============================================================
# scale_shape
# ============================================================

test_that("scale_shape 离散变量", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    scale_shape(range = c(1, 3))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_shape 默认 trans=discrete", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    scale_shape()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_shape trans=binned", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, shape = hp)) |>
    mark_point() |>
    scale_shape(trans = "binned")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_shape trans=identity 报错（连续变量不能映射到 shape）", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, shape = hp)) |>
    mark_point()
  expect_error(
    scale_shape(p, trans = "identity"),
    "continuous variable cannot be mapped to shape"
  )
})

# ============================================================
# scale_linetype
# ============================================================

test_that("scale_linetype 基础不报错", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_line() |>
    scale_linetype()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_linetype trans=binned", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, linetype = hp)) |>
    mark_line() |>
    scale_linetype(trans = "binned")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_linetype trans=identity 报错", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, linetype = hp)) |>
    mark_line()
  expect_error(
    scale_linetype(p, trans = "identity"),
    "continuous variable cannot be mapped to linetype"
  )
})

# ============================================================
# scale_x
# ============================================================

test_that("scale_x 连续尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    scale_x(name = "宽度", trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x 自动检测离散", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_point() |>
    scale_x()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x 显式 discrete", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    scale_x(trans = "discrete")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x trans=log10", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x trans=sqrt", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(trans = "sqrt")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x trans=reverse", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x trans=binned", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(trans = "binned")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x limits", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(limits = c(1, 6))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x breaks + labels", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(breaks = c(2, 4, 6), labels = c("轻", "中", "重"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x range 发出警告", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(scale_x(p, range = c(0, 10)), "range.*not meaningful")
})

test_that("scale_x 非法 trans 报错", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_error(scale_x(p, trans = "asin"), "must be one of")
})

# ============================================================
# scale_y
# ============================================================

test_that("scale_y 连续尺度 + limits", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    scale_y(limits = c(0, 10))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y 强制定量尺度", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_point() |>
    scale_y(trans = "identity")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y trans=log2", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_y(trans = "log2")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y range 发出警告", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(scale_y(p, range = c(0, 30)), "range.*not meaningful")
})

# ============================================================
# cross-scale: 多层 scale 覆盖
# ============================================================

test_that("同一 plot 连续调用 scale_color 和 scale_size 不冲突", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp, size = qsec)) |>
    mark_point() |>
    scale_color(name = "马力", range = "viridis") |>
    scale_size(range = c(1, 8))
  expect_s3_class(p, "plotit::plotit")
})
