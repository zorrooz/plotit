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

testthat::test_that("[contract] every catalogue mark has a style story", {
  d <- plotit:::._MARK_DEFAULTS
  ch <- plotit:::._MARK_CHROME
  # Core visual marks that must carry explicit defaults
  must_default <- c(
    "mark_bar", "mark_point", "mark_line", "mark_path", "mark_step",
    "mark_boxplot", "mark_violin", "mark_density", "mark_histogram",
    "mark_area", "mark_ribbon", "mark_smooth", "mark_errorbar",
    "mark_ecdf", "mark_qq", "mark_qq_line", "mark_rect", "mark_bin2d",
    "mark_hex", "mark_corr", "mark_heatmap", "mark_contour",
    "mark_density_2d", "mark_rug", "mark_text", "mark_label",
    "mark_beeswarm", "mark_polygon"
  )
  for (nm in must_default) {
    testthat::expect_true(nm %in% names(d), label = nm)
  }
  testthat::expect_equal(d$mark_beeswarm$size, 1)
  testthat::expect_equal(d$mark_beeswarm$cex, 3)
  testthat::expect_equal(d$mark_qq$size, 1)
  testthat::expect_equal(d$mark_text$size, 3.2)
  testthat::expect_equal(d$mark_hex$linewidth, 0)
  testthat::expect_equal(d$mark_heatmap$linewidth, 0)
  testthat::expect_equal(d$mark_rug$linewidth, 0.25)
  testthat::expect_equal(d$mark_contour$linewidth, 0.25)
  # Relational chrome blank
  for (nm in c("mark_sankey", "mark_treemap", "mark_network", "mark_chord", "mark_map")) {
    testthat::expect_equal(ch[[nm]]$axis, "blank", label = nm)
  }
})

testthat::test_that("[contract] mapped aesthetics drive mark colours", {
  df <- data.frame(
    g = rep(c("A", "B"), each = 6),
    x = rep(1:6, 2),
    y = c(1:6, 4:9),
    y2 = c(3:8, 6:11)
  )
  cols <- function(p) {
    bd <- ggplot2::ggplot_build(p@gg)
    unique(as.character(bd$data[[1]]$colour))
  }
  expect_grouped <- function(p, label) {
    c <- cols(p)
    testthat::expect_true(any(c %in% c("#0072B2", "#D55E00")), label = label)
  }
  # lollipop stems follow mapped colour
  expect_grouped(plotit(df, encode(x = g, y = y, colour = g)) |> plotit::mark_lollipop(), "lolli")
  # dumbbell points follow mapped colour when groups are mixed
  expect_grouped(plotit(df, encode(x = g, y = y, yend = y2, colour = g)) |> plotit::mark_dumbbell(), "dumb")
  # default dumbbell: start=primary, end=secondary (no mapped colour)
  p0 <- plotit(df, encode(x = g, y = y, yend = y2)) |> plotit::mark_dumbbell()
  allc <- unique(unlist(lapply(ggplot2::ggplot_build(p0@gg)$data, function(d) d$colour)))
  testthat::expect_true("#0072B2" %in% allc)
  testthat::expect_true("#E15759" %in% allc)
  # explicit stem override wins
  pc <- plotit(df, encode(x = g, y = y, colour = g)) |>
    plotit::mark_lollipop(stem_color = "red")
  testthat::expect_true("red" %in% cols(pc))
  # user alpha / size beat defaults
  pa <- plotit(df, encode(x = g, y = y, fill = g)) |> plotit::mark_bar(alpha = 0.2)
  testthat::expect_equal(unique(ggplot2::ggplot_build(pa@gg)$data[[1]]$alpha), 0.2)
  ps <- plotit(df, encode(x = x, y = y)) |> plotit::mark_point(size = 4)
  testthat::expect_equal(unique(ggplot2::ggplot_build(ps@gg)$data[[1]]$size), 4)
})

testthat::test_that("[contract] user parameters beat mark defaults", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    plotit::mark_line(linewidth = 1.2)
  testthat::expect_equal(unique(.built(p)[[1]]$linewidth), 1.2)

  p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    plotit::mark_boxplot(alpha = 0.9)
  testthat::expect_equal(unique(.built(p2)[[1]]$alpha), 0.9)
})
