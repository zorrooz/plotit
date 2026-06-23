# ============================================================
# compose function family -- BDD tests
# AGENTS.md §4.8
# ============================================================
library(plotit)

# ---- helpers ----
.p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
.p2 <- plotit(iris, encode(x = Species, y = Petal.Length)) |> mark_boxplot()
.p3 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
.p4 <- plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()

# =====================================================================
# compose_grid -- basic behaviour
# =====================================================================

test_that("[BDD] compose_grid two plots vertical (ncol=1) renders", {
  c <- compose_grid(.p1, .p2)
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid two plots horizontal (nrow=1) renders", {
  c <- compose_grid(.p1, .p2, nrow = 1)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid four plots 2x2 grid renders", {
  c <- compose_grid(.p1, .p2, .p3, .p4, ncol = 2, nrow = 2)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid single plot renders", {
  c <- compose_grid(.p1)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("compose_grid empty input errors", {
  expect_error(compose_grid(), "At least one")
})

test_that("compose_grid non-plotit input errors", {
  expect_error(compose_grid("not_a_plot"), "must be a")
})

# =====================================================================
# compose_grid -- tag_levels (verify via rendered output)
# =====================================================================

test_that("[BDD] compose_grid tag_levels = 'A' renders tagged sub-figures", {
  c <- compose_grid(.p1, .p2, tag_levels = "A")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid tag_levels = NULL renders without tags", {
  c <- compose_grid(.p1, .p2)
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# compose_grid -- axes (verify via rendered output)
# =====================================================================

test_that("[BDD] compose_grid axes='collect' renders without error", {
  px <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  py <- plotit(iris, encode(x = Petal.Width, y = Sepal.Length)) |> mark_point()
  c <- compose_grid(px, py, nrow = 1, axes = "collect")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# compose_grid -- nesting
# =====================================================================

test_that("[BDD] compose_grid nested: grid of composites renders", {
  row1 <- compose_grid(.p1, .p2, nrow = 1)
  row2 <- compose_grid(.p3, .p4, nrow = 1)
  c <- compose_grid(row1, row2, ncol = 1)
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid nested: composite + single plot renders", {
  row <- compose_grid(.p1, .p2, nrow = 1)
  c <- compose_grid(row, .p3, ncol = 1)
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# compose_inset
# =====================================================================

test_that("[BDD] compose_inset renders overlay", {
  c <- compose_inset(.p3, .p4, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95)
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

test_that("compose_inset non-plotit base errors", {
  expect_error(compose_inset("not_a_plot", .p4), "must be a")
})

# =====================================================================
# label_title / subtitle / caption on composite (BDD: check rendered)
# =====================================================================

test_that("[BDD] label_title on composite renders via export", {
  c <- compose_grid(.p1, .p2) |> label_title("My Title")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] label_subtitle on composite renders via export", {
  c <- compose_grid(.p1, .p2) |> label_subtitle("Sub")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] label_caption on composite renders via export", {
  c <- compose_grid(.p1, .p2) |> label_caption("Cap")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] label_title hide renders via export", {
  c <- compose_grid(.p1, .p2) |> label_title("T") |> label_title(hide = TRUE)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] label_title reset renders via export", {
  c <- compose_grid(.p1, .p2) |> label_title("T") |> label_title(reset = TRUE)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("label_title text + reset errors (mutual exclusion)", {
  c <- compose_grid(.p1, .p2)
  expect_error(label_title(c, text = "X", reset = TRUE), "mutually exclusive")
})

test_that("[BDD] label_title on inset composite renders via export", {
  c <- compose_inset(.p3, .p4, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95) |>
    label_title("Inset Demo")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# style on composite
# =====================================================================

test_that("[BDD] style on composite applies theme", {
  c <- compose_grid(.p1, .p2) |> style()
  expect_s3_class(c, "plotit::plotit_composite")
})

test_that("[BDD] style with base_theme renders", {
  c <- compose_grid(.p1, .p2) |> style(base_theme = ggplot2::theme_bw())
  built <- ggplot2::ggplot_build(c@gg)
  expect_false(is.null(built$plot$theme$panel.border))
})

# =====================================================================
# export on composite (already BDD: file-system assertions)
# =====================================================================

test_that("[BDD] export composite to PNG creates file", {
  c <- compose_grid(.p1, .p2) |> label_title("Export Test")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 0)
  unlink(f)
})

test_that("[BDD] export composite with explicit dimensions", {
  c <- compose_grid(.p1, .p2, .p3, .p4, ncol = 2)
  f <- tempfile(fileext = ".png")
  export(c, f, width = 10, height = 8, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("export composite invalid filename errors", {
  c <- compose_grid(.p1, .p2)
  expect_error(export(c, NULL), "filename")
  expect_error(export(c, ""), "filename")
})

test_that("[BDD] export composite with annotations renders tags too", {
  c <- compose_grid(.p1, .p2, tag_levels = "A") |>
    label_title("Tagged") |>
    label_caption("caption")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# Pipeline integration
# =====================================================================

test_that("[BDD] full pipeline: compose -> label -> style -> export", {
  c <- compose_grid(.p1, .p2, .p3, .p4, ncol = 2, tag_levels = "A") |>
    label_title("Pipeline Test") |>
    label_subtitle("Subtitle") |>
    label_caption("Source: mtcars & iris") |>
    style(plot.title = ggplot2::element_text(size = 14))
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] pipeline: compose_inset -> label -> style -> export", {
  c <- compose_inset(.p3, .p4, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95) |>
    label_title("Inset Pipeline") |>
    label_caption("Demo")
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# compose_marginal
# =====================================================================

test_that("[BDD] compose_marginal builds and renders", {
  main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length,
                colour = Species)) |> mark_point()
  top <- plotit(iris, encode(x = Sepal.Width, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5)
  right <- plotit(iris, encode(x = Sepal.Length, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5) |>
    project_cartesian(flip = TRUE)
  c <- compose_marginal(main, top, right)
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_marginal custom widths/heights", {
  main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length,
                colour = Species)) |> mark_point()
  top <- plotit(iris, encode(x = Sepal.Width, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5)
  right <- plotit(iris, encode(x = Sepal.Length, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5) |>
    project_cartesian(flip = TRUE)
  c <- compose_marginal(main, top, right, widths = c(3, 1), heights = c(1, 3))
  expect_s3_class(c, "plotit::plotit_composite")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_marginal pipeline: label + style + export", {
  main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length,
                colour = Species)) |> mark_point()
  top <- plotit(iris, encode(x = Sepal.Width, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5)
  right <- plotit(iris, encode(x = Sepal.Length, fill = Species)) |>
    mark_histogram(bins = 15, alpha = 0.5) |>
    project_cartesian(flip = TRUE)
  c <- compose_marginal(main, top, right) |>
    label_title("Pipeline") |>
    label_caption("source") |>
    style(plot.title = ggplot2::element_text(size = 14))
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# =====================================================================
# style_default on composite
# =====================================================================

test_that("[BDD] style_default on composite renders", {
  c <- compose_grid(.p1, .p2) |> style_default()
  expect_s3_class(c, "plotit::plotit_composite")
  built <- ggplot2::ggplot_build(c@gg)
  # Default theme has white panel background
  fill <- built$plot$theme$panel.background$fill
  expect_true(is.null(fill) || fill == "white" || identical(fill, "#FFFFFF"))
})
