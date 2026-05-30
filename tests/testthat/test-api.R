# ============================================================
# API 基本功能测试 — 类验证、守卫、关键路径
# ============================================================
library(plotit)

# ---- plotit() + encode() ----
test_that("plotit() 和 encode() 协作创建 plotit 对象", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg, "ggplot"))
  expect_true(inherits(p@meta, "plotit::plotit_metadata"))
})

test_that("plotit() 拒绝非 encode() 映射", {
  expect_error(
    plotit(iris, ggplot2::aes(x = Sepal.Width, y = Sepal.Length)),
    "must be created with"
  )
})

test_that("plotit() 在 autofit=FALSE 时要求 width 和 height", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
         autofit = FALSE, width = NULL, height = 5),
    "both.*width.*height"
  )
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
         autofit = FALSE, width = 7, height = NULL),
    "both.*width.*height"
  )
})

test_that("plotit() autofit=TRUE 时忽略 width/height", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            autofit = TRUE, width = 100, height = 100)
  expect_null(p@meta@width)
  expect_null(p@meta@height)
  expect_null(p@meta@unit)
})

test_that("plotit() 的 default_color 注入 I() 到 mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = "steelblue")
  expect_equal(p@meta@default_color, "steelblue")
  expect_true(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() 的 default_color 为 NULL 时不注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = NULL)
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("plotit() 的 default_color 在有 colour 映射时跳过", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
            default_color = "steelblue")
  expect_true(is.call(p@gg$mapping$colour))
  expect_false(inherits(p@gg$mapping$colour, "AsIs"))
})

# ---- default_color 失效机制 ----
test_that("scale_color 清除 default_color 的 I() 注入和 guides", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = "steelblue")
  p <- scale_color(p, name = "测试")
  expect_null(p@gg$mapping$colour)
  expect_true(is.null(p@gg$guides$colour) || p@gg$guides$colour != "none")
  expect_null(p@meta@default_color)
})

test_that("scale_fill 也清除 default_color 注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = "steelblue")
  p <- scale_fill(p, name = "测试")
  expect_null(p@gg$mapping$colour)
  expect_null(p@meta@default_color)
})

# ---- mark_point / mark_line ----
test_that("mark_point 添加散点图层后返回 plotit 对象", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, size = 2)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_line 添加折线图层后返回 plotit 对象", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  p2 <- mark_line(p, linewidth = 0.8)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_line 支持局部数据", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  sub <- ggplot2::economics[1:10, ]
  p2 <- mark_line(p, data = sub, mapping = encode(x = date, y = unemploy))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

# ---- label_* ----
test_that("label_title 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_title(p, "测试标题")
  expect_equal(p@meta@labels@title, "测试标题")
  expect_equal(p@gg$labels$title, "测试标题")
})

test_that("label_axis 同步更新 x/y 轴标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, x = "X轴", y = "Y轴")
  expect_equal(p@meta@labels@x, "X轴")
  expect_equal(p@meta@labels@y, "Y轴")
  expect_equal(p@gg$labels$x, "X轴")
  expect_equal(p@gg$labels$y, "Y轴")
})

test_that("label_axis 部分更新时不影响另一轴", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, x = "仅 X")
  expect_equal(p@meta@labels@x, "仅 X")
  expect_null(p@meta@labels@y)
})

# ---- style ----
test_that("style() 默认应用 plotit_theme_default", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- style(p)
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() 接受自定义主题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- style(p, ggplot2::theme_minimal(base_size = 14))
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_polar ----
test_that("project_polar 不崩溃", {
  p <- plotit(mtcars, encode(x = factor(cyl)))
  expect_no_error(project_polar(p))
})

# ---- split_wrap ----
test_that("split_wrap 添加分面", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- split_wrap(p, Species, ncol = 3)
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetWrap"))
})

# ---- set_size ----
test_that("set_size 更新 meta 尺寸字段", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- set_size(p, width = 10, height = 8, unit = "cm")
  expect_equal(p@meta@width, 10)
  expect_equal(p@meta@height, 8)
  expect_equal(p@meta@unit, "cm")
})

test_that("set_size 部分更新不影响其他字段", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  orig_w <- p@meta@width
  p <- set_size(p, height = 6)
  expect_equal(p@meta@width, orig_w)
  expect_equal(p@meta@height, 6)
})

# ---- export ----
test_that("export() 可导出 PNG 和 PDF", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p)
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
  expect_no_error(export(p, tempfile(fileext = ".pdf")))
})

# ---- mark_bar / mark_boxplot ----
test_that("mark_bar 添加柱状图层后返回 plotit 对象", {
  p <- plotit(iris, encode(x = Species))
  p2 <- mark_bar(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_boxplot 添加箱线图图层后返回 plotit 对象", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p2 <- mark_boxplot(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

# ---- label_subtitle / label_caption / label_legend ----
test_that("label_subtitle 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_subtitle(p, "副标题")
  expect_equal(p@meta@labels@subtitle, "副标题")
  expect_equal(p@gg$labels$subtitle, "副标题")
})

test_that("label_caption 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_caption(p, "脚注")
  expect_equal(p@meta@labels@caption, "脚注")
  expect_equal(p@gg$labels$caption, "脚注")
})

test_that("label_legend 按 aesthetic 设置图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, title = "物种", aesthetic = "colour")
  expect_equal(p@meta@labels@legend[["colour"]], "物种")
  expect_equal(p@gg$labels$colour, "物种")
})

test_that("label_legend 不指定 aesthetic 时影响所有映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, title = "全部")
  expect_equal(p@meta@labels@legend[["default"]], "全部")
  expect_equal(p@gg$labels$colour, "全部")
})

# ---- scale_x / scale_y ----
test_that("scale_x 使用连续尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- scale_x(p, name = "宽度", trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x 自动检测离散变量", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p <- scale_x(p)
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y 使用连续尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- scale_y(p, limits = c(0, 10))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x 显式 discrete=TRUE 使用离散尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- scale_x(p, discrete = TRUE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y 显式 discrete=FALSE 强制定量尺度", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p <- scale_y(p, discrete = FALSE)
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_cartesian / project_flip ----
test_that("project_cartesian 不崩溃", {
  p <- plotit(mtcars, encode(x = wt, y = mpg))
  expect_no_error(project_cartesian(p, xlim = c(0, 6)))
})

test_that("project_flip 翻转坐标轴", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg))
  p <- mark_boxplot(p)
  expect_no_error(project_flip(p))
})

# ---- split_grid ----
test_that("split_grid 添加网格分面", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- split_grid(p, rows = ggplot2::vars(Species))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetGrid"))
})

test_that("split_grid 支持 cols 参数", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- split_grid(p, cols = ggplot2::vars(Species))
  expect_s3_class(p, "plotit::plotit")
})

test_that("split_grid 同时使用 rows 和 cols", {
  p <- plotit(mtcars, encode(x = wt, y = mpg))
  p <- split_grid(p, rows = ggplot2::vars(vs), cols = ggplot2::vars(am))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$facet, "FacetGrid"))
})

test_that("split_grid 使用 ... 时对 rows 重复给出警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_warning(
    split_grid(p, Species, rows = ggplot2::vars(Species))
  )
})

# ---- 管道链 ----
test_that("完整管道链不崩溃", {
  p <- iris |>
    plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point(size = 2) |>
    scale_color(name = "Species") |>
    label_title("Test") |>
    style()
  expect_s3_class(p, "plotit::plotit")
})

test_that("扩展管道链含新功能不崩溃", {
  p <- iris |>
    plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot() |>
    scale_fill(name = "物种") |>
    label_title("箱线图") |>
    label_subtitle("按鸢尾花种类") |>
    label_axis(x = "种类", y = "花萼长度") |>
    project_flip() |>
    style()
  expect_s3_class(p, "plotit::plotit")
})
