# ============================================================
# mark_* function family — layer addition, auto-dodge, rasterization
# ============================================================
library(plotit)

# ---- mark_point ----
test_that("mark_point 添加散点图层并返回 plotit 对象", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, size = 2)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_point 支持局部 mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, mapping = encode(colour = Species))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_point 支持局部 data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, data = iris[1:50, ])
  expect_s3_class(p2, "plotit::plotit")
})

# ---- mark_line ----
test_that("mark_line 添加折线图层并返回 plotit 对象", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  p2 <- mark_line(p, linewidth = 0.8)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_line 支持局部 data 和 mapping", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  sub <- ggplot2::economics[1:10, ]
  p2 <- mark_line(p, data = sub, mapping = encode(x = date, y = unemploy))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

# ---- mark_bar ----
test_that("mark_bar 添加柱状图层并返回 plotit 对象", {
  p <- plotit(iris, encode(x = Species))
  p2 <- mark_bar(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_bar 有 y 映射时自动切换到 geom_col", {
  df <- data.frame(cat = c("A", "B"), val = c(10, 20))
  p <- plotit(df, encode(x = cat, y = val)) |>
    mark_bar()
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

test_that("mark_bar 支持图层级 data", {
  p <- plotit(iris, encode(x = Species)) |>
    mark_bar(data = iris[1:100, ])
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

test_that("mark_bar 支持 fill 映射实现堆叠", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_boxplot ----
test_that("mark_boxplot 添加箱线图图层并返回 plotit 对象", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p2 <- mark_boxplot(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_boxplot 支持局部 data", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p2 <- mark_boxplot(p, data = iris[1:100, ])
  expect_s3_class(p2, "plotit::plotit")
})

# ---- dodge 自动注入 ----
test_that("mark_bar 离散 x 时自动注入 position_dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_bar 连续 x 时不注入 dodge（dodge=0）", {
  p <- plotit(mtcars, encode(x = wt)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionStack"))
})

test_that("mark_bar 显式 position 覆盖全局 dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  pos <- p@gg$layers[[1]]$position
  expect_false(inherits(pos, "PositionDodge"))
})

test_that("mark_bar 显式 position_dodge(0.5) 覆盖全局 dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = ggplot2::position_dodge(0.5))
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_boxplot 离散 x 时自动注入 position_dodge", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_boxplot 显式 position=\"dodge2\" 覆盖全局 dodge", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot(position = "dodge2")
  pos <- p@gg$layers[[1]]$position
  # dodge2 继承自 PositionDodge → 检查是否为 PositionDodge2 而非 PositionDodge
  expect_true(inherits(pos, "PositionDodge2"))
})

test_that("mark_point 离散 x 时自动注入 position_dodge", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_point()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_line 离散 x 时自动注入 position_dodge", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_line()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("plotit() 显式 dodge=0 时所有 mark 都不注入 dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species), dodge = 0) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_false(inherits(pos, "PositionDodge"))
})

test_that("离散 y（无 y 映射）时 bar 也触发 dodge", {
  # Species 是离散变量 → dodge 启发为 0.8
  p <- plotit(iris, encode(x = Species)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

# ---- rasterize ----
test_that("rasterize 默认 FALSE 时不触发 ggrastr 检查", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_no_error(mark_point(p))
})

# ---- 管道链含 mark ----
test_that("管道链 mark_point + scale + label 不崩溃", {
  p <- iris |>
    plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point(size = 2) |>
    scale_color(name = "Species") |>
    label_title("Test") |>
    style_default()
  expect_s3_class(p, "plotit::plotit")
})

test_that("管道链 mark_boxplot + scale_fill + label + project 不崩溃", {
  p <- iris |>
    plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot() |>
    scale_fill(name = "物种") |>
    label_title("箱线图") |>
    label_subtitle("按鸢尾花种类") |>
    label_axis(text = "种类", aes = "x") |>
    label_axis(text = "花萼长度", aes = "y") |>
    project_flip() |>
    style_default()
  expect_s3_class(p, "plotit::plotit")
})
