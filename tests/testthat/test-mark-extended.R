# Tests for the extended mark catalog (2025-12 mark-coverage round):
# mark_step / mark_rug / mark_spoke / mark_curve / mark_count / mark_bin2d /
# mark_contour / mark_qq / mark_qq_line / mark_ecdf / mark_label /
# mark_forest, plus the mark_area band dispatch and the mark_errorbar
# caps/orientation modernization.  Style: assert behavior via
# ggplot_build(), never internal slots (AGENTS.md 4.8).

.built <- function(p) ggplot2::ggplot_build(p@gg)

# ---- mark_step ----
test_that("[BDD] mark_step adds a stair-step line", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |> mark_step()
  b <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomStep"))
  expect_gt(nrow(b$data[[1]]), 0)
})

test_that("mark_step direction is routed to the geom", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_step(direction = "hv")
  expect_true(nrow(.built(p)$data[[1]]) > 0)
  expect_error(
    plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
      mark_step(direction = "sideways"),
    "'arg' should be one of"
  )
})

# ---- mark_rug ----
test_that("[BDD] mark_rug adds marginal ticks with configurable sides", {
  p <- plotit(faithful, encode(x = eruptions)) |>
    mark_histogram(bins = 15) |>
    mark_rug(sides = "t")
  b <- .built(p)
  expect_length(p@gg$layers, 2)
  expect_equal(p@gg$layers[[2]]$geom_params$sides, "t")
  expect_true(nrow(b$data[[2]]) > 0)
})

test_that("mark_rug never auto-dodges", {
  df <- data.frame(g = rep(c("A", "B"), each = 20), v = rnorm(40))
  p <- plotit(df, encode(x = g, y = v)) |> mark_rug()
  pos <- p@gg$layers[[1]]$position
  expect_false(inherits(pos, "PositionDodge"))
})

# ---- mark_spoke ----
test_that("[BDD] mark_spoke draws radial segments from angle/radius", {
  df <- data.frame(x = 0, y = 0, angle = c(0, pi / 2, pi), radius = c(1, 1, 1))
  p <- plotit(df, encode(x = x, y = y, angle = angle, radius = radius)) |>
    mark_spoke()
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomSpoke"))
  expect_equal(nrow(b$data[[1]]), 3)
})

# ---- mark_curve ----
test_that("[BDD] mark_curve draws curved links between endpoints", {
  df <- data.frame(x = c(0, 1), y = c(0, 0), xend = c(1, 2), yend = c(1, 1))
  p <- plotit(df, encode(x = x, y = y, xend = xend, yend = yend)) |>
    mark_curve(curvature = 0.3)
  b <- .built(p)
  lay <- p@gg$layers[[1]]
  expect_true(inherits(lay$geom, "GeomCurve"))
  curvature <- lay$geom_params$curvature %||% lay$stat_params$curvature
  expect_equal(curvature, 0.3)
  expect_gt(nrow(b$data[[1]]), 0)
})

test_that("mark_curve passes arrow through to the geom", {
  df <- data.frame(x = 0, y = 0, xend = 1, yend = 1)
  p <- plotit(df, encode(x = x, y = y, xend = xend, yend = yend)) |>
    mark_curve(arrow = grid::arrow(length = grid::unit(0.1, "cm")))
  expect_true(!is.null(.built(p)))
})

test_that("mark_curve binds graph edge geometry from ~edges", {
  e <- data.frame(source = c("a", "b"), target = c("b", "c"))
  p <- as_graph(e) |>
    plotit() |>
    layout_circle() |>
    mark_curve(data = ~edges)
  b <- .built(p)
  # Endpoint columns auto-bound from the layout table.
  expect_true(all(c("x", "y", "xend", "yend") %in% names(b$data[[1]])))
})

# ---- mark_count ----
test_that("[BDD] mark_count sizes points by overlap counts", {
  df <- data.frame(x = rep(1:3, each = 4), y = rep(1:2, 6))
  p <- plotit(df, encode(x = x, y = y)) |> mark_count()
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$stat, "StatSum"))
  expect_true(any(b$data[[1]]$n > 1))
})

# ---- mark_bin2d ----
test_that("[BDD] mark_bin2d bins the plane and defaults to viridis", {
  set.seed(1)
  df <- data.frame(x = rnorm(200), y = rnorm(200))
  p <- plotit(df, encode(x = x, y = y)) |> mark_bin2d(bins = 8)
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomRect"))
  expect_true(nrow(b$data[[1]]) > 1)
  # Derived count channel owns a managed continuous fill scale.
  expect_true(inherits(p@gg$scales$get_scales("fill"), "ScaleContinuous"))
})

test_that("mark_bin2d lets a later scale_fill win over the derived default", {
  set.seed(3)
  df <- data.frame(x = rnorm(100), y = rnorm(100))
  # The count channel is stat-computed, so a replacement scale declares its
  # trans explicitly (continuous identity), same contract as mark_corr.
  p <- plotit(df, encode(x = x, y = y)) |>
    mark_bin2d(bins = 6) |>
    suppressMessages(scale_fill(trans = "identity", range = "brewer"))
  expect_s3_class(p@gg$scales$get_scales("fill"), "ScaleContinuous")
  expect_true(!is.null(.built(p)))
})

test_that("mark_bin2d accepts binwidth", {
  set.seed(2)
  df <- data.frame(x = rnorm(100), y = rnorm(100))
  p <- plotit(df, encode(x = x, y = y)) |> mark_bin2d(binwidth = c(0.5, 0.5))
  expect_true(nrow(.built(p)$data[[1]]) > 1)
})

# ---- mark_contour ----
contour_df <- function() {
  df <- expand.grid(x = seq(0, 10, length.out = 25), y = seq(0, 10, length.out = 25))
  df$z <- sin(df$x / 2) * cos(df$y / 2)
  df
}

test_that("[BDD] mark_contour draws lines for a z field", {
  p <- plotit(contour_df(), encode(x = x, y = y, z = z)) |>
    mark_contour(breaks = seq(-1, 1, by = 0.25))
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomContour"))
  expect_gt(nrow(b$data[[1]]), 0)
})

test_that("mark_contour filled mode owns the level fill scale", {
  p <- plotit(contour_df(), encode(x = x, y = y, z = z)) |>
    mark_contour(filled = TRUE, bins = 8)
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomContourFilled"))
  expect_true("fill" %in% names(b$data[[1]]))
})

# ---- mark_qq / mark_qq_line ----
test_that("[BDD] mark_qq + mark_qq_line build a QQ diagnostic", {
  df <- data.frame(v = faithful$eruptions)
  p <- plotit(df, encode(x = v)) |>
    mark_qq() |>
    mark_qq_line()
  b <- .built(p)
  # ggplot2 4.0 renders QQ points through GeomPoint + the Qq stat, and the
  # reference line through the QqLine stat producing abline params.
  expect_s3_class(p@gg$layers[[1]]$geom, "GeomPoint")
  expect_s3_class(p@gg$layers[[1]]$stat, "StatQq")
  expect_s3_class(p@gg$layers[[2]]$stat, "StatQqLine")
  expect_equal(length(b$data), 2)
})

test_that("mark_qq resolves the distribution short name", {
  df <- data.frame(v = rexp(50))
  p <- plotit(df, encode(x = v)) |> mark_qq(distribution = "exp")
  expect_true(nrow(.built(p)$data[[1]]) > 0)
  expect_error(
    mark_qq(plotit(df, encode(x = v)), distribution = "not-a-dist"),
    "q\\*"
  )
})

test_that("mark_qq_line errors on unknown distribution", {
  df <- data.frame(v = 1:20)
  expect_error(
    plotit(df, encode(x = v)) |> mark_qq_line(distribution = "wat"),
    "not found"
  )
})

# ---- mark_ecdf ----
test_that("[BDD] mark_ecdf draws the empirical CDF as a step", {
  p <- plotit(faithful, encode(x = eruptions)) |> mark_ecdf()
  b <- .built(p)
  d <- b$data[[1]]
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomStep"))
  expect_equal(range(d$y), c(0, 1))
})

test_that("mark_ecdf groups compare", {
  df <- data.frame(
    value = c(iris$Sepal.Length, iris$Petal.Length),
    part = rep(c("Sepal", "Petal"), each = 150)
  )
  p <- plotit(df, encode(x = value, colour = part)) |> mark_ecdf()
  expect_true(nrow(.built(p)$data[[1]]) > 300)
})

# ---- mark_label ----
test_that("[BDD] mark_label draws boxed labels", {
  agg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
  p <- plotit(agg, encode(x = cyl, y = mpg, label = round(mpg, 1))) |>
    mark_label()
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomLabel"))
  expect_equal(nrow(b$data[[1]]), nrow(agg))
})

# ---- mark_forest ----
forest_df <- function() {
  data.frame(
    trial = paste0("T", 1:4),
    es = c(0.4, 0.3, 0.55, 0.2),
    lo = c(0.1, -0.05, 0.3, -0.1),
    hi = c(0.7, 0.65, 0.8, 0.5)
  )
}

test_that("[BDD] mark_forest adds bar, point, and reference layers", {
  p <- plotit(forest_df(), encode(x = es, y = trial, xmin = lo, xmax = hi)) |>
    mark_forest(ref = 0)
  b <- .built(p)
  expect_length(p@gg$layers, 3)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomErrorbar"))
  expect_true(inherits(p@gg$layers[[2]]$geom, "GeomPoint"))
  expect_true(inherits(p@gg$layers[[3]]$geom, "GeomVline"))
  expect_equal(b$data[[3]]$xintercept, 0)
})

test_that("mark_forest omits the rule without ref", {
  p <- plotit(forest_df(), encode(x = es, y = trial, xmin = lo, xmax = hi)) |>
    mark_forest()
  expect_length(p@gg$layers, 2)
})

test_that("mark_forest validates aesthetics", {
  df <- data.frame(y = c("A", "B"), es = c(1, 2))
  expect_error(
    plotit(df, encode(x = es, y = y)) |> mark_forest(),
    "xmin"
  )
})

test_that("mark_forest does not leak fill to the interval geom", {
  # plotit() injects AsIs colour+fill when nothing is mapped; the interval
  # bar must only receive interval channels (no "unknown aesthetics" warning).
  expect_silent(
    plotit(forest_df(), encode(x = es, y = trial, xmin = lo, xmax = hi)) |>
      mark_forest(ref = 0) |>
      .built()
  )
})

# ---- mark_area band dispatch ----
test_that("[BDD] mark_area routes ymin/ymax to geom_ribbon", {
  df <- data.frame(x = 1:10, lo = 1:10 - 0.5, hi = 1:10 + 0.5)
  p <- plotit(df, encode(x = x, ymin = lo, ymax = hi)) |> mark_area()
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomRibbon"))
})

test_that("mark_area keeps geom_area with y", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_area()
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomArea"))
})

test_that("mark_area band does not auto-dodge", {
  df <- data.frame(x = 1:10, lo = 1:10 - 0.5, hi = 1:10 + 0.5, g = "a")
  p <- plotit(df, encode(x = x, ymin = lo, ymax = hi, group = g)) |> mark_area()
  expect_false(inherits(p@gg$layers[[1]]$position, "PositionDodge"))
})

# ---- mark_errorbar modernization ----
test_that("mark_errorbar vertical caps stay an errorbar", {
  df <- data.frame(x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22))
  p <- plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
    mark_errorbar(width = 0.3)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomErrorbar"))
})

test_that("mark_errorbar caps = FALSE uses linerange", {
  df <- data.frame(x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22))
  p <- plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
    mark_errorbar(caps = FALSE)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomLinerange"))
})

test_that("mark_errorbar horizontal maps y position with xmin/xmax", {
  df <- data.frame(y = c("A", "B"), xmin = c(8, 18), xmax = c(12, 22))
  p <- plotit(df, encode(y = y, xmin = xmin, xmax = xmax)) |>
    mark_errorbar(orientation = "horizontal")
  b <- .built(p)
  expect_equal(nrow(b$data[[1]]), 2)
})

# ---- scale_radius (defunct, A2) ----
test_that("scale_radius is defunct with directed migration guidance", {
  p <- plotit(
    ggplot2::midwest,
    encode(x = popdensity, y = percollege, size = poptotal)
  ) |> mark_point()
  expect_error(scale_radius(p, range = c(1, 10)), "defunct")
  expect_error(scale_radius(p), "scale_size")
})

test_that("scale_size covers the former radius role (bubble encoding)", {
  p <- plotit(
    ggplot2::midwest,
    encode(x = popdensity, y = percollege, size = poptotal)
  ) |>
    mark_point() |>
    scale_size(range = c(1, 10))
  b <- .built(p)
  rng <- range(b$data[[1]]$size)
  expect_equal(round(rng[1], 4), 1)
  expect_equal(round(rng[2], 4), 10)
})

# ---- ggplot2 escape hatch: add_ggplot ----
test_that("[BDD] add_ggplot keeps the plotit wrapper", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p2 <- p |> add_ggplot(ggplot2::annotate("text", x = 3, y = 7.9, label = "hi", size = 3))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 2)
})

test_that("add_ggplot renders theme components", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  p2 <- p |> add_ggplot(ggplot2::theme_minimal(base_size = 11))
  b <- .built(p2)
  expect_equal(b$plot$theme$text$size, 11)
})

test_that("add_ggplot works on composites (patchwork semantics)", {
  p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  c1 <- compose_grid(p1, p1) |> add_ggplot(patchwork::plot_annotation(title = "T"))
  expect_s3_class(c1, "plotit::plotit_composite")
})

# ---- mark_rule global segment mode ----
test_that("mark_rule() picks up segment endpoints from the global mapping", {
  segs <- data.frame(
    x = c(1, 2), xend = c(2, 3), y = c(1, 2), yend = c(2, 3)
  )
  p <- plotit(segs, encode(x = x, y = y, xend = xend, yend = yend)) |>
    mark_rule(color = "grey40")
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomSegment"))
  expect_equal(nrow(b$data[[1]]), 2)
})

# ---- composite rejection stubs cover the new marks ----
test_that("new marks reject plotit_composite", {
  p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  cmp <- compose_grid(p1, p1)
  expect_error(mark_step(cmp), "not supported")
  expect_error(mark_curve(cmp), "not supported")
  expect_error(mark_forest(cmp), "not supported")
  # scale_radius is defunct since 1.0 (radius belongs to scale_size's
  # domain), so it aborts with migration guidance before any composite
  # dispatch is reached.
  expect_error(scale_radius(cmp), "defunct")
})

# ---- draw-time smoke tests ----
# ggplot_build() never exercises the grid linejoin/lineend parameters --
# invalid values only explode at grob draw time (a "miter" default once
# shipped past a green suite).  Render the mark families that carry
# stroke-style defaults to an in-memory raster device.
test_that("stroke-style defaults survive actual drawing", {
  skip_if_not_installed("ragg")
  econ <- ggplot2::economics
  cases <- list(
    step = plotit(econ, encode(x = date, y = unemploy)) |> mark_step(),
    ecdf = plotit(faithful, encode(x = eruptions)) |> mark_ecdf(),
    curve = plotit(
      data.frame(x = 0, y = 0, xend = 1, yend = 1),
      encode(x = x, y = y, xend = xend, yend = yend)
    ) |>
      mark_curve(),
    qqline = plotit(
      data.frame(v = faithful$eruptions), encode(x = v)
    ) |>
      mark_qq() |>
      mark_qq_line()
  )
  for (nm in names(cases)) {
    tmp <- tempfile(fileext = ".png")
    expect_error(
      {
        ragg::agg_png(tmp, width = 400, height = 300, res = 100)
        print(cases[[nm]]@gg)
        invisible(grDevices::dev.off())
      },
      NA,
      info = nm
    )
    unlink(tmp)
  }
})

# ---- catalogue integrity ----
test_that("every catalogued mark is exported and callable", {
  # (R CMD check has no man/ directory, so assert export membership rather
  # than Rd files on disk; roxygen guarantees the Rd.)
  ex <- getNamespaceExports("plotit")
  for (nm in plotit:::._CATALOG_MARKS) {
    expect_true(nm %in% ex, info = nm)
    expect_true(exists(nm, mode = "function"), info = nm)
  }
  for (nm in plotit:::._CATALOG_SCALES) {
    expect_true(nm %in% ex, info = nm)
  }
})

test_that("._MARK_BIND_AES covers every catalogued mark family it needs to", {
  bind <- plotit:::._MARK_BIND_AES
  # Marks that can render graph tables must declare a binding scope.
  for (nm in c(
    "mark_step", "mark_rug", "mark_spoke", "mark_curve",
    "mark_count", "mark_bin2d", "mark_contour", "mark_qq",
    "mark_qq_line", "mark_ecdf", "mark_label"
  )) {
    expect_true(nm %in% names(bind), info = nm)
  }
})

# ---- aesthetic-kind registry (layer-declared channels) ----
test_that("scale_* auto-detection sees layer-resolved channels", {
  e <- data.frame(source = c("a", "b"), target = c("b", "c"), w = c(1, 2))
  n <- data.frame(id = c("a", "b", "c"), m = c(10, 20, 5))
  p <- as_graph(e, nodes = n) |>
    plotit() |>
    layout_force(seed = 1) |>
    mark_point(data = ~nodes, encode(size = m)) |>
    scale_size()
  sc <- p@gg$scales$get_scales("size")
  expect_s3_class(sc, "ScaleContinuous")
})

test_that("discrete layer channels keep discrete auto-detection", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species)) |>
    scale_color()
  sc <- p@gg$scales$get_scales("colour")
  expect_true(inherits(sc, "ScaleDiscrete"))
})

# ---- mark_heatmap ----
# Ordered integer matrix: clustering must reorder rows/columns away from
# this layout, cluster = "none" must not.
.hm_mat <- function() {
  m <- matrix(1:30,
    nrow = 6,
    dimnames = list(paste0("g", 1:6), paste0("s", 1:5))
  )
  m[1, ] <- c(10, 11, 12, 1, 2)
  m[2, ] <- c(9, 8, 7, 20, 21)
  m[3, ] <- c(13, 14, 15, 3, 4)
  m[4, ] <- c(6, 5, 4, 22, 23)
  m[5, ] <- c(30, 29, 28, 5, 6)
  m[6, ] <- c(27, 26, 25, 7, 8)
  m
}

test_that("[BDD] mark_heatmap renders a matrix as a tile grid", {
  m <- .hm_mat()
  p <- plotit(m, encode()) |> mark_heatmap(cluster = "none")
  b <- .built(p)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomTile"))
  expect_equal(nrow(b$data[[1]]), 30)
  # Order preserved: rows/cols keep the matrix dimnames, and every tile's
  # value matches mat[row, col] (guards the expand.grid orientation).
  d <- p@gg$layers[[1]]$data
  expect_equal(levels(d$Var1), rownames(m))
  expect_equal(levels(d$Var2), colnames(m))
  expect_equal(d$value, as.vector(t(m)))
})

test_that("mark_heatmap accepts a wide numeric data.frame", {
  df <- as.data.frame(.hm_mat())
  p <- plotit(df, encode()) |> mark_heatmap(cluster = "none")
  expect_equal(nrow(.built(p)$data[[1]]), 30)
})

test_that("mark_heatmap accepts a tidy x/y/fill mapping", {
  long <- expand.grid(
    gene = c("a", "b", "c"), samp = c("p", "q"),
    stringsAsFactors = FALSE
  )
  long$val <- seq_len(nrow(long))
  p <- plotit(long, encode(x = samp, y = gene, fill = val)) |>
    mark_heatmap(cluster = "none")
  b <- .built(p)
  expect_equal(nrow(b$data[[1]]), 6)
  d <- p@gg$layers[[1]]$data
  expect_equal(levels(d$Var2), c("p", "q"))
  # xtabs orientation: mat[gene, samp] -- cell (a, p) holds long$val[1] = 1.
  expect_equal(d$value[d$Var1 == "a" & d$Var2 == "p"], 1)
})

test_that("mark_heatmap cluster reorders away from the input order", {
  kept <- plotit(.hm_mat(), encode()) |> mark_heatmap(cluster = "none")
  moved <- plotit(.hm_mat(), encode()) |> mark_heatmap(cluster = "both")
  dk <- kept@gg$layers[[1]]$data
  dm <- moved@gg$layers[[1]]$data
  expect_false(identical(levels(dk$Var1), levels(dm$Var1)))
  # Reordering is a permutation: the value multiset is unchanged.
  expect_equal(sort(dk$value), sort(dm$value))
})

test_that("mark_heatmap scale z-scores rows and columns", {
  p_row <- plotit(.hm_mat(), encode()) |>
    mark_heatmap(cluster = "none", scale = "row")
  d <- p_row@gg$layers[[1]]$data
  rms <- tapply(d$value, d$Var1, mean)
  rsd <- tapply(d$value, d$Var1, stats::sd)
  expect_true(all(abs(rms) < 1e-9))
  expect_true(all(abs(rsd - 1) < 1e-8))

  p_col <- plotit(.hm_mat(), encode()) |>
    mark_heatmap(cluster = "none", scale = "column")
  dc <- p_col@gg$layers[[1]]$data
  cms <- tapply(dc$value, dc$Var2, mean)
  expect_true(all(abs(cms) < 1e-9))
})

test_that("mark_heatmap owns a managed continuous fill scale, replaceable", {
  p <- plotit(.hm_mat(), encode()) |> mark_heatmap()
  expect_true(inherits(p@gg$scales$get_scales("fill"), "ScaleContinuous"))
  p2 <- suppressMessages(
    p |> scale_fill(trans = "identity", range = "brewer")
  )
  expect_true(inherits(p2@gg$scales$get_scales("fill"), "ScaleContinuous"))
  expect_true(!is.null(.built(p2)))
})

test_that("mark_heatmap blanks the synthetic axis titles", {
  p <- plotit(.hm_mat(), encode()) |> mark_heatmap()
  expect_true(inherits(p@gg$theme$axis.title, "element_blank"))
})

test_that("mark_heatmap validates input and arguments", {
  expect_error(
    plotit(data.frame(a = letters[1:3]), encode()) |> mark_heatmap(),
    "numeric"
  )
  expect_error(
    plotit(.hm_mat(), encode()) |> mark_heatmap(cluster = "rows"),
    "should be one of"
  )
})

test_that("mark_heatmap survives actual drawing", {
  skip_if_not_installed("ragg")
  p <- plotit(.hm_mat(), encode()) |> mark_heatmap(scale = "row")
  tmp <- tempfile(fileext = ".png")
  expect_error(
    {
      ragg::agg_png(tmp, width = 400, height = 300, res = 100)
      print(p@gg)
      invisible(grDevices::dev.off())
    },
    NA
  )
  unlink(tmp)
})

# ---- mark_rule data-segment mode keeps foreign channels out ----
test_that("mark_rule segment mode does not warn about injected fill", {
  # The default_color injection puts `fill` into the global mapping;
  # geom_segment used to reject it with "Ignoring unknown aesthetics".
  segs <- data.frame(
    x = c(1, 2), xend = c(2, 3), y = c(1, 2), yend = c(2, 3)
  )
  p <- plotit(segs, encode(x = x, y = y, xend = xend, yend = yend)) |>
    mark_rule()
  expect_no_warning(.built(p))
})
