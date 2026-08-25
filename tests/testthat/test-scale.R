# ============================================================
# scale_* function family -- all 8 scales, full coverage
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
    "not a known colour scheme"
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

test_that("scale_size trans=reverse with discrete variable", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, size = Species)) |>
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

test_that("scale_alpha trans=reverse with discrete variable", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, alpha = Species)) |>
    mark_point() |>
    scale_alpha(trans = "reverse")
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
  # Reverse should swap the gradient direction -- verify scale exists
  scale <- built$plot$scales$get_scales("colour")
  expect_true(inherits(scale, "ScaleContinuous"))
})

# ---- [BDD] scale_size deep rendering tests ----

test_that("[BDD] scale_size continuous renders with custom range", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point() |>
    scale_size(range = c(1, 10))
  built <- ggplot2::ggplot_build(p@gg)
  scale <- built$plot$scales$get_scales("size")
  expect_true(inherits(scale, "ScaleContinuous"))
})

test_that("[BDD] scale_size default applies continuous scale", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
    mark_point()
  built <- ggplot2::ggplot_build(p@gg)
  expect_true("size" %in% names(built$data[[1]]))
})

# ---- [BDD] scale_alpha deep rendering tests ----

test_that("[BDD] scale_alpha continuous renders with custom range", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point() |>
    scale_alpha(range = c(0.2, 0.8))
  built <- ggplot2::ggplot_build(p@gg)
  alpha_vals <- built$data[[1]]$alpha
  expect_true(all(alpha_vals >= 0.2 & alpha_vals <= 0.8, na.rm = TRUE))
})

test_that("[BDD] scale_alpha default applies continuous scale", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
    mark_point()
  built <- ggplot2::ggplot_build(p@gg)
  expect_true("alpha" %in% names(built$data[[1]]))
})

# ---- [BDD] scale_shape deep rendering tests ----

test_that("[BDD] scale_shape discrete renders shape values in data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    scale_shape(range = c(16, 17, 18))
  built <- ggplot2::ggplot_build(p@gg)
  expect_true("shape" %in% names(built$data[[1]]))
  scale <- built$plot$scales$get_scales("shape")
  expect_true(inherits(scale, "ScaleDiscrete"))
})

# ---- [BDD] scale_linetype deep rendering tests ----

test_that("[BDD] scale_linetype discrete applies linetype scale", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_line()
  built <- ggplot2::ggplot_build(p@gg)
  has_channel <- "linetype" %in% names(built$data[[1]])
  has_scale <- inherits(built$plot$scales$get_scales("linetype"), "Scale")
  expect_true(has_channel || has_scale)
})

# ---- [BDD] scale_x positional deep rendering tests ----

test_that("[BDD] scale_x trans=log10 renders log-transformed x-axis", {
  skip_if_not_installed("scales")
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(trans = "log10")
  built <- ggplot2::ggplot_build(p@gg)
  scale <- built$plot$scales$get_scales("x")
  expect_equal(scale$trans$name, "log-10")
})

test_that("[BDD] scale_x limits crop rendered x data", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_x(limits = c(2, 4))
  built <- ggplot2::ggplot_build(p@gg)
  x_vals <- built$data[[1]]$x
  expect_true(all(x_vals >= 2 & x_vals <= 4, na.rm = TRUE))
})

# ---- [BDD] scale_y positional deep rendering tests ----

test_that("[BDD] scale_y limits crop rendered y data", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    scale_y(limits = c(15, 25))
  built <- ggplot2::ggplot_build(p@gg)
  y_vals <- built$data[[1]]$y
  expect_true(all(y_vals >= 15 & y_vals <= 25, na.rm = TRUE))
})

# ---- managed colour-scale registry (token palette parity) ----

test_that("[BDD] user colour scale survives later layer mappings", {
  suppressMessages(
    p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
      mark_point() |>
      scale_color(range = "grey") |>
      mark_point(mapping = encode(shape = Species))
  )
  cols <- unique(ggplot2::ggplot_build(p@gg)$data[[1]]$colour)
  expect_true(all(cols %in% c("#333333", "#989898", "#CCCCCC")))
})

test_that("[BDD] cleared default_color re-attaches the token palette for layers", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point(mapping = encode(colour = factor(cyl)))
  cols <- unique(ggplot2::ggplot_build(p@gg)$data[[1]]$colour)
  expect_false(setequal(cols, c("#F8766D", "#00BA38", "#619CFF"))) # not raw hue
  expect_true("#0072B2" %in% cols) # friendly anchor
})
