# Visual style contract (tidyplots-calibrated).
# Pins the numbers that define the package look. Changing a default in
# R/theme.R or R/mark_style.R MUST update this file in the same commit --
# that is the point: style is an intentional, reviewable contract, not
# accidental drift. Do NOT duplicate per-mark prose in AGENTS.md.

.built <- function(p) {
  ggplot2::ggplot_build(p@gg)$data
}

testthat::test_that("[contract] theme tokens: classic base, 6.5pt, bold title, 0.35 hairline", {
  thm <- plotit:::._theme_default()
  tok <- plotit:::._STYLE_TOKENS
  testthat::expect_equal(tok$base_size, 6.5)
  testthat::expect_equal(tok$lw_axis, 0.35)
  testthat::expect_equal(tok$size_title, 7)
  testthat::expect_equal(tok$size_legend_text, 5.8)
  testthat::expect_equal(tok$palette_discrete[[1]], "#0072B2")
  testthat::expect_equal(thm$text$size, 6.5)
  testthat::expect_equal(thm$plot.title$face, "bold")
  testthat::expect_equal(thm$plot.title$hjust, 0)
  testthat::expect_equal(thm$axis.line$linewidth, 0.35)
  testthat::expect_s3_class(thm$panel.border, "element_blank")
  testthat::expect_equal(thm$plot.background$fill, "#FFFFFF")
})

testthat::test_that("[contract] default canvas is Nature single column 89 x 56 mm", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> plotit::mark_point()
  testthat::expect_equal(p@meta@width, 89)
  testthat::expect_equal(p@meta@height, 56)
  testthat::expect_equal(p@meta@unit, "mm")

  # Explicit size still wins
  p3 <- plotit(mtcars, encode(x = wt, y = mpg),
               width = 50, height = 40, size_unit = "mm") |>
    plotit::mark_point()
  testthat::expect_equal(p3@meta@width, 50)
})

testthat::test_that("[contract] mark tokens: strokes, alphas, widths", {
  st <- plotit:::._MARK_STYLE
  testthat::expect_equal(st$lw_data, 0.25)
  testthat::expect_equal(st$lw_thin, 0.5)
  testthat::expect_equal(st$alpha_fill, 0.3)
  testthat::expect_equal(st$alpha_ci, 0.4)
  testthat::expect_equal(st$primary, "#0072B2")

  d <- plotit:::._MARK_DEFAULTS
  testthat::expect_equal(d$mark_bar$width, 0.6)
  testthat::expect_equal(d$mark_bar$linewidth, 0)
  testthat::expect_equal(d$mark_point$size, 1)
  testthat::expect_equal(d$mark_boxplot$width, 0.6)
  testthat::expect_equal(d$mark_boxplot$alpha, 0.3)
  testthat::expect_equal(d$mark_boxplot$staplewidth, 0.8)
  testthat::expect_equal(d$mark_boxplot$outlier.size, 0.5)
  testthat::expect_null(d$mark_boxplot$colour) # outline follows colour map
  testthat::expect_equal(d$mark_errorbar$width, 0.4)
  testthat::expect_equal(d$mark_errorbar$linewidth, 0.25)
  testthat::expect_equal(d$mark_ribbon$alpha, 0.4)
  testthat::expect_true(is.na(d$mark_ribbon$colour))
  testthat::expect_equal(d$mark_line$linewidth, 0.25)
})

testthat::test_that("[contract] rendered bar/box match tidyplots proportions", {
  df <- data.frame(g = rep(c("a", "b"), each = 3), y = 1:6)
  pb <- plotit(df, encode(x = g, y = y, fill = g)) |> plotit::mark_bar()
  bd <- .built(pb)[[1]]
  testthat::expect_true(all(abs((bd$xmax - bd$xmin) - 0.6) < 1e-6))
  testthat::expect_true(all(bd$linewidth == 0))

  pbox <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    plotit::mark_boxplot()
  bd2 <- .built(pbox)[[1]]
  testthat::expect_true(all(abs((bd2$xmax - bd2$xmin) - 0.6) < 1e-6))
  testthat::expect_true(all(abs(bd2$alpha - 0.3) < 1e-6))
  testthat::expect_true(all(bd2$staplewidth == 0.8))
  testthat::expect_true(all(bd2$outlier.size == 0.5))
})

testthat::test_that("[contract] colour and fill are mirrored at construction", {
  # tidyplots rule: one categorical channel drives both outline and fill
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    plotit::mark_boxplot()
  d <- .built(p)[[1]]
  testthat::expect_setequal(unique(as.character(d$colour)), unique(as.character(d$fill)))
  testthat::expect_false(any(as.character(d$colour) %in% c("grey20", "#333333", "grey30")))
})

testthat::test_that("[contract] single-colour injection is friendly blue", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> plotit::mark_point()
  testthat::expect_equal(unique(.built(p)[[1]]$colour), "#0072B2")
})

testthat::test_that("[contract] user parameters beat mark defaults", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    plotit::mark_line(linewidth = 1.2)
  testthat::expect_equal(unique(.built(p)[[1]]$linewidth), 1.2)

  p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    plotit::mark_boxplot(alpha = 0.9)
  testthat::expect_equal(unique(.built(p2)[[1]]$alpha), 0.9)
})
