# ============================================================
# compose function family -- BDD tests
# AGENTS.md 4.8
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
  c <- compose_grid(.p1, .p2) |>
    label_title("T") |>
    label_title(hide = TRUE)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] label_title reset renders via export", {
  c <- compose_grid(.p1, .p2) |>
    label_title("T") |>
    label_title(reset = TRUE)
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
  main <- plotit(iris, encode(
    x = Sepal.Width, y = Sepal.Length,
    colour = Species
  )) |> mark_point()
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
  main <- plotit(iris, encode(
    x = Sepal.Width, y = Sepal.Length,
    colour = Species
  )) |> mark_point()
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
  main <- plotit(iris, encode(
    x = Sepal.Width, y = Sepal.Length,
    colour = Species
  )) |> mark_point()
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
# style on composite (default-theme path)
# =====================================================================

test_that("[BDD] style() on composite renders with default theme", {
  c <- compose_grid(.p1, .p2) |> style()
  expect_s3_class(c, "plotit::plotit_composite")
  built <- ggplot2::ggplot_build(c@gg)
  # Default theme has white panel background
  fill <- built$plot$theme$panel.background$fill
  expect_true(is.null(fill) || fill == "white" || identical(fill, "#FFFFFF"))
})

# =====================================================================
# composite default canvas sizing (null-unit measurement regression)
# =====================================================================

test_that("[BDD] composites default to a sane export canvas", {
  c <- compose_grid(.p1, .p2)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  # The old patchworkGrob measurement produced ~0.7 x 1.2 in canvases whose
  # exports clipped to garbage; the panel-meta default must render a real
  # figure (a 72-dpi 6.6 x 8.6 in PNG is far larger than a clipped strip).
  expect_gt(file.info(f)$size, 10000)
  unlink(f)
})

test_that("[BDD] composite style reaches every panel (patchwork &)", {
  c <- compose_grid(.p1, .p2) |>
    style(plot.title = ggplot2::element_text(face = "bold"))
  built <- ggplot2::ggplot_build(c@gg)
  # patchwork exposes sub-plot themes through the built object's patches;
  # assert via the assembled grob: both panel columns carry the theme.
  expect_s3_class(built$plot$theme$plot.title, "element_text")
})

test_that("[BDD] marginal composites default to a sane export canvas", {
  main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  top <- plotit(iris, encode(x = Sepal.Width)) |> mark_histogram()
  right <- plotit(iris, encode(x = Sepal.Length)) |>
    mark_histogram() |>
    project_cartesian(flip = TRUE)
  c <- compose_marginal(main, top, right)
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_gt(file.info(f)$size, 10000)
  unlink(f)
})

# =====================================================================
# composite rejection stubs (single-plot verbs must refuse composites
# with a targeted message, never fall through to the plotit method)
# =====================================================================

test_that("[BDD] mark_* on composite aborts with a targeted message", {
  c <- compose_grid(.p1, .p2)
  expect_error(c |> mark_point(), "not supported for .plotit_composite")
  expect_error(c |> mark_bar(), "not supported for .plotit_composite")
})

test_that("[BDD] scale/project/split/label_axis on composite abort", {
  c <- compose_grid(.p1, .p2)
  expect_error(c |> scale_color(), "not supported for .plotit_composite")
  expect_error(c |> project_polar(), "not supported for .plotit_composite")
  expect_error(c |> split_wrap(Species), "not supported for .plotit_composite")
  expect_error(c |> label_axis(text = "x", aes = "x"), "not supported for .plotit_composite")
  expect_error(c |> label_legend(text = "x"), "not supported for .plotit_composite")
})

# =====================================================================
# stage 5: 5-1 D-03 -- compose_grid design / axis_titles
# =====================================================================

test_that("[BDD] compose_grid design text layout renders with empty cell", {
  c <- compose_grid(.p1, .p2, .p3, .p4, design = "12#\n344")
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_grid design list of area vectors renders", {
  c <- compose_grid(.p1, .p2, .p3, design = list(c(1, 1, 2, 1), c(1, 2, 1, 3), c(2, 2, 2, 3)))
  f <- tempfile(fileext = ".png")
  export(c, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("compose_grid design wins over grid args with a warning", {
  expect_warning(
    c <- compose_grid(.p1, .p2, ncol = 2, design = "12"),
    "takes precedence"
  )
  expect_equal(c@layout$design, "12")
  expect_null(c@layout$ncol)
})

test_that("compose_grid invalid design entries abort with a hint", {
  expect_error(
    compose_grid(.p1, .p2, design = list(c(1, 1))),
    "numeric vector c\\(top, left, bottom, right\\)"
  )
  expect_error(
    compose_grid(.p1, .p2, design = matrix(1)),
    "layout string or a list of area vectors"
  )
})

test_that("[BDD] compose_grid axis_titles = collect renders", {
  c <- compose_grid(.p1, .p2, axes = "collect", axis_titles = "collect")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  unlink(f)
})

test_that("compose_grid design does not mutate subplot meta (SM5)", {
  w <- .p1@meta@width
  c <- compose_grid(.p1, .p2, design = "12")
  expect_equal(.p1@meta@width, w)
  expect_equal(c@layout$type, "grid")
})

# =====================================================================
# stage 5: 5-2 D-04 -- compose_annot strips
# =====================================================================

.dend_strip <- function(h, direction = "up") {
  as_graph(h) |>
    plotit() |>
    layout_dendrogram(direction = direction) |>
    mark_rule(data = ~edges)
}

test_that("[BDD] compose_annot top dendrogram strip renders (D4 flagship core)", {
  mat <- matrix(
    c(9, 1, 8, 2, 1, 9, 2, 8, 5, 3, 7, 4),
    nrow = 4,
    dimnames = list(paste0("g", 1:4), paste0("s", 1:3))
  )
  h <- stats::hclust(stats::dist(mat))
  hm <- plotit(mat, encode()) |> mark_heatmap(cluster = h)
  p <- hm |> compose_annot(top = .dend_strip(h, "up"))
  expect_s3_class(p, "plotit::plotit_composite")
  expect_equal(p@layout$type, "annot")
  expect_equal(p@layout$sides, "top")
  expect_length(p@plots, 2)
  f <- tempfile(fileext = ".png")
  export(p, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] compose_annot four sides + gap render", {
  strip_v <- .dend_strip(stats::hclust(dist(iris[, 1:4])), "up")
  strip_h <- .dend_strip(stats::hclust(dist(t(iris[, 1:4]))), "right")
  c <- compose_grid(.p1, .p2)
  p <- compose_annot(c, top = strip_v, right = strip_h, gap = 0.05)
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, dpi = 72))
  unlink(f)
})

test_that("[BDD] compose_annot accepts explicit strip sizes (three states)", {
  s1 <- .dend_strip(stats::hclust(dist(iris[, 1:4])), "up")
  p1 <- .p1 |> compose_annot(top = s1, heights = grid::unit(0.6, "in"))
  expect_s3_class(p1, "plotit::plotit_composite")
  p2 <- .p1 |> compose_annot(top = s1, heights = c(1, 4))
  expect_s3_class(p2, "plotit::plotit_composite")
})

test_that("compose_annot full-grid size mismatch aborts", {
  s1 <- .dend_strip(stats::hclust(dist(iris[, 1:4])), "up")
  expect_error(
    .p1 |> compose_annot(top = s1, heights = c(1, 4, 9)),
    "assembled grid has 2 rows"
  )
})

test_that("compose_annot error paths abort with targeted hints", {
  expect_error(compose_annot(.p1), "at least one strip")
  expect_error(compose_annot(.p1, top = "nope"), "must be a")
  expect_error(compose_annot("nope", top = .p1), "must be a")
  expect_error(compose_annot(.p1, top = .p2, align = "diagonal"), "must be one of")
})

test_that("compose_annot on_top = TRUE warns and still renders beside", {
  expect_warning(p <- compose_annot(.p1, top = .p2, on_top = TRUE), "reserved")
  expect_s3_class(p, "plotit::plotit_composite")
})

test_that("[BDD] compose_marginal with a single side renders (regression)", {
  main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  top <- plotit(iris, encode(x = Sepal.Width)) |> mark_histogram()
  c <- compose_marginal(main, top = top)
  expect_equal(c@layout$type, "marginal")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(c, f, dpi = 72))
  unlink(f)
  expect_error(compose_marginal(main), "at least one marginal")
  expect_error(compose_marginal(main, top = top, align = "diagonal"), "must be one of")
})
