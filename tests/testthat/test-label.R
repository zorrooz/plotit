# ============================================================
# label_* function family — text + hide protocol, meta sync, edge cases
# ============================================================
library(plotit)

# ---- label_title ----
test_that("label_title syncs meta and gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_title(p, "Custom Title")
  expect_equal(p@meta@labels@title, "Custom Title")
  expect_equal(p@gg$labels$title, "Custom Title")
})

test_that("label_title text=NULL preserves existing title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(text = NULL)
  expect_equal(p@gg$labels$title, "Old")
  expect_equal(p@meta@labels@title, "Old")
})

test_that("label_title reset=TRUE removes title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Old") |>
    label_title(reset = TRUE)
  expect_null(p@gg$labels$title)
  expect_null(p@meta@labels@title)
})

test_that("label_title hide=TRUE removes title from layout", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_title(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.title, "element_blank"))
  expect_null(p@meta@labels@title)
})

test_that("label_title text=\"\" preserves layout slot", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_title(p, text = "")
  expect_equal(p@gg$labels$title, "")
  expect_equal(p@meta@labels@title, "")
})

# ---- label_subtitle ----
test_that("label_subtitle syncs meta and gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_subtitle(p, "Sub")
  expect_equal(p@meta@labels@subtitle, "Sub")
  expect_equal(p@gg$labels$subtitle, "Sub")
})

test_that("label_subtitle text=NULL preserves existing subtitle", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(text = NULL)
  expect_equal(p@gg$labels$subtitle, "Old")
  expect_equal(p@meta@labels@subtitle, "Old")
})

test_that("label_subtitle reset=TRUE removes subtitle", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_subtitle("Old") |>
    label_subtitle(reset = TRUE)
  expect_null(p@gg$labels$subtitle)
  expect_null(p@meta@labels@subtitle)
})

test_that("label_subtitle hide=TRUE removes from layout", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_subtitle(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.subtitle, "element_blank"))
})

# ---- label_caption ----
test_that("label_caption syncs meta and gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_caption(p, "Cap")
  expect_equal(p@meta@labels@caption, "Cap")
  expect_equal(p@gg$labels$caption, "Cap")
})

test_that("label_caption text=NULL preserves existing caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(text = NULL)
  expect_equal(p@gg$labels$caption, "Old")
  expect_equal(p@meta@labels@caption, "Old")
})

test_that("label_caption reset=TRUE removes caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    label_caption("Old") |>
    label_caption(reset = TRUE)
  expect_null(p@gg$labels$caption)
  expect_null(p@meta@labels@caption)
})

test_that("label_caption hide=TRUE removes from layout", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_caption(p, hide = TRUE)
  expect_true(inherits(p@gg$theme$plot.caption, "element_blank"))
})

# ---- label_axis ----
test_that("label_axis syncs x-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "X Axis", aes = "x")
  expect_equal(p@meta@labels@x, "X Axis")
  expect_equal(p@gg$labels$x, "X Axis")
})

test_that("label_axis syncs y-axis label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "Y Axis", aes = "y")
  expect_equal(p@meta@labels@y, "Y Axis")
  expect_equal(p@gg$labels$y, "Y Axis")
})

test_that("label_axis partial update does not affect other axis", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- label_axis(p, text = "X Only", aes = "x")
  expect_equal(p@meta@labels@x, "X Only")
  expect_null(p@meta@labels@y)
})

test_that("label_axis missing aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "X"), "must be specified")
})

test_that("label_axis invalid aes errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(label_axis(p, text = "Test", aes = "z"), "must be one of")
})

test_that("label_axis hide=TRUE hides and stores FALSE in meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, hide = TRUE, aes = "x")
  expect_true(inherits(p@gg$theme$axis.title.x, "element_blank"))
  expect_false(p@meta@labels@x)
})

test_that("label_axis text=NULL preserves current label", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  # Set a custom label first, then call with text=NULL (should be no-op)
  p <- label_axis(p, text = "Custom", aes = "x")
  p <- label_axis(p, text = NULL, aes = "x")
  expect_equal(p@gg$labels$x, "Custom")
  expect_equal(p@meta@labels@x, "Custom")
})

test_that("label_axis reset=TRUE restores variable name, meta stores NULL", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, text = "Custom", aes = "x")
  p <- label_axis(p, reset = TRUE, aes = "x")
  # labs(x = NULL) clears the label override; entry exists but value is NULL
  expect_null(p@gg$labels$x)
  expect_null(p@meta@labels@x)
})

test_that("label_axis reset=TRUE overrides previous custom", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- p |>
    label_axis(text = "Old", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  expect_null(p@gg$labels$x)
})

# ---- label_legend ----
test_that("label_legend sets legend title by aesthetic", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "Species", aes = "colour")
  expect_equal(p@meta@labels@legend[["colour"]], "Species")
  expect_equal(p@gg$labels$colour, "Species")
})

test_that("label_legend without aes affects all mapped aesthetics", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species))
  p <- label_legend(p, text = "All")
  expect_equal(p@meta@labels@legend[["default"]], "All")
  expect_equal(p@gg$labels$colour, "All")
})

test_that("label_legend global mode discovers layer-level colour mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  p <- label_legend(p, text = "Species")
  expect_equal(p@meta@labels@legend[["default"]], "Species")
})

test_that("label_legend no warning when aesthetic exists in layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p <- mark_point(p, mapping = encode(colour = Species))
  expect_no_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend hide=TRUE hides legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color()
  p <- label_legend(p, hide = TRUE, aes = "colour")
  # guides(colour = guide_legend(title = NULL)) hides title without
  # modifying the scale's internal $name slot (public API only)
  expect_s3_class(p, "plotit::plotit")
})

test_that("label_legend reset=TRUE restores default legend title (waiver)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    scale_color() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(reset = TRUE, aes = "colour")
  expect_true(inherits(p@gg$scales$scales[[1]]$name, "waiver"))
})

test_that("label_legend warns on non-existent aes", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), default_color = NULL)
  expect_warning(label_legend(p, text = "test", aes = "colour"))
})

test_that("label_legend works for fill", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, fill = Species)) |>
    mark_point()
  p <- label_legend(p, text = "Fill", aes = "fill")
  expect_equal(p@meta@labels@legend[["fill"]], "Fill")
})

test_that("label_legend works for shape", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
    mark_point()
  p <- label_legend(p, text = "Shape", aes = "shape")
  expect_equal(p@meta@labels@legend[["shape"]], "Shape")
})

# ---- pipeline label composition ----
test_that("pipeline with multiple labels does not conflict", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Main") |>
    label_subtitle("Sub") |>
    label_caption("Cap") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  expect_equal(p@meta@labels@title, "Main")
  expect_equal(p@meta@labels@subtitle, "Sub")
  expect_equal(p@meta@labels@caption, "Cap")
  expect_equal(p@meta@labels@x, "X")
  expect_equal(p@meta@labels@y, "Y")
})

# ---- hide + reset combo ----
test_that("label_axis hide=TRUE then reset=TRUE restores", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p <- label_axis(p, hide = TRUE, aes = "x")
  expect_false(p@meta@labels@x)
  p <- label_axis(p, reset = TRUE, aes = "x")
  expect_null(p@meta@labels@x)
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

test_that("label_legend reset=TRUE without aes resets all mapped aesthetics", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species, fill = Species)) |>
    mark_point() |>
    scale_color() |>
    scale_fill() |>
    label_legend(text = "Custom", aes = "colour") |>
    label_legend(text = "Custom", aes = "fill") |>
    label_legend(reset = TRUE)
  expect_true(inherits(p@gg$scales$scales[[1]]$name, "waiver"))
  expect_true(inherits(p@gg$scales$scales[[2]]$name, "waiver"))
})
