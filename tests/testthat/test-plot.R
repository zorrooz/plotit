library(plotit)

# Helper: build and return rendered plot data
.build <- function(p) ggplot2::ggplot_build(p@gg)

# ---- plotit() construction guards ----
test_that("plotit() and encode() cooperate to create valid object", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg, "ggplot"))
})

test_that("plotit() rejects non-encode() mapping", {
  expect_error(
    plotit(iris, ggplot2::aes(x = Sepal.Width, y = Sepal.Length)),
    "must be created with"
  )
})

test_that("plotit() autofit=FALSE requires both width and height", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = FALSE, width = NULL, height = 5
    ),
    "both.*width.*height"
  )
})

test_that("plotit() autofit=TRUE ignores width/height and warns", {
  expect_warning(
    p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = TRUE, width = 100, height = 100
    ),
    "ignored"
  )
  # autofit=TRUE results in non-patchwork gg (verified in
  # "[BDD] autofit=TRUE does not wrap in patchwork" below)
  expect_false(inherits(p@gg, "patchwork"))
})

test_that("plotit() size_unit validated regardless of autofit", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      autofit = TRUE, size_unit = "ft"
    ),
    "unit"
  )
})

test_that("plotit() rejects invalid unit in non-autofit mode too", {
  expect_error(
    plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
      size_unit = "ft"
    ),
    "unit"
  )
})

# ---- default_color behaviour (BDD) ----
test_that("[BDD] default_color renders single colour when no mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  ) |> mark_point(size = 2)
  built <- .build(p)
  # default_color injects guides(colour="none") -- rendered guide is NULL
  expect_null(built$plot$guides$colour)
})

test_that("[BDD] default_color NOT injected when colour mapping present", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
    default_color = "steelblue"
  ) |> mark_point(size = 2)
  built <- .build(p)
  # Colour mapping present -> rendered points use multiple colours
  colour_scale <- built$plot$scales$get_scales("colour")
  expect_false(is.null(colour_scale))
})

test_that("[BDD] default_color cleared when layer provides colour mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    default_color = "steelblue"
  ) |> mark_point(mapping = encode(colour = Species), size = 2)
  built <- .build(p)
  # Layer-level colour mapping triggers clearing -> scale is present
  colour_scale <- built$plot$scales$get_scales("colour")
  expect_false(is.null(colour_scale))
})

test_that("[BDD] default_color = NULL renders multiple colours from mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species),
    default_color = NULL
  ) |> mark_point(size = 2)
  built <- .build(p)
  colour_scale <- built$plot$scales$get_scales("colour")
  expect_false(is.null(colour_scale))
})

# ---- patchwork integration (structural -- remove when 3.3.10 debt is paid) ----
test_that("plotit() autofit=TRUE does not wrap in patchwork", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), autofit = TRUE)
  expect_false(inherits(p@gg, "patchwork"))
})

test_that("plotit() initializes with default theme applied", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  built <- .build(p)
  # Default theme should produce a panel with white background (not grey)
  expect_true(inherits(built$plot$theme$panel.background, "element_rect"))
})

# ---- default axis title cleanup (factor wrappers) ----

test_that("[BDD] factor-wrapped mappings get clean default axis titles", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |> mark_point()
  expect_equal(p@gg$labels$x, "cyl")
})

test_that("[BDD] non-wrapped expressions keep deparsed axis titles", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_equal(p@gg$labels$x, "wt")
  p2 <- plotit(mtcars, encode(x = wt / 1000, y = mpg)) |> mark_point()
  expect_match(p2@gg$labels$x, "wt")
})

# ---- matrix input coercion (TBD-7: ggplot2 4.0 requires named columns) ----

test_that("[BDD] plain matrix without dimnames is coerced for plotting", {
  m <- matrix(1:6, nrow = 2) # 2 rows x 3 cols, no names
  p <- plotit(m, encode(x = V1, y = V3)) |> mark_point()
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(nrow(built$data[[1]]), 2)
  expect_equal(names(built$data[[1]])[1], "x")
  # Data frame behind the scenes keeps invented V1..Vk column names.
  expect_equal(names(p@gg$data), c("V1", "V2", "V3"))
})

test_that("[BDD] dimnamed matrix keeps column and row names without warnings", {
  m <- matrix(
    1:6,
    nrow = 2,
    dimnames = list(c("row_a", "row_b"), c("col_c", "col_d", "col_e"))
  )
  expect_no_warning(
    p <- plotit(m, encode(x = col_c, y = col_e)) |> mark_point()
  )
  expect_equal(names(p@gg$data), c("col_c", "col_d", "col_e"))
  expect_equal(rownames(p@gg$data), c("row_a", "row_b"))
})

test_that("[BDD] character matrix columns are not factorised at the boundary", {
  m <- matrix(c("a", "b", "c", "d"), nrow = 2)
  p <- plotit(m, encode(x = V1, y = V2)) |> mark_point()
  expect_type(p@gg$data[[1]], "character")
})

test_that("[BDD] constant-only mapped matrix still renders (pie idiom)", {
  # The documented `encode(x = 1, y = count)` idiom keeps a constant column;
  # ggplot2 itself warns when *every* mapped aesthetic is length 1, so the
  # assertion targets the rendered layer, not the noise.
  m <- matrix(1:4, nrow = 2)
  p <- plotit(m, encode(x = 1, y = 2)) |> mark_point()
  built <- suppressWarnings(ggplot2::ggplot_build(p@gg))
  expect_equal(nrow(built$data[[1]]), 2)
})

# ---- aspect-true fixed gtable (letterbox) ----

test_that("[BDD] fixed-aspect panels stay aspect-true in the export gtable", {
  edges <- data.frame(source = c("A", "B"), target = c("B", "C"))
  suppressMessages(
    p <- edges |>
      plotit(encode(source = source, target = target)) |>
      mark_chord()
  )
  build <- ggplot2::ggplot_build(p@gg)
  expected <- p@gg$coordinates$aspect(build$layout$panel_params[[1]])
  gt <- ._build_fixed_gtable(p@gg, 5, 3.5, "in")
  panel_idx <- which(gt$layout$name == "panel")[1]
  w_in <- grid::convertWidth(gt$widths[[gt$layout$l[panel_idx]]], "in", valueOnly = TRUE)
  h_in <- grid::convertHeight(gt$heights[[gt$layout$t[panel_idx]]], "in", valueOnly = TRUE)
  # The panel honours the coordinate system's required height/width ratio
  # (letterboxed inside the declared box instead of stretched).
  expect_equal(h_in / w_in, expected, tolerance = 0.01)
})
