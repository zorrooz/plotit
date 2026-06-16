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

test_that("plotit() size_unit 不受 autofit 影响，始终验证", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
           autofit = TRUE, size_unit = "ft"),
    "unit"
  )
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

# ---- plotit() 尺寸初始化（替代旧 set_size 测试）----
test_that("plotit() 正确设置 meta 尺寸字段", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
              width = 10, height = 8, size_unit = "cm")
  expect_equal(p@meta@width, 10)
  expect_equal(p@meta@height, 8)
  expect_equal(p@meta@unit, "cm")
})

test_that("plotit() 尺寸可通过 export() 覆盖", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
              width = 6, height = 4, size_unit = "in") |>
    mark_point()
  # Export 时传入不同尺寸
  expect_no_error(export(p, tempfile(fileext = ".png"),
                         width = 8, height = 6, dpi = 72))
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

# ---- scale_color / scale_fill 自动检测 ----
test_that("scale_color 对连续变量使用 viridis 连续尺度", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point()
  expect_no_error(p <- scale_color(p, name = "马力"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color 对离散变量使用离散尺度", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length,
             colour = Species)) |>
    mark_point()
  expect_no_error(p <- scale_color(p, name = "物种"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill 对连续变量使用 viridis 连续尺度", {
  p <- plotit(mtcars, encode(x = factor(cyl), fill = hp)) |>
    mark_bar()
  expect_no_error(p <- scale_fill(p, name = "马力"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill 对离散变量使用离散尺度", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar()
  expect_no_error(p <- scale_fill(p, name = "物种"))
  expect_s3_class(p, "plotit::plotit")
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
  p <- label_axis(p, text = "X轴", aes = "x")
  p <- label_axis(p, text = "Y轴", aes = "y")
  expect_equal(p@meta@labels@x, "X轴")
  expect_equal(p@meta@labels@y, "Y轴")
  expect_equal(p@gg$labels$x, "X轴")
  expect_equal(p@gg$labels$y, "Y轴")
})

test_that("label_axis 部分更新时不影响另一轴", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "仅 X", aes = "x")
  expect_equal(p@meta@labels@x, "仅 X")
  expect_null(p@meta@labels@y)
})

# ---- label_axis FALSE vs TRUE 在 meta 中可区分 ----
test_that("label_axis FALSE 在 meta 中存储 FALSE（非 NULL）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = FALSE, aes = "x")
  expect_false(p@meta@labels@x)
})

test_that("label_axis TRUE 在 meta 中存储 NULL", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = TRUE, aes = "x")
  expect_null(p@meta@labels@x)
})

# ---- style_default / style ----
test_that("style_default() 应用默认主题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- style_default(p)
  expect_s3_class(p, "plotit::plotit")
})

test_that("style() 接受自定义主题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- style(p, ggplot2::theme_minimal())
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

# ---- export ----
test_that("export() 可导出 PNG 和 PDF", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p)
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
  expect_no_error(export(p, tempfile(fileext = ".pdf")))
})

test_that("export() 非法 filename 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(export(p, NULL), "filename")
  expect_error(export(p, ""), "filename")
})

# ---- export autofit ----
test_that("export() works with autofit = TRUE", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
              autofit = TRUE) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
})

test_that("export() autofit + 用户显式参数：用户参数不被覆盖", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
              autofit = TRUE) |>
    mark_point()
  # 用户显式传 width=10, height=8 — autofit 不应覆盖
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, height = 8, dpi = 72))
})

test_that("export() autofit + 用户只传 width：height 仍由 autofit 决定", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
              autofit = TRUE) |>
    mark_point()
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, dpi = 72))
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
  p <- label_legend(p, text = "物种", aes = "colour")
  expect_equal(p@meta@labels@legend[["colour"]], "物种")
  expect_equal(p@gg$labels$colour, "物种")
})

test_that("label_legend 不指定 aesthetic 时影响所有映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "全部")
  expect_equal(p@meta@labels@legend[["default"]], "全部")
  expect_equal(p@gg$labels$colour, "全部")
})

# ---- label_legend 图层级映射 ----
test_that("label_legend 全局模式可发现图层级 colour 映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  p <- label_legend(p, text = "物种")
  # 应能找到图层中的 colour 映射
  expect_equal(p@meta@labels@legend[["default"]], "物种")
})

test_that("label_legend aes 警告检查包含图层映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  # colour 在图层映射中存在，不应警告
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

# ---- Four-state protocol tests ----
test_that("label_axis errors when aes is missing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_title four-state: FALSE hides, TRUE resets, NULL skips", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p1 <- p |> label_title(FALSE)
  expect_null(p1@gg$labels$title)
  p2 <- p |> label_title(TRUE)
  expect_null(p2@gg$labels$title)  # title has no default, same as FALSE
  p3 <- p |> label_title("Old") |> label_title(NULL)
  expect_equal(p3@gg$labels$title, "Old")  # NULL = skip
})

test_that("label_axis four-state: FALSE hides, TRUE shows variable name, NULL skips", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p1 <- p |> label_axis(text = FALSE, aes = "x")
  expect_true(inherits(p1@gg$theme$axis.title.x, "element_blank"))
  expect_false(p1@meta@labels@x)  # FALSE stored in meta, not NULL
  p2 <- p |> label_axis(text = TRUE, aes = "x")
  expect_false("x" %in% names(p2@gg$labels))  # key removed → fallback to variable name
  expect_null(p2@meta@labels@x)  # TRUE → NULL in meta
  p3 <- p |> label_axis(text = "Old", aes = "x") |> label_axis(text = NULL, aes = "x")
  expect_equal(p3@gg$labels$x, "Old")  # NULL = skip
  # TRUE after custom removes the key
  p4 <- p |> label_axis(text = "Old", aes = "x") |> label_axis(text = TRUE, aes = "x")
  expect_false("x" %in% names(p4@gg$labels))
})

test_that("label_legend four-state: FALSE hides, TRUE shows default, NULL skips", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p1 <- p |> label_legend(text = FALSE, aes = "colour")
  expect_null(p1@gg$scales$scales[[1]]$name)  # blanked
  p2 <- p |> label_legend(text = TRUE, aes = "colour")
  expect_true(inherits(p2@gg$scales$scales[[1]]$name, "waiver"))  # default
  p3 <- p |> label_legend(text = "Custom", aes = "colour") |>
    label_legend(text = NULL, aes = "colour")
  expect_equal(p3@gg$scales$scales[[1]]$name, "Custom")  # NULL = skip
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
    style_default()
  expect_s3_class(p, "plotit::plotit")
})

test_that("扩展管道链含新功能不崩溃", {
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

# ---- style_default 参数 ----
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

test_that("style() with ... theme overrides", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style(ggplot2::theme_minimal(),
      plot.title = ggplot2::element_text(face = "bold"))
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_bar with y aesthetic triggers geom_col ----
test_that("mark_bar with y mapping uses geom_col", {
  df <- data.frame(cat = c("A", "B"), val = c(10, 20))
  p <- plotit(df, encode(x = cat, y = val)) |>
    mark_bar()
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

test_that("mark_bar supports layer-level data", {
  p <- plotit(iris, encode(x = Species)) |>
    mark_bar(data = iris[1:100, ])
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

# ---- label_axis with invalid aes ----
test_that("label_axis errors on invalid aes value", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

# ---- label_legend 边际情况 ----
test_that("label_legend FALSE 隐藏图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, text = FALSE, aes = "colour")
  expect_null(p@gg$scales$scales[[1]]$name)
})

test_that("label_legend TRUE 显示默认图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, text = TRUE, aes = "colour")
  expect_true(inherits(p@gg$scales$scales[[1]]$name, "waiver"))
})

test_that("label_legend 不存在的 aes 给出警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

# ---- print() 方法基本测试 ----
test_that("print() 返回 plotit 对象", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_s3_class(print(p), "plotit::plotit")
})
