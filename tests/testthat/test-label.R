# ============================================================
# label_* function family — text + hide protocol, meta sync, edge cases
# ============================================================
library(plotit)

# ---- label_title ----
test_that("label_title 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_title(p, "Custom Title")
  expect_equal(p@meta@labels@title, "Custom Title")
  expect_equal(p@gg$labels$title, "Custom Title")
})

test_that("label_title text=NULL 不修改已有标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(text = NULL)
  expect_equal(p@gg$labels$title, "Old")
  expect_equal(p@meta@labels@title, "Old")
})

test_that("label_title reset=TRUE 移除标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(reset = TRUE)
  expect_null(p@gg$labels$title)
  expect_null(p@meta@labels@title)
})

test_that("label_title hide=TRUE 从布局移除标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_title(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.title, "element_blank"))
  expect_null(p@meta@labels@title)
})

test_that("label_title text=\"\" 保留布局占位", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_title(p, text = "")
  expect_equal(p@gg$labels$title, "")
  expect_equal(p@meta@labels@title, "")
})

# ---- label_subtitle ----
test_that("label_subtitle 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_subtitle(p, "Sub")
  expect_equal(p@meta@labels@subtitle, "Sub")
  expect_equal(p@gg$labels$subtitle, "Sub")
})

test_that("label_subtitle text=NULL 不修改已有副标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(text = NULL)
  expect_equal(p@gg$labels$subtitle, "Old")
  expect_equal(p@meta@labels@subtitle, "Old")
})

test_that("label_subtitle reset=TRUE 移除副标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(reset = TRUE)
  expect_null(p@gg$labels$subtitle)
  expect_null(p@meta@labels@subtitle)
})

test_that("label_subtitle hide=TRUE 从布局移除", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_subtitle(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.subtitle, "element_blank"))
})

# ---- label_caption ----
test_that("label_caption 同步更新 meta 和 gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_caption(p, "Cap")
  expect_equal(p@meta@labels@caption, "Cap")
  expect_equal(p@gg$labels$caption, "Cap")
})

test_that("label_caption text=NULL 不修改已有脚注", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(text = NULL)
  expect_equal(p@gg$labels$caption, "Old")
  expect_equal(p@meta@labels@caption, "Old")
})

test_that("label_caption reset=TRUE 移除脚注", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(reset = TRUE)
  expect_null(p@gg$labels$caption)
  expect_null(p@meta@labels@caption)
})

test_that("label_caption hide=TRUE 从布局移除", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_caption(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.caption, "element_blank"))
})

# ---- label_axis ----
test_that("label_axis 同步更新 x 轴标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "X Axis", aes = "x")
  expect_equal(p@meta@labels@x, "X Axis")
  expect_equal(p@gg$labels$x, "X Axis")
})

test_that("label_axis 同步更新 y 轴标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "Y Axis", aes = "y")
  expect_equal(p@meta@labels@y, "Y Axis")
  expect_equal(p@gg$labels$y, "Y Axis")
})

test_that("label_axis 部分更新不影响另一轴", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "X Only", aes = "x")
  expect_equal(p@meta@labels@x, "X Only")
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

test_that("label_axis hide=TRUE：隐藏并存储 FALSE 到 meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, hide = TRUE, aes = "x")
  expect_true(inherits(p@gg$theme$axis.title.x, "element_blank"))
  expect_false(p@meta@labels@x)
})

test_that("label_axis text=NULL：不修改当前标签", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  # Set a custom label first, then call with text=NULL (should be no-op)
  p <- label_axis(p, text = "Custom", aes = "x")
  p <- label_axis(p, text = NULL, aes = "x")
  expect_equal(p@gg$labels$x, "Custom")
  expect_equal(p@meta@labels@x, "Custom")
})

test_that("label_axis reset=TRUE：恢复为变量名，meta 存 NULL", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, text = "Custom", aes = "x")
  p <- label_axis(p, reset = TRUE, aes = "x")
  expect_false("x" %in% names(p@gg$labels))
  expect_null(p@meta@labels@x)
})

test_that("label_axis reset=TRUE 覆盖之前自定义", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_false("x" %in% names(p@gg$labels))
})

# ---- label_legend ----
test_that("label_legend 按 aesthetic 设置图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "Species", aes = "colour")
  expect_equal(p@meta@labels@legend[["colour"]], "Species")
  expect_equal(p@gg$labels$colour, "Species")
})

test_that("label_legend 不指定 aes 时影响所有已映射美学", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "All")
  expect_equal(p@meta@labels@legend[["default"]], "All")
  expect_equal(p@gg$labels$colour, "All")
})

test_that("label_legend 全局模式可发现图层级 colour 映射", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  p <- label_legend(p, text = "Species")
  expect_equal(p@meta@labels@legend[["default"]], "Species")
})

test_that("label_legend 图层映射中存在时不警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend hide=TRUE 隐藏图例标题", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, hide = TRUE, aes = "colour")
  expect_null(p@gg$scales$scales[[1]]$name)
})

test_that("label_legend reset=TRUE 恢复默认图例标题（waiver）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(reset = TRUE, aes = "colour")
  expect_true(inherits(p@gg$scales$scales[[1]]$name, "waiver"))
})

test_that("label_legend 不存在的 aes 给出警告", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend 对 fill 生效", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point()
  p <- label_legend(p, text = "Fill", aes = "fill")
  expect_equal(p@meta@labels@legend[["fill"]], "Fill")
})

test_that("label_legend 对 shape 生效", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point()
  p <- label_legend(p, text = "Shape", aes = "shape")
  expect_equal(p@meta@labels@legend[["shape"]], "Shape")
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

# ---- hide + reset combo ----
test_that("label_axis hide=TRUE then reset=TRUE restores", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, hide = TRUE, aes = "x")
  expect_false(p@meta@labels@x)
  p <- label_axis(p, reset = TRUE, aes = "x")
  expect_null(p@meta@labels@x)
})

# ---- text/reset mutual exclusion ----
test_that("label_axis text+reset 互斥报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_axis(p, text = "X", reset = TRUE, aes = "x"),
    "mutually exclusive"
  )
})

test_that("label_title text+reset 互斥报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_title(p, text = "T", reset = TRUE),
    "mutually exclusive"
  )
})
