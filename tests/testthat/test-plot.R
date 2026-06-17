library(plotit)

test_that("plotit() 初始化应用默认主题并设置 plotit_theme_managed 标记", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("plotit() default_color 在无 color/fill 映射时存入 meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  )
  expect_equal(p@meta@default_color, "steelblue")
  expect_true(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color 在有 colour 映射时不在 meta 中存储", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
    default_color = "steelblue"
  )
  # 有 colour 映射 -> default_color 不被注入
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$colour))
  expect_false(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color 在有 fill 映射时不在 meta 中存储", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species),
    default_color = "steelblue"
  )
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$fill))
})

test_that("plotit() default_color = NULL 时不注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = NULL
  )
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("plotit() 拒绝非法 unit（不受 autofit 影响）", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      size_unit = "ft"
    ),
    "unit"
  )
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = TRUE, size_unit = "ft"
    ),
    "unit"
  )
})

# ---- patchwork 集成 ----
test_that("plotit() 始终添加 plot_layout 固定面板尺寸", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 6, height = 4, size_unit = "in"
  )
  expect_true(inherits(p@gg, "patchwork"))
})

test_that("plotit() autofit=TRUE 时不添加 patchwork 布局", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  )
  expect_false(inherits(p@gg, "patchwork"))
})

# ---- plotit() 基本构造与守卫 ----
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

test_that("plotit() autofit=FALSE 时要求 width 和 height", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = FALSE, width = NULL, height = 5
    ),
    "both.*width.*height"
  )
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = FALSE, width = 7, height = NULL
    ),
    "both.*width.*height"
  )
})

test_that("plotit() autofit=TRUE 时忽略 width/height 但保留 unit", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, width = 100, height = 100
  )
  expect_null(p@meta@width)
  expect_null(p@meta@height)
  expect_equal(p@meta@unit, "in")
})

test_that("plotit() size_unit 不受 autofit 影响始终验证", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = TRUE, size_unit = "ft"
    ),
    "unit"
  )
})
