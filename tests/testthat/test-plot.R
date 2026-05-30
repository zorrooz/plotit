library(plotit)

test_that("plotit() 初始化应用默认主题并设置 plotit_applied 标记", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@gg$theme, "plotit_applied"))
})

test_that("plotit() default_color 在无 color/fill 映射时存入 meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = "steelblue")
  expect_equal(p@meta@default_color, "steelblue")
  expect_true(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color 在有 colour 映射时不在 meta 中存储", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
            default_color = "steelblue")
  # 有 colour 映射 -> default_color 不被注入
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$colour))
  expect_false(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color 在有 fill 映射时不在 meta 中存储", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species),
            default_color = "steelblue")
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$fill))
})

test_that("plotit() default_color = NULL 时不注入", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
            default_color = NULL)
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("plotit() 拒绝非法 unit", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
         size_unit = "ft"),
    "unit"
  )
})
