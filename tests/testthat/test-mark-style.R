# Tests for the unified mark style system (R/mark_style.R)
#
# [BDD] As a plotit user, I want every mark to share one coherent default
# look, with my explicit parameters and mapped aesthetics always winning.

# Build helper: run the pipeline and return ggplot_build data
.built <- function(p) {
  ggplot2::ggplot_build(p@gg)$data
}

test_that("[BDD] mark_line applies the unified data-line default", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_line()
  expect_equal(unique(.built(p)[[1]]$linewidth), 0.9)
})

test_that("[BDD] explicit parameters override mark style defaults", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_line(linewidth = 0.8)
  expect_equal(unique(.built(p)[[1]]$linewidth), 0.8)
})

test_that("[BDD] grouped bars get a white hairline border", {
  df <- data.frame(g = rep(c("a", "b"), each = 3), y = 1:6)
  p <- plotit(df, encode(x = g, y = y, fill = g)) |> mark_bar()
  expect_true(all(.built(p)[[1]]$colour == "white"))
  expect_equal(unique(.built(p)[[1]]$linewidth), 0.25)
})

test_that("[BDD] injected single-colour bars stay borderless", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |> mark_bar()
  d <- .built(p)[[1]]
  expect_false(any(d$colour == "white"))
  expect_true(all(d$fill == "#4E79A7"))
})

test_that("[BDD] histogram shares the bar border default", {
  p <- plotit(iris, encode(x = Sepal.Width)) |> mark_histogram()
  expect_equal(unique(.built(p)[[1]]$linewidth), 0.25)
})

test_that("[BDD] density and violin render translucent fills", {
  pd <- plotit(iris, encode(x = Sepal.Width)) |> mark_density()
  pv <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_violin()
  expect_equal(unique(.built(pd)[[1]]$alpha), 0.6)
  expect_equal(unique(.built(pv)[[1]]$alpha), 0.6)
})

test_that("[BDD] mapped alpha beats the translucency default", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, alpha = cyl)) |>
    mark_point(alpha = 0.3)
  expect_equal(unique(.built(p)[[1]]$alpha), 0.3)
})

test_that("[BDD] boxplot gains a contrast stroke under injected default color", {
  p <- plotit(iris, encode(x = Species, y = Petal.Length)) |> mark_boxplot()
  d <- .built(p)[[1]]
  expect_equal(unique(d$colour), "grey30")
  expect_true(all(d$fill == "#4E79A7"))
})

test_that("[BDD] boxplot respects a user colour mapping", {
  p <- plotit(iris, encode(x = Species, y = Petal.Length, colour = Species)) |>
    mark_boxplot()
  d <- .built(p)[[1]]
  expect_false(any(d$colour == "grey30"))
})

test_that("[BDD] reference lines default to the soft neutral", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_rule(yintercept = 20)
  d <- .built(p)[[1]]
  expect_equal(unique(d$colour), "grey50")
  expect_equal(unique(d$linewidth), 0.5)
})

test_that("[BDD] explicit rule colour is preserved", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_rule(yintercept = 20, colour = "red")
  expect_equal(unique(.built(p)[[1]]$colour), "red")
})

test_that("[BDD] area and polygon drop their outline by default", {
  pa <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |> mark_area()
  tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
  pp <- plotit(tri, encode(x = x, y = y)) |> mark_polygon()
  expect_equal(unique(.built(pa)[[1]]$linewidth), 0)
  expect_equal(unique(.built(pp)[[1]]$linewidth), 0)
})

test_that("[BDD] smooth trend lines use the data-line weight", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_smooth(se = FALSE)
  expect_equal(unique(.built(p)[[1]]$linewidth), 0.9)
})

test_that("[BDD] correlation matrix defaults to viridis", {
  p <- plotit(mtcars, encode()) |> mark_corr()
  fills <- unique(.built(p)[[1]]$fill)
  # legacy muted gradient must be gone; viridis max yellow present (corr = 1)
  expect_false("#132B43" %in% fills)
  expect_true("#FDE725" %in% fills)
})

test_that("[BDD] corr viridis default is replaceable by scale_fill", {
  p1 <- plotit(mtcars, encode()) |> mark_corr()
  p2 <- suppressMessages(p1 |> scale_fill(trans = "identity"))
  expect_identical(
    .built(p1)[[1]]$fill,
    .built(p2)[[1]]$fill
  )
})

test_that("[BDD] hex bins default to viridis", {
  skip_if_not_installed("hexbin")
  p <- plotit(
    ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 500), ],
    encode(x = carat, y = price)
  ) |> mark_hex()
  fills <- unique(.built(p)[[1]]$fill)
  expect_false("#132B43" %in% fills)
  expect_true("#FDE725" %in% fills)
})

test_that("[BDD] filled 2D density bands default to discrete viridis", {
  p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_density_2d(filled = TRUE)
  p2 <- suppressMessages(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
      mark_density_2d(filled = TRUE) |>
      scale_fill(trans = "discrete", range = "viridis")
  )
  fills <- unique(.built(p1)[[1]]$fill)
  expect_false("#132B43" %in% fills)
  expect_identical(fills, unique(.built(p2)[[1]]$fill))
})

test_that("[BDD] significance brackets use unified tokens", {
  df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
  comp <- data.frame(group1 = "A", group2 = "B", label = "*")
  p <- plotit(df, encode(x = group, y = value)) |>
    mark_bar() |>
    mark_significance(comp, y_position = 9)
  datas <- .built(p)
  seg_lw <- unlist(lapply(datas, function(d) if (!is.null(d$linewidth)) unique(d$linewidth)))
  expect_true(0.5 %in% seg_lw)
  txt_size <- unlist(lapply(datas, function(d) if (!is.null(d$size)) unique(d$size)))
  expect_true(any(abs(txt_size - 3.2) < 0.01))
})

test_that("[BDD] custom marks registered via make_mark are unaffected", {
  skip_if_not_installed("ggbeeswarm")
  make_mark("mark_spoke_style_probe", ggplot2::geom_spoke)
  df <- data.frame(x = 1:3, y = 1:3, angle = 0, radius = 0.2)
  p <- df |>
    plotit(encode(x = x, y = y, angle = angle, radius = radius)) |>
    mark_spoke_style_probe()
  expect_s3_class(ggplot2::ggplot_build(p@gg), "ggplot_built")
})

# ---- bar slot width (AGENTS.md 6: slim bars with air) ----

test_that("[BDD] bars default to 0.7 of the slot", {
  p <- plotit(ggplot2::mpg, encode(x = class, y = hwy)) |> mark_bar()
  d <- .built(p)[[1]]
  expect_true(all(abs((d$xmax - d$xmin) - 0.7) < 1e-6))
})

test_that("[BDD] explicit width overrides the bar default", {
  p <- plotit(ggplot2::mpg, encode(x = class, y = hwy)) |>
    mark_bar(width = 0.4)
  d <- .built(p)[[1]]
  expect_true(all(abs((d$xmax - d$xmin) - 0.4) < 1e-6))
})

# ---- closed-cell heatmap chrome (tile / corr) ----

test_that("[BDD] closed-cell marks drop axis furniture and expansion", {
  df <- data.frame(
    x = rep(LETTERS[1:3], 3), y = rep(1:3, each = 3), z = 1:9
  )
  p <- df |>
    plotit(encode(x = x, y = y, fill = z)) |>
    mark_rect()
  thm <- ggplot2::ggplot_build(p@gg)$plot$theme
  expect_s3_class(thm$axis.line, "element_blank")
  expect_s3_class(thm$axis.ticks, "element_blank")
  expect_false(inherits(thm$axis.text, "element_blank")) # labels stay
  expect_false(isTRUE(p@gg$coordinates$expand)) # cells touch panel edges
})

test_that("[BDD] correlation heatmap blanks synthetic axis titles", {
  p <- plotit(mtcars[, c("mpg", "hp", "wt")], encode()) |> mark_corr()
  thm <- ggplot2::ggplot_build(p@gg)$plot$theme
  expect_s3_class(thm$axis.title, "element_blank") # Var1/Var2 carry no meaning
  expect_s3_class(thm$axis.line, "element_blank")
  expect_false(inherits(thm$axis.text, "element_blank")) # variable names stay
})
