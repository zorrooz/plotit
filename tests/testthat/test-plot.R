library(plotit)

test_that("plotit() initializes with default theme and sets managed flag", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(attr(p@meta, "plotit_theme_managed"))
})

test_that("plotit() default_color stored in meta when no color/fill mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  )
  expect_equal(p@meta@default_color, "steelblue")
  expect_true(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color not stored when colour mapping present", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
    default_color = "steelblue"
  )
  # colour mapping present -> default_color not injected
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$colour))
  expect_false(inherits(p@gg$mapping$colour, "AsIs"))
})

test_that("plotit() default_color not stored when fill mapping present", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species),
    default_color = "steelblue"
  )
  expect_null(p@meta@default_color)
  expect_true(is.call(p@gg$mapping$fill))
})

test_that("default_color auto-resets when layer provides colour mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  )
  expect_equal(p@meta@default_color, "steelblue")
  p <- mark_point(p, mapping = encode(colour = Species))
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("plotit() default_color = NULL does not inject", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = NULL
  )
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("plotit() rejects invalid unit (regardless of autofit)", {
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

# ---- patchwork integration ----
test_that("plotit() always adds plot_layout to fix panel size", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 6, height = 4, size_unit = "in"
  )
  expect_true(inherits(p@gg, "patchwork"))
})

test_that("plotit() autofit=TRUE does not add patchwork layout", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  )
  expect_false(inherits(p@gg, "patchwork"))
})

# ---- plotit() basic construction and guards ----
test_that("plotit() and encode() cooperate to create plotit object", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg, "ggplot"))
  expect_true(inherits(p@meta, "plotit::plotit_metadata"))
})

test_that("plotit() rejects non-encode() mapping", {
  expect_error(
    plotit(iris, ggplot2::aes(x = Sepal.Width, y = Sepal.Length)),
    "must be created with"
  )
})

test_that("plotit() autofit=FALSE requires width and height", {
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

test_that("plotit() autofit=TRUE ignores width/height but retains unit", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, width = 100, height = 100
  )
  expect_null(p@meta@width)
  expect_null(p@meta@height)
  expect_equal(p@meta@unit, "in")
})

test_that("plotit() size_unit validated regardless of autofit", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = TRUE, size_unit = "ft"
    ),
    "unit"
  )
})
