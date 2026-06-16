# ============================================================
# label_* function family — four-state protocol, meta sync, edge cases
# ============================================================
library(plotit)

# ---- label_title ----
test_that("label_title 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_title(p, "测试标题")
  expect_equal(p@meta@labels@title, "测试标题")
  expect_equal(p@gg$labels$title, "测试标题")
})

test_that("label_title NULL 跳过，不修改已有值", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("Old") |>
    label_title(NULL)
  expect_equal(p@gg$labels$title, "Old")
})

test_that("label_title FALSE 隐藏标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p1 <- p |> label_title(FALSE)
  expect_null(p1@gg$labels$title)
})

test_that("label_title TRUE 清空（title 无默认变量名）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p2 <- p |> label_title(TRUE)
  expect_null(p2@gg$labels$title)
})

# ---- label_subtitle ----
test_that("label_subtitle 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_subtitle(p, "副标题")
  expect_equal(p@meta@labels@subtitle, "副标题")
  expect_equal(p@gg$labels$subtitle, "副标题")
})

test_that("label_subtitle FALSE 隐藏", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_subtitle(p, FALSE)
  expect_null(p@meta@labels@subtitle)
  expect_null(p@gg$labels$subtitle)
})

test_that("label_subtitle NULL 跳过", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(NULL)
  expect_equal(p@gg$labels$subtitle, "Old")
})

# ---- label_caption ----
test_that("label_caption 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_caption(p, "脚注")
  expect_equal(p@meta@labels@caption, "脚注")
  expect_equal(p@gg$labels$caption, "脚注")
})

test_that("label_caption FALSE 隐藏", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_caption(p, FALSE)
  expect_null(p@meta@labels@caption)
  expect_null(p@gg$labels$caption)
})

test_that("label_caption NULL 跳过", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(NULL)
  expect_equal(p@gg$labels$caption, "Old")
})

# ---- label_axis ----
test_that("label_axis 同步更新 x 轴标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "X轴", aes = "x")
  expect_equal(p@meta@labels@x, "X轴")
  expect_equal(p@gg$labels$x, "X轴")
})

test_that("label_axis 同步更新 y 轴标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "Y轴", aes = "y")
  expect_equal(p@meta@labels@y, "Y轴")
  expect_equal(p@gg$labels$y, "Y轴")
})

test_that("label_axis 部分更新不影响另一轴", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "仅 X", aes = "x")
  expect_equal(p@meta@labels@x, "仅 X")
  expect_null(p@meta@labels@y)
})

test_that("label_axis 缺 aes 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_axis 非法 aes 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

test_that("label_axis FALSE：隐藏并存储 FALSE 到 meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |> label_axis(text = FALSE, aes = "x")
  expect_true(inherits(p@gg$theme$axis.title.x, "element_blank"))
  expect_false(p@meta@labels@x)
})

test_that("label_axis TRUE：显示变量名，meta 存 NULL", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |> label_axis(text = TRUE, aes = "x")
  expect_false("x" %in% names(p@gg$labels))
  expect_null(p@meta@labels@x)
})

test_that("label_axis TRUE 覆盖之前自定义", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(text = TRUE, aes = "x")
  expect_false("x" %in% names(p@gg$labels))
})

test_that("label_axis NULL 跳过，保留之前自定义", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(text = NULL, aes = "x")
  expect_equal(p@gg$labels$x, "Old")
})

# ---- label_legend ----
test_that("label_legend 按 aesthetic 设置图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "物种", aes = "colour")
  expect_equal(p@meta@labels@legend[["colour"]], "物种")
  expect_equal(p@gg$labels$colour, "物种")
})

test_that("label_legend 不指定 aes 时影响所有已映射美学", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "全部")
  expect_equal(p@meta@labels@legend[["default"]], "全部")
  expect_equal(p@gg$labels$colour, "全部")
})

test_that("label_legend 全局模式可发现图层级 colour 映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  p <- label_legend(p, text = "物种")
  expect_equal(p@meta@labels@legend[["default"]], "物种")
})

test_that("label_legend 图层映射中存在时不警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend FALSE 隐藏图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, text = FALSE, aes = "colour")
  expect_null(p@gg$scales$scales[[1]]$name)
})

test_that("label_legend TRUE 显示默认图例标题（waiver）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, text = TRUE, aes = "colour")
  expect_true(inherits(p@gg$scales$scales[[1]]$name, "waiver"))
})

test_that("label_legend NULL 跳过，保留自定义", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(text = NULL, aes = "colour")
  expect_equal(p@gg$scales$scales[[1]]$name, "Custom")
})

test_that("label_legend 不存在的 aes 给出警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend 对 fill 生效", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point()
  p <- label_legend(p, text = "填充", aes = "fill")
  expect_equal(p@meta@labels@legend[["fill"]], "填充")
})

test_that("label_legend 对 shape 生效", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point()
  p <- label_legend(p, text = "形状", aes = "shape")
  expect_equal(p@meta@labels@legend[["shape"]], "形状")
})

# ---- 管道链 label 组合 ----
test_that("管道链多个 label 不冲突", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Main") |>
    label_subtitle("Sub") |>
    label_caption("Cap") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  expect_equal(p@meta@labels@title, "Main")
  expect_equal(p@meta@labels@subtitle, "Sub")
  expect_equal(p@meta@labels@caption, "Cap")
  expect_equal(p@meta@labels@x, "X")
  expect_equal(p@meta@labels@y, "Y")
})
