# Stage-8 visual bug regression tests (T1-T11).
# Every assertion is vision-free: build-state (2a) or pixel geometry (2b).
# Run: devtools::test()

plotit <- plotit
encode <- encode
suppressMessages(pkgload::load_all(".", quiet = TRUE))

# ---- local helpers ----
.built <- function(p) ggplot2::ggplot_build(p@gg)

# Pixel ink helpers (2b): white threshold <0.95, y grows DOWN (row order).
._mask <- function(path) {
  img <- png::readPNG(path)
  if (length(dim(img)) == 2) return(img < 0.95)
  rgb <- img[, , 1:3]
  alpha <- if (dim(img)[3] >= 4) img[, , 4] else array(1, dim(rgb)[1:2])
  apply(rgb < 0.95, c(1, 2), any) & (alpha >= 0.5)
}
._ink_bbox <- function(path, region = NULL) {
  mask <- ._mask(path)
  if (!is.null(region)) {
    h <- nrow(mask); w <- ncol(mask)
    r <- rep(region, length.out = 4)
    xr <- sort(round(r[1:2] * (w - 1)) + 1); yr <- sort(round(r[3:4] * (h - 1)) + 1)
    xr[1] <- max(1, xr[1]); xr[2] <- min(w, xr[2])
    yr[1] <- max(1, yr[1]); yr[2] <- min(h, yr[2])
    keep <- mask; keep[] <- FALSE
    keep[yr[1]:yr[2], xr[1]:xr[2]] <- mask[yr[1]:yr[2], xr[1]:xr[2], drop = FALSE]
    mask <- keep
  }
  rows <- which(rowSums(mask) > 0); cols <- which(colSums(mask) > 0)
  if (length(rows) == 0 || length(cols) == 0) return(rep(NA_real_, 4))
  c(x0 = (min(cols) - 1) / (ncol(mask) - 1), x1 = (max(cols) - 1) / (ncol(mask) - 1),
    y0 = (min(rows) - 1) / (nrow(mask) - 1), y1 = (max(rows) - 1) / (nrow(mask) - 1))
}
._center_offset <- function(path, region = NULL) {
  bb <- ._ink_bbox(path, region)
  if (anyNA(bb)) return(c(NA, NA))
  c(dx = (bb[1] + bb[2]) / 2 - 0.5, dy = (bb[3] + bb[4]) / 2 - 0.5)
}
._margin_top_ink <- function(path, band = 0.08) {
  mask <- ._mask(path)
  bh <- max(1, round(band * nrow(mask)))
  sum(mask[seq_len(bh), , drop = FALSE]) / sum(mask)
}
._legend_entries <- function(path, band = 0.14) {
  img <- png::readPNG(path)
  rgb <- img[, , 1:3]
  w <- ncol(img)
  x0 <- max(1, round(w * (1 - band)))
  rgb <- rgb[, x0:w, , drop = FALSE]
  sat <- apply(rgb, c(1, 2), function(p) max(p) - min(p) > 0.15)
  rowcov <- rowSums(sat) > 0
  rle <- rle(rowcov)
  sum(rle$lengths[rle$values] > 1)
}
._render_png <- function(p, tag, width = 900, height = 620) {
  f <- tempfile(pattern = tag, fileext = ".png")
  grDevices::png(f, width = width, height = height, res = 120)
  on.exit(grDevices::dev.off(), add = TRUE)
  print(p)
  f
}

test_that("[BDD] T1.1 polar blanks every axis element (plain and radial)", {
  df <- data.frame(seg = c("A", "B", "C"), val = c(10, 8, 5))
  p1 <- df |> plotit(encode(x = 1, y = val, fill = seg)) |>
    mark_bar(position = "stack", width = 1) |>
    project_polar(theta = "y")
  p2 <- df |> plotit(encode(x = 1, y = val, fill = seg)) |>
    mark_bar(position = "stack", width = 1) |>
    project_polar(theta = "y", inner_radius = 0.5)
  for (p in list(p1, p2)) {
    for (el in c("axis.line", "axis.ticks", "axis.text", "axis.title")) {
      expect_true(inherits(ggplot2::calc_element(el, p@gg$theme), "element_blank"),
        info = sprintf("%s under polar", el))
    }
  }
})

test_that("[BDD] T1.2 polar panels keep the full-extent layout (border guard)", {
  df <- data.frame(seg = c("A", "B", "C"), val = c(10, 8, 5))
  p <- df |> plotit(encode(x = 1, y = val, fill = seg)) |>
    mark_bar(position = "stack", width = 1) |>
    project_polar(theta = "y")
  bg <- ggplot2::calc_element("panel.background", p@gg$theme)
  expect_true(inherits(bg, "element_rect"))
  expect_false(is.na(bg$colour))
})

test_that("[BDD] T1.2/T1.3 polar renders centred with a real body (pixels)", {
  set.seed(42)
  df <- data.frame(a = c(rnorm(200, 0, 1), rnorm(200, 3, 0.7)))
  p <- df |> plotit(encode(x = a)) |> mark_histogram(bins = 24) |>
    project_polar(theta = "x")
  f <- ._render_png(p, "t1hist")
  co <- ._center_offset(f, c(0.05, 0.85, 0.05, 0.95))
  expect_true(all(abs(co) <= 0.06), info = sprintf("dx=%.3f dy=%.3f", co[1], co[2]))
  bb <- ._ink_bbox(f)
  span <- (bb[2] - bb[1]) * (bb[4] - bb[3])
  expect_true(span >= 0.5, info = sprintf("span=%.3f", span))
})

test_that("[BDD] T1.4 polar removes the white rim border from bar sectors", {
  df <- data.frame(seg = c("A", "B", "C"), val = c(10, 8, 5))
  p <- df |> plotit(encode(x = 1, y = val, fill = seg)) |>
    mark_bar(position = "stack", width = 1) |>
    project_polar(theta = "y")
  # the white hairline border injected by mark_bar must be dropped in polar
  b <- .built(p)
  expect_false(any(b$data[[1]]$linewidth > 0))
})

test_that("[BDD] T2.2 compose_grid collects identical legends", {
  set.seed(1)
  d <- data.frame(x = rnorm(60), y = rnorm(60), g = rep(letters[1:3], 20))
  p1 <- d |> plotit(encode(x = x, y = y, colour = g)) |> mark_point()
  p2 <- d |> plotit(encode(x = x, y = y, colour = g)) |> mark_line()
  cnt <- function(cmp) {
    gg <- getFromNamespace("._apply_annotations", "plotit")(cmp)
    gr <- patchwork::patchworkGrob(gg)
    walk <- function(g) {
      n <- 0L
      if (!is.null(g$layout)) n <- sum(grepl("guide", g$layout$name))
      for (gr_ in g$grobs) if (inherits(gr_, "gtable") || inherits(gr_, "gTree")) n <- n + walk(gr_)
      n
    }
    walk(gr)
  }
  n_collect <- cnt(compose_grid(p1, p2, ncol = 2))
  n_keep <- cnt(compose_grid(p1, p2, ncol = 2, guides = "keep"))
  expect_true(n_collect < n_keep,
    info = sprintf("collect=%d keep=%d", n_collect, n_keep))
  expect_true(n_collect <= 4, info = sprintf("collect=%d", n_collect))
})

test_that("[BDD] T2.3 compose_inset parks its legend inside the inset", {
  set.seed(2)
  d <- data.frame(x = rnorm(50), y = rnorm(50), g = rep(letters[1:3], length.out = 50))
  cmp <- compose_inset(
    d |> plotit(encode(x = x, y = y)) |> mark_point(alpha = 0.4),
    d |> plotit(encode(x = x, y = y, colour = g)) |> mark_point() |>
      project_cartesian(xlim = c(-1, 1), ylim = c(-1, 1)),
    left = 0.55, bottom = 0.55, right = 0.95, top = 0.95
  )
  f <- ._render_png(cmp, "t2inset")
  mask <- ._mask(f)
  w <- ncol(mask)
  right_ink <- sum(mask[, (w - round(w * 0.05) + 1):w, drop = FALSE]) / sum(mask)
  expect_true(right_ink <= 0.02, info = sprintf("right band ink=%.3f", right_ink))
})

test_that("[BDD] T2.4 facet variable == colour variable hides the legend", {
  set.seed(3)
  d <- data.frame(x = rnorm(60), y = rnorm(60), g = rep(letters[1:3], 20))
  p <- d |> plotit(encode(x = x, y = y, colour = g)) |> mark_point() |>
    split_wrap(g)
  expect_equal(length(.built(p)$plot$guides$params), 0L)
})

test_that("[BDD] T4.3 significance brackets stay inside the panel", {
  set.seed(7)
  d <- data.frame(grp = factor(rep(c("A", "B", "C", "D"), each = 20)), v = rnorm(80))
  comp <- data.frame(group1 = c("A", "B", "C"), group2 = c("D", "D", "D"), label = "*")
  p <- d |> plotit(encode(x = grp, y = v)) |> mark_boxplot() |>
    mark_significance(comp)
  f <- ._render_png(p, "t4sig", width = 800, height = 560)
  expect_true(._margin_top_ink(f, 0.08) <= 0.02,
    info = sprintf("top ink=%.3f", ._margin_top_ink(f, 0.08)))
})

test_that("[BDD] T5.1 mark_corr defaults to a diverging fill scale", {
  p <- plotit(mtcars, encode()) |> mark_corr()
  sc <- p@gg$scales$get_scales("fill")
  expect_false(is.null(sc))
  # Render-accurate: resolve the fill colour of the most-negative and
  # most-positive cells from the BUILT data.
  vals <- p@gg$layers[[1]]$data$value
  bd <- .built(p)$data[[1]]$fill
  i_lo <- which.min(vals); i_hi <- which.max(vals)
  col_lo <- bd[i_lo]; col_hi <- bd[i_hi]
  r_lo <- grDevices::col2rgb(col_lo); r_hi <- grDevices::col2rgb(col_hi)
  reddish <- r_lo[1] > r_lo[2] + 40 & r_lo[1] > r_lo[3] + 20
  bluish <- r_hi[3] > r_hi[1] + 40 & r_hi[3] > r_hi[2] + 20
  expect_true(reddish, info = paste0("low-end colour: ", col_lo))
  expect_true(bluish, info = paste0("high-end colour: ", col_hi))
})

test_that("[BDD] T5.2 mark_heatmap honors range = \"RdBu\"", {
  mat <- matrix(rnorm(60), nrow = 6, dimnames = list(paste0("g", 1:6), paste0("s", 1:10)))
  p <- plotit(mat, encode()) |> mark_heatmap(scale = "row", range = "RdBu")
  sc <- p@gg$scales$get_scales("fill")
  expect_false(is.null(sc))
  # Render-accurate: resolve the fill colour of the most-negative and
  # most-positive cells from the BUILT data.
  vals <- p@gg$layers[[1]]$data$value
  bd <- .built(p)$data[[1]]$fill
  i_lo <- which.min(vals); i_hi <- which.max(vals)
  col_lo <- bd[i_lo]; col_hi <- bd[i_hi]
  r_lo <- grDevices::col2rgb(col_lo); r_hi <- grDevices::col2rgb(col_hi)
  reddish <- r_lo[1] > r_lo[2] + 40 & r_lo[1] > r_lo[3] + 20
  bluish <- r_hi[3] > r_hi[1] + 40 & r_hi[3] > r_hi[2] + 20
  expect_true(reddish, info = paste0("low-end colour: ", col_lo))
  expect_true(bluish, info = paste0("high-end colour: ", col_hi))
})

test_that("[BDD] T5.3 discrete variable + auto continuous scheme warns", {
  set.seed(4)
  d <- data.frame(x = rnorm(40), y = rnorm(40), g = factor(rep(letters[1:3], length.out = 40)))
  expect_warning(
    d |> plotit(encode(x = x, y = y, colour = g)) |> mark_point() |>
      scale_color(range = "viridis"),
    "discrete", ignore.case = TRUE
  )
})

test_that("[BDD] T5.5 mark_bin2d defaults to a binned fill scale", {
  set.seed(5)
  d <- data.frame(x = rnorm(300), y = rnorm(300))
  p <- d |> plotit(encode(x = x, y = y)) |> mark_bin2d()
  sc <- p@gg$scales$get_scales("fill")
  expect_true(grepl("Binned", class(sc)[1]))
})

test_that("[BDD] T6 grouped boxes/bars on numeric x warn", {
  set.seed(6)
  d <- data.frame(y = rnorm(90), numx = rep(c(1, 2, 3), each = 30), grp = rep(c("a", "b"), 45))
  expect_warning(
    d |> plotit(encode(x = numx, y = y, fill = grp)) |> mark_boxplot(),
    "overlap", ignore.case = TRUE
  )
  expect_warning(
    aggregate(y ~ numx + grp, d, mean) |>
      plotit(encode(x = numx, y = y, fill = grp)) |> mark_bar(),
    "overlap", ignore.case = TRUE
  )
})

test_that("[BDD] T9.1 scale_x identity on a Date column warns and routes to date", {
  d <- data.frame(date = seq(as.Date("2015-01-01"), by = "day", length.out = 400),
    v = cumsum(rnorm(400)))
  warn <- character()
  p <- withCallingHandlers(
    d |> plotit(encode(x = date, y = v)) |> mark_line() |> scale_x(trans = "identity"),
    warning = function(w) { warn <<- c(warn, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  expect_true(any(grepl("Date", warn, ignore.case = TRUE)))
  labs <- .built(p)$layout$panel_params[[1]]$x$get_labels()
  # Date labels carry a 4-digit year (month names are locale-dependent).
  expect_true(any(grepl("[0-9]{4}", labs)))
})

test_that("[BDD] T9.2 project_parallel default alpha is low", {
  p <- iris |> plotit(encode()) |>
    project_parallel(columns = c("Sepal.Length", "Sepal.Width"), group = "Species")
  expect_true(p@gg$layers[[1]]$aes_params$alpha < 0.35)
})

test_that("[BDD] T11.1 split_grid accepts rows ~ cols formula", {
  d <- data.frame(x = rnorm(40), y = rnorm(40), r = rep(letters[1:2], 20), c = rep(1:2, 20))
  p <- d |> plotit(encode(x = x, y = y)) |> mark_point() |>
    split_grid(r ~ c)
  b <- .built(p)
  expect_true(nrow(b$layout$layout) == 4)
})