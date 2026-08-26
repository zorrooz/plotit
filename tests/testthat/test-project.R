# ============================================================
# project_* function family -- coordinate transforms
# ============================================================
library(plotit)

# ---- project_polar ----
test_that("project_polar basic (no radial mode)", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar()
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_polar theta=\"y\"", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(theta = "y")
  expect_s3_class(p, "plotit::plotit")
})


# ---- project_cartesian ----
test_that("project_cartesian basic no crash", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian()
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian xlim + ylim", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(xlim = c(0, 6), ylim = c(5, 40))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian expand=FALSE", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(expand = FALSE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian clip=\"off\"", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(clip = "off")
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_cartesian extended ----
test_that("project_cartesian flip=TRUE swaps axes", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |>
    mark_boxplot() |>
    project_cartesian(flip = TRUE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian fixed=1 locks aspect ratio", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(fixed = 1)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian coord_trans applies coordinate transform", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(coord_trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})


# ---- project_parallel ----
test_that("project_parallel basic parallel coordinates", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c(
      "Sepal.Width", "Sepal.Length",
      "Petal.Width", "Petal.Length"
    ))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel with group coloring", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      group = "Species"
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel scale=\"global\"", {
  p <- plotit(mtcars, encode()) |>
    project_parallel(columns = c("wt", "qsec"), scale = "global")
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel errors on missing column", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p, columns = c("not_a_column")),
    "not found"
  )
})

# ---- project_map ----
test_that("project_map default coord_sf works", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- plotit(nc, encode(fill = AREA)) |>
    mark_point() |>
    project_map()
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_polar radial mode ----
test_that("project_polar basic (non-radial test in radial section)", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar()
  expect_s3_class(p, "plotit::plotit")
})


test_that("project_polar inner_radius > 0 switches to radial", {
  skip_if(utils::packageVersion("ggplot2") < "3.5.0")
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(inner_radius = 0.3)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_polar r_axis_inside + inner_radius", {
  skip_if(utils::packageVersion("ggplot2") < "3.5.0")
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(r_axis_inside = TRUE, inner_radius = 0.3)
  expect_s3_class(p, "plotit::plotit")
})

# ---- edge cases & warnings ----
test_that("project_cartesian warns on multiple modes (flip + fixed)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    project_cartesian(p, flip = TRUE, fixed = 1),
    "Multiple coordinate modes"
  )
})

test_that("project_cartesian warns on multiple modes (flip + coord_trans)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    project_cartesian(p, flip = TRUE, coord_trans = "log10"),
    "Multiple coordinate modes"
  )
})

test_that("project_parallel scale=\"none\" skips normalisation", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      scale = "none"
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel handles NA values without crash", {
  df <- iris
  df$Sepal.Width[1] <- NA
  p <- plotit(df, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel errors on reserved column names", {
  df <- iris
  df$.plotit_id <- seq_len(nrow(df))
  p <- plotit(df, encode())
  expect_error(
    project_parallel(p, columns = c("Sepal.Width")),
    "reserved column"
  )
})

test_that("project_parallel errors on empty data", {
  p <- plotit(iris[0, ], encode())
  expect_error(
    project_parallel(p, columns = c("Sepal.Width")),
    "No data found"
  )
})

test_that("[BDD] project_parallel shared-scale mode has 2 data layers", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"))
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(length(built$data), 2) # geom_line + geom_point only
})

test_that("[BDD] project_parallel none mode adds per-column axis layers", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      scale = "none"
    )
  built <- ggplot2::ggplot_build(p@gg)
  expect_gt(length(built$data), 2) # line + point + axis layers
})

test_that("project_polar clip=\"off\" works", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(clip = "off")
  expect_s3_class(p, "plotit::plotit")
})

test_that("[BDD] project_parallel clears default_color when group provides colour", {
  # project_parallel adds its own layers; no need for mark_point()
  p <- plotit(iris, encode(), default_color = "black") |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      group = "Species"
    )
  # Group introduces colour mapping -> default_color cleared -> scale exists
  built <- ggplot2::ggplot_build(p@gg)
  colour_scale <- built$plot$scales$get_scales("colour")
  expect_false(is.null(colour_scale))
})

test_that("project_parallel errors on non-existent group column", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p, columns = c("Sepal.Width"), group = "not_a_column"),
    "not found"
  )
})

test_that("project_parallel errors when group is also a parallel column", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p,
      columns = c("Sepal.Width", "Sepal.Length"),
      group = "Sepal.Width"
    ),
    "also in"
  )
})

test_that("project_parallel errors on empty columns vector", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p, columns = character(0)),
    "at least one column"
  )
})

test_that("project_cartesian multi-mode warning names correct active mode", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_warning(
    project_cartesian(p, fixed = 1, coord_trans = "log10"),
    "Only .*fixed.* will be used"
  )
  # flip wins when set
  expect_warning(
    project_cartesian(p, flip = TRUE, fixed = 1),
    "Only .*flip.* will be used"
  )
})

# ---- BDD: project_parallel scale="none" axis rendering ----
test_that("[BDD] scale='none' draws per-column axis lines", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"), scale = "none")
  built <- ggplot2::ggplot_build(p@gg)
  # Should have data layers (line + point) plus axis segments
  expect_gt(length(built$data), 2) # line + point + axis layers
})

test_that("[BDD] scale='none' suppresses native y-axis", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"), scale = "none")
  built <- ggplot2::ggplot_build(p@gg)
  # Native y-axis line should be blank
  expect_true(inherits(built$plot$theme$axis.line.y, "element_blank"))
})

test_that("[BDD] scale='std' uses shared y-axis (no manual axes)", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"), scale = "std")
  built <- ggplot2::ggplot_build(p@gg)
  expect_length(built$data, 2) # only line + point, no axis segments
})

# ---- [BDD] project_cartesian deep rendering tests ----

test_that("[BDD] project_cartesian xlim sets coordinate limits", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(xlim = c(2, 4))
  built <- ggplot2::ggplot_build(p@gg)
  pp <- built$layout$panel_params[[1]]
  expect_true(pp$x.range[1] <= 2 && pp$x.range[2] >= 4)
})

test_that("[BDD] project_cartesian flip=TRUE swaps axes", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |>
    mark_boxplot() |>
    project_cartesian(flip = TRUE)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$coordinates, "CoordFlip"))
})

test_that("[BDD] project_cartesian fixed=1 locks aspect ratio", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(fixed = 1)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$coordinates, "CoordCartesian"))
  expect_equal(built$plot$coordinates$ratio, 1)
})

# ---- [BDD] project_polar deep rendering tests ----

test_that("[BDD] project_polar renders polar coordinates", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar()
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$coordinates, "CoordPolar"))
})

test_that("[BDD] project_polar with inner_radius activates radial coord", {
  skip_if(utils::packageVersion("ggplot2") < "3.5.0")
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(inner_radius = 0.3)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$coordinates, "CoordRadial"))
})

# ---- [BDD] project_map deep rendering tests ----

test_that("[BDD] project_map produces CoordSf coordinate system", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- plotit(nc, encode(fill = AREA)) |>
    project_map()
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$coordinates, "CoordSf"))
})

# ---- regression: project_parallel routes the group channel through the
# shared palette decision point (friendly/viridis), not ggplot2 hue ----
test_that("[BDD] parallel coordinates group colours use the token palette", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      group = "Species"
    )
  cols <- unique(ggplot2::ggplot_build(p@gg)$data[[1]]$colour)
  expect_true("#0072B2" %in% cols) # friendly anchor
  expect_false(setequal(cols, c("#F8766D", "#00BA38", "#619CFF"))) # not raw hue
})
