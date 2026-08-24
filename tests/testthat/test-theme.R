# Tests for the centralised style module (R/theme.R): visual tokens, default
# theme recipe, curated default colour scales, and WYSIWYG panel sizing.

# ---- helpers ----
built_colours <- function(p, layer = 1, aes = "colour") {
  bd <- ggplot2::ggplot_build(p@gg)
  unique(as.character(bd$data[[layer]][[aes]]))
}

testthat::test_that("[BDD] style tokens expose the friendly palette anchors", {
  tok <- plotit:::._STYLE_TOKENS
  testthat::expect_length(tok$palette_discrete, 6)
  testthat::expect_equal(tok$palette_discrete[[1]], "#0072B2")
  testthat::expect_equal(tok$ink, "#000000")
  testthat::expect_equal(plotit:::._ink_mix(0), "#000000")
  testthat::expect_equal(tolower(plotit:::._ink_mix(1)), "#ffffff")
})

testthat::test_that("[BDD] discrete palette sampling subsamples then interpolates", {
  pal3 <- plotit:::._palette_discrete(3)
  testthat::expect_length(pal3, 3)
  testthat::expect_true(all(pal3 %in% plotit:::._STYLE_TOKENS$palette_discrete))
  pal10 <- plotit:::._palette_discrete(10)
  testthat::expect_length(pal10, 10)
  testthat::expect_false(all(pal10 %in% plotit:::._STYLE_TOKENS$palette_discrete))
})

testthat::test_that("[BDD] default theme follows the academic-minimal recipe", {
  thm <- plotit:::._theme_default()
  testthat::expect_equal(thm$axis.line$linewidth, 0.25)
  testthat::expect_equal(thm$axis.line$colour, "#000000")
  testthat::expect_s3_class(thm$panel.grid, "element_blank")
  testthat::expect_false(thm$plot.title$face == "bold")
  testthat::expect_equal(as.numeric(thm$legend.key.size), 3.5)
})

testthat::test_that("[BDD] fixed panel dimensions are baked into every plot", {
  p <- plotit(mtcars,
    encode(x = wt, y = mpg),
    autofit = FALSE, width = 7, height = 5, size_unit = "in"
  ) |>
    mark_point()
  testthat::expect_false(is.null(p@gg$theme$panel.widths))
  gt <- plotit:::._build_fixed_gtable(p@gg, 7, 5, "in")
  w_in <- grid::convertWidth(sum(gt$widths), "in", valueOnly = TRUE)
  testthat::expect_gte(w_in, 7 * 0.99)
})

testthat::test_that("[BDD] autofit plots carry no absolute panel constraint", {
  p <- plotit(mtcars, encode(x = wt, y = mpg), autofit = TRUE) |> mark_point()
  testthat::expect_null(p@gg$theme$panel.widths)
})

testthat::test_that("[BDD] strip removes baked panel size via public reset", {
  p <- plotit(mtcars,
    encode(x = wt, y = mpg),
    autofit = FALSE, width = 7, height = 5, size_unit = "in"
  )
  stripped <- plotit:::._strip_panel_size(p@gg)
  testthat::expect_null(stripped$theme$panel.widths)
  testthat::expect_null(stripped$theme$panel.heights)
  # No-op when nothing is baked
  bare <- ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg))
  testthat::expect_identical(plotit:::._strip_panel_size(bare), bare)
})

testthat::test_that("[BDD] mapped discrete aesthetics default to friendly colours", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_bar()
  fills <- built_colours(p, aes = "fill")
  testthat::expect_length(fills, 3)
  testthat::expect_true(all(fills %in% c(
    "#0072B2", "#56B4E9", "#009E73", "#F5C710", "#E69F00", "#D55E00"
  )))
  testthat::expect_false("#F8766D" %in% fills)
})

testthat::test_that("[BDD] mapped continuous aesthetics default to viridis", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = disp)) |> mark_point()
  cols <- built_colours(p)
  testthat::expect_false("#F8766D" %in% cols)
  testthat::expect_gte(length(unique(cols)), 10)
})

testthat::test_that("[BDD] AsIs constant colours bypass the default palette", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = I("red"))) |> mark_point()
  testthat::expect_equal(built_colours(p), "red")
})

testthat::test_that("[BDD] single-colour injection stays brand blue", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  testthat::expect_equal(built_colours(p), "#4E79A7")
})

testthat::test_that("[BDD] user scale calls override the construction defaults", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_bar() |>
    scale_fill(range = "grey")
  fills <- built_colours(p, aes = "fill")
  is_grey <- vapply(fills, function(hex) {
    rgbv <- grDevices::col2rgb(hex)[, 1]
    length(unique(rgbv)) == 1
  }, logical(1))
  testthat::expect_true(all(is_grey))
})

testthat::test_that("[BDD] explicit friendly scheme supports reverse", {
  fwd <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(trans = "discrete", range = "friendly")
  rev <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    scale_color(trans = "discrete", range = "friendly", limits = rev(levels(iris$Species)))
  cf <- built_colours(fwd)
  cr <- built_colours(rev)
  testthat::expect_length(cf, 3)
  testthat::expect_setequal(cf, cr)
})
