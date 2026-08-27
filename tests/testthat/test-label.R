# ============================================================
# label_* function family -- BDD tests via ggplot_build()
# Labels are stored lazily in meta@labels and synced to gg
# at print()/export() time via ._sync_labels().
# Tests verify the final rendered state, not internal meta.
# AGENTS.md SS4.8
# ============================================================
library(plotit)

# ---- helpers ----
# Sync lazy labels to gg then build for inspection
.build_synced <- function(p) {
  ggplot2::ggplot_build(plotit:::._sync_labels(p)@gg)
}

# ---- label_title ----
test_that("[BDD] label_title sets rendered title after sync", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("Custom Title")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$title, "Custom Title")
})

test_that("[BDD] label_title text=NULL preserves existing rendered title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(text = NULL)
  built <- .build_synced(p)
  expect_equal(built$plot$labels$title, "Old")
})

test_that("[BDD] label_title reset=TRUE clears rendered title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(reset = TRUE)
  built <- .build_synced(p)
  expect_null(built$plot$labels$title)
})

test_that("[BDD] label_title hide=TRUE produces element_blank in theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Visible") |>
    label_title(hide = TRUE)
  built <- .build_synced(p)
  expect_true(inherits(built$plot$theme$plot.title, "element_blank"))
})

test_that("[BDD] label_title text=\"\" renders empty title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title(text = "")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$title, "")
})

# ---- label_subtitle ----
test_that("[BDD] label_subtitle sets rendered subtitle after sync", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Sub")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$subtitle, "Sub")
})

test_that("[BDD] label_subtitle text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(text = NULL)
  built <- .build_synced(p)
  expect_equal(built$plot$labels$subtitle, "Old")
})

test_that("[BDD] label_subtitle reset=TRUE clears rendered subtitle", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(reset = TRUE)
  built <- .build_synced(p)
  expect_null(built$plot$labels$subtitle)
})

test_that("[BDD] label_subtitle hide=TRUE produces element_blank", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_subtitle(hide = TRUE)
  built <- .build_synced(p)
  expect_true(inherits(built$plot$theme$plot.subtitle, "element_blank"))
})

# ---- label_caption ----
test_that("[BDD] label_caption sets rendered caption after sync", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Cap")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$caption, "Cap")
})

test_that("[BDD] label_caption text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(text = NULL)
  built <- .build_synced(p)
  expect_equal(built$plot$labels$caption, "Old")
})

test_that("[BDD] label_caption reset=TRUE clears rendered caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(reset = TRUE)
  built <- .build_synced(p)
  expect_null(built$plot$labels$caption)
})

test_that("[BDD] label_caption hide=TRUE produces element_blank", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_caption(hide = TRUE)
  built <- .build_synced(p)
  expect_true(inherits(built$plot$theme$plot.caption, "element_blank"))
})

# ---- label_axis ----
test_that("[BDD] label_axis sets rendered x-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Axis", aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "X Axis")
})

test_that("[BDD] label_axis sets rendered y-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "Y Axis", aes = "y")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$y, "Y Axis")
})

test_that("[BDD] label_axis partial update does not affect other axis", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Only", aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "X Only")
  # y retains the default variable name
  expect_equal(built$plot$labels$y, "Sepal.Length")
})

test_that("label_axis missing aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_axis invalid aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

test_that("[BDD] label_axis hide=TRUE produces element_blank in theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x")
  built <- .build_synced(p)
  expect_true(inherits(built$plot$theme$axis.title.x, "element_blank"))
})

test_that("[BDD] label_axis text=NULL preserves current rendered label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(text = NULL, aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "Custom")
})

test_that("[BDD] label_axis reset=TRUE restores default variable name", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "Sepal.Width")
})

test_that("[BDD] label_axis reset overrides previous custom", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "Sepal.Width")
})

# ---- label_legend ----
test_that("[BDD] label_legend sets rendered legend title by aesthetic", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "Species", aes = "colour")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "Species")
})

test_that("[BDD] label_legend without aes sets default legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "All")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "All")
})

test_that("[BDD] label_legend global mode on layer-only aesthetic", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species)) |>
    label_legend(text = "Species")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "Species")
})

test_that("label_legend no warning when aesthetic exists in layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("[BDD] label_legend hide=TRUE suppresses legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(hide = TRUE, aes = "colour")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "Species")
})

test_that("[BDD] label_legend reset=TRUE clears custom legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(reset = TRUE, aes = "colour")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "Species")
})

test_that("label_legend warns on non-existent aes", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("[BDD] label_legend works for fill", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point() |>
    label_legend(text = "Fill", aes = "fill")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$fill, "Fill")
})

test_that("[BDD] label_legend works for shape", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    label_legend(text = "Shape", aes = "shape")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$shape, "Shape")
})

# ---- pipeline label composition ----
test_that("[BDD] pipeline with multiple labels renders all in sync", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Main") |>
    label_subtitle("Sub") |>
    label_caption("Cap") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$title, "Main")
  expect_equal(built$plot$labels$subtitle, "Sub")
  expect_equal(built$plot$labels$caption, "Cap")
  expect_equal(built$plot$labels$x, "X")
  expect_equal(built$plot$labels$y, "Y")
})

# ---- hide + reset combo ----
test_that("[BDD] label_axis hide then reset restores default variable name", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  built <- .build_synced(p)
  expect_equal(built$plot$labels$x, "Sepal.Width")
})

# ---- text/reset mutual exclusion ----
test_that("label_axis text+reset mutual exclusion errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_axis(p, text = "X", reset = TRUE, aes = "x"),
    "mutually exclusive"
  )
})

test_that("label_title text+reset mutual exclusion errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(
    label_title(p, text = "T", reset = TRUE),
    "mutually exclusive"
  )
})

test_that("[BDD] label_legend global reset restores default legend titles", {
  p <- plotit(iris, encode(
    x = Sepal.Width, y = Sepal.Length,
    colour = Species, fill = Species
  )) |>
    mark_point() |>
    scale_color() |>
    scale_fill() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(text = "Custom", aes = "fill") |>
    label_legend(reset = TRUE)
  built <- .build_synced(p)
  expect_equal(built$plot$labels$colour, "Species")
  expect_equal(built$plot$labels$fill, "Species")
})

# ---- regression: label sync must not wipe theme typography ----
# `theme(el = NULL)` deletes the element key entirely (modifyList
# semantics); setting a text label must only neutralize a previous
# element_blank, preserving the shared theme's alignment/size hierarchy.
test_that("[BDD] label_title keeps the default title typography", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("Styled Title")
  p <- plotit:::._sync_labels(p)
  el <- p@gg$theme$plot.title
  expect_false(inherits(el, "element_blank"))
  expect_false(is.null(el$hjust))
  expect_equal(el$hjust, 0) # shared token: left-aligned title
})

test_that("[BDD] hide then set restores typography (no residual blank)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("First") |>
    label_title(hide = TRUE) |>
    label_title("Second")
  p <- plotit:::._sync_labels(p)
  expect_false(inherits(p@gg$theme$plot.title, "element_blank"))
  expect_equal(p@gg$labels$title, "Second")
})

# ---- review regressions: legend reset after sync & priority protocol ----
test_that("label_legend reset after a synced custom title restores the default", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    label_legend(text = "Custom", aes = "colour")
  s1 <- plotit:::._sync_labels(p)
  expect_equal(s1@gg$labels$colour, "Custom")
  s2 <- plotit:::._sync_labels(label_legend(s1, reset = TRUE, aes = "colour"))
  expect_null(s2@gg$labels$colour)
})

test_that("label_legend global reset clears all synced legend titles", {
  p <- plotit(
    iris,
    encode(x = Sepal.Width, y = Sepal.Length, colour = Species, size = Petal.Width)
  ) |>
    mark_point() |>
    label_legend(text = "Everything")
  s1 <- plotit:::._sync_labels(p)
  expect_equal(s1@gg$labels$colour, "Everything")
  expect_equal(s1@gg$labels$size, "Everything")
  s2 <- plotit:::._sync_labels(label_legend(s1, reset = TRUE))
  expect_null(s2@gg$labels$colour)
  expect_null(s2@gg$labels$size)
})

test_that("reset outranks hide in the three-parameter protocol (axis)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Width", aes = "x")
  s1 <- plotit:::._sync_labels(p)
  r <- label_axis(s1, aes = "x", reset = TRUE, hide = TRUE)
  s2 <- plotit:::._sync_labels(r)
  # reset wins: element is NOT blanked, custom text removed
  expect_false(inherits(s2@gg$theme$axis.title.x, "element_blank"))
  expect_null(s2@gg$labels$x)
})

test_that("reset outranks hide in the three-parameter protocol (legend)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    label_legend(text = "Custom", aes = "colour")
  s1 <- plotit:::._sync_labels(p)
  s2 <- plotit:::._sync_labels(label_legend(s1, aes = "colour", reset = TRUE, hide = TRUE))
  expect_null(s2@gg$labels$colour)
})
