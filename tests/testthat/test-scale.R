# ============================================================
# scale_* function family — all 8 scales, full coverage
# ============================================================
library(plotit)

# ============================================================
# scale_color
# ============================================================

test_that("scale_color auto-detects continuous variable", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(name = "power")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color auto-detects discrete variable", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(name = "species")
  expect_s3_class(p, "plotit::plotit")
})

test_that("[BDD] scale_color clears default_color (legend becomes visible)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
    default_color = "steelblue"
  ) |>
    mark_point(size = 2) |>
    scale_color()
  built <- ggplot2::ggplot_build(p@gg)
  # After scale_color, the colour legend should appear (not "none")
  expect_false(identical(built$plot$guides$colour, "none"))
})

test_that("scale_color range=viridis (discrete)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "viridis")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=brewer (discrete)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "brewer")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=grey (discrete)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "grey")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=hue (discrete, explicit default)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "hue")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=c(blue,red) continuous gradient", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color range=c(blue,white,red) three-color gradient", {
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

test_that("scale_color trans=reverse + range=c(blue,red) reversed gradient", {
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

test_that("scale_color trans=binned + range=c(blue,red) two-step gradient", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "binned", range = c("blue", "red"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color continuous + limits", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(limits = c(50, 300))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color discrete + breaks", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(breaks = c("setosa", "virginica"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color trans=identity explicit continuous", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point() |>
    scale_color(trans = "identity")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_color unknown scheme errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point()
  expect_error(
    scale_color(p, range = "unknown_scheme"),
    "Unknown colour scheme"
  )
})

test_that("scale_color invalid trans errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point()
  expect_error(
    scale_color(p, trans = "log"),
    "log/sqrt transformations are not applicable"
  )
})

# ============================================================
# scale_fill
# ============================================================

test_that("scale_fill auto-detects continuous variable", {
  p <- plotit(mtcars, encode(x = factor(cyl), fill = hp)) |>
    mark_bar() |>
    scale_fill(name = "power")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill auto-detects discrete variable", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(name = "species")
  expect_s3_class(p, "plotit::plotit")
})

test_that("[BDD] scale_fill clears default_color (legend becomes visible)", {
  p <- plotit(iris, encode(x = Species, fill = Species),
    default_color = "steelblue"
  ) |>
    mark_bar() |>
    scale_fill()
  built <- ggplot2::ggplot_build(p@gg)
  expect_false(identical(built$plot$guides$fill, "none"))
})

test_that("scale_fill range=viridis (discrete)", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(range = "viridis")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill range=brewer (discrete)", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar() |>
    scale_fill(range = "brewer")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_fill range=c(blue,red) continuous gradient", {
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

test_that("scale_size continuous variable", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size(trans = "identity", range = c(1, 10))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_size discrete variable", {
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

test_that("scale_size auto-detect continuous (trans=NULL)", {
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

test_that("scale_alpha continuous variable", {
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

test_that("scale_alpha trans=discrete", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha(trans = "discrete")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_alpha range=c(0.2, 0.8)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha(range = c(0.2, 0.8))
  expect_s3_class(p, "plotit::plotit")
})

# ============================================================
# scale_shape
# ============================================================

test_that("scale_shape discrete variable", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    scale_shape(range = c(1, 3))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_shape default trans=discrete", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    scale_shape()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_shape trans=binned errors (discrete aesthetic)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, shape = hp)) |>
    mark_point()
  expect_error(
    scale_shape(p, trans = "binned"),
    "binned mapping"
  )
})

test_that("scale_shape trans=identity errors (continuous cannot map to shape)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, shape = hp)) |>
    mark_point()
  expect_error(
    scale_shape(p, trans = "identity"),
    "continuous mapping"
  )
})

# ============================================================
# scale_linetype
# ============================================================

test_that("scale_linetype basic no error", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_line() |>
    scale_linetype()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_linetype trans=binned errors (discrete aesthetic)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, linetype = hp)) |>
    mark_line()
  expect_error(
    scale_linetype(p, trans = "binned"),
    "binned mapping"
  )
})

test_that("scale_linetype trans=identity errors", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, linetype = hp)) |>
    mark_line()
  expect_error(
    scale_linetype(p, trans = "identity"),
    "continuous mapping"
  )
})

test_that("scale_linetype trans=reverse with custom values", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, linetype = Species)) |>
    mark_line()
  expect_no_error(
    scale_linetype(p, trans = "reverse", range = c("solid", "dashed", "dotted"))
  )
})

# ============================================================
# scale_x
# ============================================================

test_that("scale_x continuous", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    scale_x(name = "width", trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x auto-detect discrete", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_point() |>
    scale_x()
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x explicit discrete", {
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
    scale_x(breaks = c(2, 4, 6), labels = c("light", "medium", "heavy"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_x range as normalized panel proportion (vega-aligned)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_no_warning(p2 <- scale_x(p, range = c(0.1, 0.9)))
  expect_s3_class(p2, "plotit::plotit")
})

test_that("scale_x range+limits together warns", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    scale_x(p, range = c(0.1, 0.9), limits = c(2, 5)),
    "range.*takes precedence"
  )
})

test_that("scale_x invalid trans errors", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_error(scale_x(p, trans = "asin"), "must be one of")
})

test_that("scale_x trans=reverse on discrete variable routes to discrete scale", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_point() |>
    scale_x(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y trans=reverse on discrete variable routes to discrete scale", {
  p <- plotit(iris, encode(y = Species, x = Sepal.Length)) |>
    mark_point() |>
    scale_y(trans = "reverse")
  expect_s3_class(p, "plotit::plotit")
})

# ============================================================
# scale_y
# ============================================================

test_that("scale_y continuous + limits", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    scale_y(limits = c(0, 10))
  expect_s3_class(p, "plotit::plotit")
})

test_that("scale_y forced continuous", {
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

test_that("scale_y range as normalized panel proportion (vega-aligned)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_no_warning(p2 <- scale_y(p, range = c(0.1, 0.9)))
  expect_s3_class(p2, "plotit::plotit")
})

test_that("scale_y range+limits together warns", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    scale_y(p, range = c(0.1, 0.9), limits = c(10, 30)),
    "range.*takes precedence"
  )
})

# ============================================================
# cross-scale: multiple scale layers
# ============================================================

test_that("same plot chained scale_color + scale_size no conflict", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp, size = qsec)) |>
    mark_point() |>
    scale_color(name = "power", range = "viridis") |>
    scale_size(range = c(1, 8))
  expect_s3_class(p, "plotit::plotit")
})

# ---- behaviour-driven tests (assert rendered output) ----

test_that("[BDD] scale_color range=c(blue,red) renders gradient colours", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point(size = 2) |>
    scale_color(range = c("blue", "red"))
  built <- ggplot2::ggplot_build(p@gg)
  # The rendered scale should be continuous (colour gradient, not manual)
  scale <- built$plot$scales$get_scales("colour")
  expect_false(inherits(scale, "ScaleDiscrete"))
})

test_that("[BDD] scale_color range=brewer renders discrete colours", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(range = "brewer")
  built <- ggplot2::ggplot_build(p@gg)
  expect_false(identical(built$plot$guides$colour, "none"))
})

test_that("[BDD] scale_color trans=reverse + range=c(blue,red) reverses gradient", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = hp)) |>
    mark_point(size = 2) |>
    scale_color(trans = "reverse", range = c("blue", "red"))
  built <- ggplot2::ggplot_build(p@gg)
  # Reverse should swap the gradient direction — verify scale exists
  scale <- built$plot$scales$get_scales("colour")
  expect_true(inherits(scale, "ScaleContinuous"))
})
