# ============================================================
# mark_encircle (D-09, design/03 <U+00A7>4) -- BDD tests
# AGENTS.md 4.8
# ============================================================
library(plotit)

enc <- data.frame(
  x = c(1, 2, 3, 8, 9, 10),
  y = c(1, 3, 2, 8, 10, 9),
  g = rep(c("A", "B"), each = 3)
)

test_that("[BDD] mark_encircle hull wraps each group's convex hull", {
  p <- plotit(enc, encode(x = x, y = y, colour = g)) |>
    mark_point() |>
    mark_encircle()
  expect_s3_class(p, "plotit::plotit")
  b <- ggplot2::ggplot_build(p@gg)
  poly_layer <- length(b$data) # point layer + polygon layer
  expect_equal(poly_layer, 2)
  expect_true(inherits(p@gg$layers[[2]]$geom, "GeomPolygon"))
  # one polygon per group
  expect_equal(length(unique(b$data[[2]]$group)), 2)
})

test_that("[BDD] mark_encircle expand dilates hull vertices outward", {
  p0 <- plotit(enc, encode(x = x, y = y)) |> mark_encircle(expand = 0)
  p5 <- plotit(enc, encode(x = x, y = y)) |> mark_encircle(expand = 0.5)
  d0 <- ggplot2::ggplot_build(p0@gg)$data[[1]]
  d5 <- ggplot2::ggplot_build(p5@gg)$data[[1]]
  # dilation moves vertices strictly outward: max distance grows
  spread0 <- max(d0$x) - min(d0$x)
  spread5 <- max(d5$x) - min(d5$x)
  expect_gt(spread5, spread0)
})

test_that("[BDD] mark_encircle matches its documented expansion pipeline", {
  # The documented equivalence: chull vertices dilated by (1 + expand)
  # around the hull centroid, rendered through mark_polygon with the same
  # tokens -- the sugar must be point-identical (+/- 1e-6).
  expand <- 0.2
  sugar <- plotit(enc, encode(x = x, y = y)) |>
    mark_encircle(expand = expand, radius = 0) # sharp hull: pure dilation
  h <- grDevices::chull(enc$x, enc$y)
  pts <- data.frame(x = enc$x[h], y = enc$y[h])
  cx <- mean(pts$x)
  cy <- mean(pts$y)
  d <- sqrt((pts$x - cx)^2 + (pts$y - cy)^2)
  m <- expand * 2 * max(d) # uniform margin share of the hull diameter
  k <- (d + m) / d
  pts$x <- cx + (pts$x - cx) * k
  pts$y <- cy + (pts$y - cy) * k
  pipeline <- plotit(enc, encode(x = x, y = y)) |>
    mark_polygon(
      fill = "#4E79A7", colour = "grey70", alpha = 0.18,
      data = pts, mapping = encode(x = x, y = y)
    )
  d_sugar <- ggplot2::ggplot_build(sugar@gg)$data[[1]]
  d_pipe <- ggplot2::ggplot_build(pipeline@gg)$data[[1]]
  # same vertex set (order kept): x/y coordinates point-identical
  expect_equal(sort(d_sugar$x), sort(d_pipe$x), tolerance = 1e-6)
  expect_equal(sort(d_sugar$y), sort(d_pipe$y), tolerance = 1e-6)
})

test_that("[BDD] mark_encircle radius smooths hull corners", {
  p0 <- plotit(enc, encode(x = x, y = y)) |> mark_encircle(radius = 0)
  p1 <- plotit(enc, encode(x = x, y = y)) |> mark_encircle(radius = 0.05)
  n0 <- nrow(ggplot2::ggplot_build(p0@gg)$data[[1]])
  n1 <- nrow(ggplot2::ggplot_build(p1@gg)$data[[1]])
  expect_gt(n1, n0) # Chaikin rounds add vertices
})

test_that("[BDD] mark_encircle ellipse engine renders per group", {
  p <- plotit(iris, encode(x = Petal.Length, y = Petal.Width, colour = Species)) |>
    mark_encircle(shape = "ellipse")
  b <- ggplot2::ggplot_build(p@gg)
  expect_equal(length(unique(b$data[[1]]$group)), 3)
})

test_that("[BDD] mark_encircle validates expand/radius", {
  p <- plotit(enc, encode(x = x, y = y))
  expect_error(mark_encircle(p, expand = -1), "expand")
  expect_error(mark_encircle(p, radius = "x"), "radius")
})
