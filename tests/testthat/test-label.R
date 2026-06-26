# ============================================================
# label_* function family <U+2014> tests for lazy label storage
# Since labels are now stored in meta@labels and synced lazily
# (Problem 3), assertions check the intent in meta rather than
# the immediate gg state.
# AGENTS.md <U+00A7>4.8
# ============================================================
library(plotit)

# ---- helpers ----
.meta <- function(p) p@meta@labels

# ---- label_title ----
test_that("label_title sets title in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_title("Custom Title")
  expect_equal(.meta(p)@title, "Custom Title")
  expect_true("title" %in% names(.meta(p)@dirty))
})

test_that("label_title text=NULL preserves existing title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(text = NULL)
  expect_equal(.meta(p)@title, "Old")
  expect_true("title" %in% names(.meta(p)@dirty))
})

test_that("label_title reset=TRUE clears title in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(reset = TRUE)
  expect_null(.meta(p)@title)
  expect_true("title" %in% names(.meta(p)@dirty))
})

test_that("label_title hide=TRUE stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Visible") |>
    label_title(hide = TRUE)
  expect_identical(.meta(p)@title, FALSE)
  expect_true("title" %in% names(.meta(p)@dirty))
})

test_that("label_title text=\"\" sets empty string in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title(text = "")
  expect_equal(.meta(p)@title, "")
  expect_true("title" %in% names(.meta(p)@dirty))
})

# ---- label_subtitle ----
test_that("label_subtitle sets subtitle in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Sub")
  expect_equal(.meta(p)@subtitle, "Sub")
  expect_true("subtitle" %in% names(.meta(p)@dirty))
})

test_that("label_subtitle text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(text = NULL)
  expect_equal(.meta(p)@subtitle, "Old")
  expect_true("subtitle" %in% names(.meta(p)@dirty))
})

test_that("label_subtitle reset=TRUE clears subtitle in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(reset = TRUE)
  expect_null(.meta(p)@subtitle)
  expect_true("subtitle" %in% names(.meta(p)@dirty))
})

test_that("label_subtitle hide=TRUE stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_subtitle(hide = TRUE)
  expect_identical(.meta(p)@subtitle, FALSE)
  expect_true("subtitle" %in% names(.meta(p)@dirty))
})

# ---- label_caption ----
test_that("label_caption sets caption in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Cap")
  expect_equal(.meta(p)@caption, "Cap")
  expect_true("caption" %in% names(.meta(p)@dirty))
})

test_that("label_caption text=NULL preserves existing", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(text = NULL)
  expect_equal(.meta(p)@caption, "Old")
  expect_true("caption" %in% names(.meta(p)@dirty))
})

test_that("label_caption reset=TRUE clears caption in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(reset = TRUE)
  expect_null(.meta(p)@caption)
  expect_true("caption" %in% names(.meta(p)@dirty))
})

test_that("label_caption hide=TRUE stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_caption(hide = TRUE)
  expect_identical(.meta(p)@caption, FALSE)
  expect_true("caption" %in% names(.meta(p)@dirty))
})

# ---- label_axis ----
test_that("label_axis sets x-axis label in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Axis", aes = "x")
  expect_equal(.meta(p)@x, "X Axis")
  expect_true("x" %in% names(.meta(p)@dirty))
})

test_that("label_axis sets y-axis label in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "Y Axis", aes = "y")
  expect_equal(.meta(p)@y, "Y Axis")
  expect_true("y" %in% names(.meta(p)@dirty))
})

test_that("label_axis partial update does not affect other axis", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_axis(text = "X Only", aes = "x")
  expect_equal(.meta(p)@x, "X Only")
  expect_null(.meta(p)@y) # y not modified
  expect_true("x" %in% names(.meta(p)@dirty))
  expect_false("y" %in% names(.meta(p)@dirty))
})

test_that("label_axis missing aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_axis invalid aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

test_that("label_axis hide=TRUE stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x")
  expect_identical(.meta(p)@x, FALSE)
  expect_true("x" %in% names(.meta(p)@dirty))
})

test_that("label_axis text=NULL preserves current label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(text = NULL, aes = "x")
  expect_equal(.meta(p)@x, "Custom")
  expect_true("x" %in% names(.meta(p)@dirty))
})

test_that("label_axis reset=TRUE clears axis label in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Custom", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_null(.meta(p)@x)
  expect_true("x" %in% names(.meta(p)@dirty))
})

test_that("label_axis reset overrides previous custom", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_null(.meta(p)@x)
  expect_true("x" %in% names(.meta(p)@dirty))
})

# ---- label_legend ----
test_that("label_legend sets legend title by aesthetic in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "Species", aes = "colour")
  expect_equal(.meta(p)@legend[["colour"]], "Species")
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend without aes stores default entry in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    label_legend(text = "All")
  expect_equal(.meta(p)@legend[["default"]], "All")
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend global mode stores default in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species)) |>
    label_legend(text = "Species")
  expect_equal(.meta(p)@legend[["default"]], "Species")
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend no warning when aesthetic exists in layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend hide=TRUE stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(hide = TRUE, aes = "colour")
  expect_identical(.meta(p)@legend[["colour"]], FALSE)
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend reset=TRUE clears legend entry in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(reset = TRUE, aes = "colour")
  expect_null(.meta(p)@legend[["colour"]])
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend warns on non-existent aes", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend works for fill", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point() |>
    label_legend(text = "Fill", aes = "fill")
  expect_equal(.meta(p)@legend[["fill"]], "Fill")
  expect_true("legend" %in% names(.meta(p)@dirty))
})

test_that("label_legend works for shape", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point() |>
    label_legend(text = "Shape", aes = "shape")
  expect_equal(.meta(p)@legend[["shape"]], "Shape")
  expect_true("legend" %in% names(.meta(p)@dirty))
})

# ---- pipeline label composition ----
test_that("pipeline with multiple labels stores all in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Main") |>
    label_subtitle("Sub") |>
    label_caption("Cap") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  m <- .meta(p)
  expect_equal(m@title, "Main")
  expect_equal(m@subtitle, "Sub")
  expect_equal(m@caption, "Cap")
  expect_equal(m@x, "X")
  expect_equal(m@y, "Y")
  for (.slot in c("title", "subtitle", "caption", "x", "y")) {
    expect_true(.slot %in% names(m@dirty))
  }
})

# ---- hide + reset combo ----
test_that("label_axis hide=TRUE then reset=TRUE clears meta and restores null", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_null(.meta(p)@x)
  expect_true("x" %in% names(.meta(p)@dirty))
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

test_that("label_legend reset=TRUE for all aesthetics clears all legend entries", {
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
  # After global reset, default entry is cleared
  expect_null(.meta(p)@legend[["default"]])
  expect_true("legend" %in% names(.meta(p)@dirty))
})
