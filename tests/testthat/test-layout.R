# Tests for layout_* engines and pipeline integration

mk_graph <- function() {
  as_graph(data.frame(
    source = c("a", "a", "b", "c"),
    target = c("b", "c", "c", "d")
  ))
}

test_that("[BDD] layout_force is deterministic under a fixed seed", {
  g1 <- mk_graph() |> layout_force(seed = 42)
  g2 <- mk_graph() |> layout_force(seed = 42)

  expect_identical(g1$nodes$x, g2$nodes$x)
  expect_identical(g1$nodes$y, g2$nodes$y)
})

test_that("layout_force: nodes and edges gain geometry columns", {
  g <- layout_force(mk_graph(), seed = 1)

  expect_true(all(c("x", "y") %in% names(g$nodes)))
  expect_true(all(c("x", "y", "xend", "yend") %in% names(g$edges)))
  # edge endpoints resolve to the same coordinates as their nodes
  x_of <- stats::setNames(g$nodes$x, g$nodes$id)
  expect_equal(g$edges$x, unname(x_of[g$edges$source]))
})

test_that("[BDD] layouts are idempotent: chaining equals last-wins", {
  fresh <- layout_force(mk_graph(), seed = 7)
  chained <- layout_circle(mk_graph()) |> layout_force(seed = 7)

  expect_identical(chained$nodes$x, fresh$nodes$x)
  expect_false(is.null(chained$nodes$y))
})

test_that("[BDD] layout_circle places nodes on a unit circle; degree sorts", {
  g_id <- layout_circle(mk_graph())
  r <- sqrt(g_id$nodes$x^2 + g_id$nodes$y^2)
  expect_equal(r, rep(1, nrow(g_id$nodes)))

  # 'c' has degree 3 (a-c, b-c, c-d) -> first when order_by = "degree"
  g_deg <- layout_circle(mk_graph(), order_by = "degree")
  expect_identical(g_deg$nodes$id[1], "c")
})

test_that("[BDD] layout_tree orients root per direction and supports hclust", {
  hc <- hclust(dist(USArrests[, 1:3]))
  down <- as_graph(hc) |> layout_tree(direction = "down")
  up <- as_graph(hc) |> layout_tree(direction = "up")

  # The tree root is the one node never referenced as a child.
  root_id <- setdiff(down$nodes$id, down$edges$target)
  expect_length(root_id, 1)

  leaves <- down$nodes$id[down$nodes$leaf]
  expect_length(leaves, sum(down$nodes$leaf))
  expect_false(anyNA(c(down$nodes$x, up$nodes$x)))
  # root on top for "down": maximal y among internal nodes
  internal <- down$nodes[!down$nodes$leaf, ]
  expect_identical(internal$id[which.max(internal$y)], root_id)
  # flipped direction puts the root at the bottom
  internal_up <- up$nodes[!up$nodes$leaf, ]
  expect_identical(internal_up$id[which.min(internal_up$y)], root_id)
})

test_that("layout_tree: cyclic graph aborts with guidance", {
  cyclic <- data.frame(
    source = c("a", "b", "c"), target = c("b", "c", "a")
  )
  expect_error(layout_tree(as_graph(cyclic, directed = TRUE)), "root|cycle")
})

test_that("[BDD] pipeline: plotit(graph) |> layout_* |> marks builds layers", {
  p <- plotit(mk_graph()) |>
    layout_force(seed = 3) |>
    mark_point(data = ~nodes) |>
    mark_rule(data = ~edges, colour = "grey70")

  gb <- ggplot2::ggplot_build(p@gg)
  expect_length(gb$plot$layers, 2)

  # auto-bind: point layer mapping has implicit x/y
  mp <- gb$plot$layers[[1]]$mapping
  expect_identical(rlang::as_label(mp$x), "x")
  expect_identical(rlang::as_label(mp$y), "y")
  # rule layer binds all four endpoint aesthetics
  mr <- gb$plot$layers[[2]]$mapping
  expect_setequal(
    intersect(names(mr), c("x", "y", "xend", "yend")),
    c("x", "y", "xend", "yend")
  )
  # graph layers never inherit the global mapping
  expect_false(gb$plot$layers[[1]]$inherit.aes)
})

test_that("[BDD] auto-bind precedence: explicit mappings win", {
  p <- plotit(mk_graph()) |>
    layout_circle() |>
    mark_point(data = ~nodes, encode(x = id))

  mp <- ggplot2::ggplot_build(p@gg)$plot$layers[[1]]$mapping
  expect_identical(rlang::as_label(mp$x), "id") # not overwritten by autobind
  expect_identical(rlang::as_label(mp$y), "y") # still bound implicitly
})

test_that("resolver errors name available tables and required setup", {
  g <- plotit(mk_graph()) |> layout_circle()

  expect_error(mark_point(g, data = ~nope), "nope")
  expect_error(mark_point(g, data = NULL), "~nodes")
  tabular_err <- tryCatch(
    mark_point(plotit(iris, encode(x = Species)), data = ~nodes),
    error = function(e) conditionMessage(e)
  )
  expect_match(tabular_err, "as_graph")
  # two-sided formulas rejected
  expect_error(mark_point(g, data = nodes ~ edges), "one-sided")
})

test_that("[BDD] mark_rule segment mode works with plain data.frames too", {
  segs <- data.frame(x0 = 1, y0 = 2, x1 = 4, y1 = 5)

  p <- plotit(segs, encode()) |>
    mark_rule(
      data = segs,
      mapping = encode(x = x0, y = y0, xend = x1, yend = y1),
      colour = "grey50"
    )

  gb <- ggplot2::ggplot_build(p@gg)
  expect_s3_class(gb$plot$layers[[1]]$geom, "GeomSegment")
  expect_false(gb$plot$layers[[1]]$inherit.aes)
})

test_that("mark_rule segment mode guards conflicting usage", {
  segs <- data.frame(x0 = 1, y0 = 2, x1 = 4, y1 = 5)
  p <- plotit(segs, encode())

  expect_error(
    mark_rule(p, data = segs, x = 1),
    "conflict"
  )
  expect_error(
    mark_rule(p, data = segs),
    "requires aesthetics"
  )
})

test_that("layout_* on non-graph plots aborts with setup hint", {
  expect_error(layout_force(plotit(iris, encode(x = Species))), "as_graph")
  expect_error(layout_circle(plotit(iris, encode(x = Species))), "as_graph")
})


# ---- layout_dendrogram ------------------------------------------------------

test_that("[BDD] layout_dendrogram reproduces hclust leaf order", {
  hc <- hclust(dist(USArrests[1:8, ]))
  g <- as_graph(hc) |> layout_dendrogram(direction = "down")

  leaves <- g$nodes[g$nodes$leaf %in% TRUE, ]
  expect_length(leaves$id, length(hc$labels))
  # merge sides (.side) must survive: left-to-right leaf order == hc$order
  expect_identical(leaves$id[order(leaves$x)], hc$labels[hc$order])
  # root sits on top for "down": y equals raw height
  expect_equal(g$nodes$y, g$nodes$height)
})

test_that("layout_dendrogram flips orientation per direction", {
  hc <- hclust(dist(USArrests[1:6, ]))
  down <- as_graph(hc) |> layout_dendrogram(direction = "down")
  up <- as_graph(hc) |> layout_dendrogram(direction = "up")

  expect_equal(down$nodes$y, -up$nodes$y)
  expect_equal(down$nodes$x, up$nodes$x)
})

test_that("layout_dendrogram maps edge endpoints to node coordinates", {
  hc <- hclust(dist(USArrests[1:6, ]))
  g <- as_graph(hc) |> layout_dendrogram()
  x_of <- stats::setNames(g$nodes$x, g$nodes$id)
  expect_equal(g$edges$x, unname(x_of[g$edges$source]))
  expect_equal(g$edges$yend, unname(stats::setNames(g$nodes$y, g$nodes$id)[g$edges$target]))
})

test_that("layout_dendrogram rejects graphs without merge columns", {
  g <- as_graph(data.frame(source = c("a", "b"), target = c("b", "c")))
  expect_error(layout_dendrogram(g), "hclust|height")
})

# ---- layout_treemap ---------------------------------------------------------

.hierarchy_df <- function() {
  data.frame(
    id = c("root", "A", "B", "a1", "a2"),
    parent = c(NA, "root", "root", "A", "A"),
    value = c(NA, NA, 50, 30, 20)
  )
}

test_that("[BDD] layout_treemap tiles leaves proportional to value", {
  tg <- .hierarchy_df() |>
    as_graph() |>
    plotit() |>
    layout_treemap()
  lv <- tg@graph$leaves

  expect_setequal(names(tg@graph), c("nodes", "edges", "leaves"))
  expect_setequal(lv$id, c("B", "a1", "a2"))
  in_unit_square <- lv$xmin >= 0 & lv$xmax <= 1 &
    lv$ymin >= 0 & lv$ymax <= 1
  expect_true(all(in_unit_square))

  area <- function(df) with(df, (xmax - xmin) * (ymax - ymin))
  a1 <- area(lv[lv$id == "a1", ])
  a2 <- area(lv[lv$id == "a2", ])
  expect_equal(a1 / a2, 30 / 20, tolerance = 0.05)

  # parent rectangles contain their children
  pa <- tg@graph$nodes[tg@graph$nodes$id == "A", ]
  ca <- lv[lv$id %in% c("a1", "a2"), ]
  expect_gte(pa$xmin, min(ca$xmin) - 1e-9)
  expect_lte(pa$xmax, max(ca$xmax) + 1e-9)
  expect_lte(pa$ymax, max(ca$ymax) + 1e-9)
})

test_that("[BDD] layout_treemap renders via mark_rect(~leaves)", {
  p <- .hierarchy_df() |>
    as_graph() |>
    plotit() |>
    layout_treemap() |>
    mark_rect(data = ~leaves, encode(fill = id))
  built <- suppressWarnings(ggplot2::ggplot_build(p@gg))
  expect_s3_class(built$plot$layers[[1]]$geom, "GeomRect")
  expect_equal(nrow(built$data[[1]]), 3)
  expect_no_warning(ggplot2::ggplot_build(p@gg))
})

test_that("layout_treemap validates leaf sizes", {
  bad_missing <- data.frame(
    id = c("r", "a"), parent = c(NA, "r"), value = c(NA, NA)
  )
  expect_error(
    layout_treemap(as_graph(bad_missing)), "positive finite"
  )
  bad_zero <- data.frame(
    id = c("r", "a"), parent = c(NA, "r"), value = c(NA, 0)
  )
  expect_error(
    layout_treemap(as_graph(bad_zero)), "a"
  )
  no_value <- as_graph(data.frame(source = "a", target = "b"))
  expect_error(layout_treemap(no_value), "value")
})

# ---- layout_sankey ----------------------------------------------------------

.sankey_edges <- function() {
  data.frame(
    source = c("S", "S", "A", "B"),
    target = c("A", "B", "T", "T"),
    value = c(5, 5, 5, 5)
  )
}

test_that("[BDD] layout_sankey emits three tables with bounded geometry", {
  sg <- as_graph(.sankey_edges()) |>
    plotit() |>
    layout_sankey()
  g <- sg@graph

  expect_setequal(names(g), c("nodes", "edges", "ribbons"))
  nr <- g$nodes
  expect_true(all(nr$xmin >= 0 & nr$xmax <= 1))
  expect_true(all(nr$ymin >= -1e-12 & nr$ymax <= 1 + 1e-12))
  # ribbons carry long-form polygon rows plus inherited edge attributes
  expect_setequal(
    intersect(
      c(".ribbon_id", "x", "y", "source", "target", "value"),
      names(g$ribbons)
    ),
    c(".ribbon_id", "x", "y", "source", "target", "value")
  )
  expect_equal(nrow(g$ribbons), nrow(.sankey_edges()) * 2 * 50)
})

test_that("[BDD] layout_sankey stacks same-layer nodes without overlap", {
  sg <- as_graph(.sankey_edges()) |>
    plotit() |>
    layout_sankey()
  nr <- sg@graph$nodes
  mid <- nr[nr$id %in% c("A", "B"), ]
  mid <- mid[order(mid$ymin), ]
  # vertical gap between stacked siblings is at least the padding
  expect_gte(mid$ymin[2] - mid$ymax[1], 0.02 - 1e-9)
})

test_that("layout_sankey requires an acyclic positive-weight DAG", {
  cyclic <- data.frame(source = c("a", "b"), target = c("b", "a"))
  expect_error(
    layout_sankey(as_graph(cyclic, directed = TRUE)),
    "cycle|DAG"
  )

  selfloop <- data.frame(source = "a", target = "a", value = 1)
  expect_error(layout_sankey(as_graph(selfloop)), "self-loop")

  neg <- data.frame(source = "a", target = "b", value = -1)
  expect_error(layout_sankey(as_graph(neg)), "non-negative")
})

test_that("layout_sankey is fully deterministic without a seed", {
  g1 <- as_graph(.sankey_edges()) |> layout_sankey()
  g2 <- as_graph(.sankey_edges()) |> layout_sankey()
  expect_identical(g1$nodes, g2$nodes)
  expect_identical(g1$ribbons, g2$ribbons)
})

test_that("[BDD] layout_sankey ribbons span their own endpoints", {
  g <- as_graph(.sankey_edges()) |> layout_sankey()
  nr <- g$nodes
  for (r in seq_len(nrow(g$edges))) {
    rb <- g$ribbons[g$ribbons$.ribbon_id == r, ]
    sx <- nr$xmax[match(g$edges$source[r], nr$id)]
    tx <- nr$xmin[match(g$edges$target[r], nr$id)]
    # each ribbon must traverse exactly its own source->target x range;
    # regression guard against shared/recycled sampling profiles
    expect_equal(min(rb$x), sx)
    expect_equal(max(rb$x), tx)
    # vertical extent at the left end equals value * node-scale k, where
    # sum of source-side outgoing thicknesses equals the source height
    left_rows <- rb[rb$x == min(rb$x), ]
    src_top <- nr$ymax[match(g$edges$source[r], nr$id)]
    src_bot <- nr$ymin[match(g$edges$source[r], nr$id)]
    expect_true(diff(range(left_rows$y)) <= src_top - src_bot + 1e-12)
  }
})

test_that("[BDD] layout_sankey renders through polygon + rect marks", {
  p <- as_graph(.sankey_edges()) |>
    plotit() |>
    layout_sankey() |>
    mark_polygon(
      data = ~ribbons,
      encode(fill = source, group = .ribbon_id),
      alpha = 0.5
    ) |>
    mark_rect(data = ~nodes, encode(fill = id))
  built <- suppressWarnings(ggplot2::ggplot_build(p@gg))
  expect_length(built$plot$layers, 2)
  expect_s3_class(built$plot$layers[[1]]$geom, "GeomPolygon")
  expect_s3_class(built$plot$layers[[2]]$geom, "GeomRect")
  expect_no_warning(ggplot2::ggplot_build(p@gg))
})

# ---- layout_chord ----------------------------------------------------------

.chord_edges <- function() {
  data.frame(
    source = c("A", "A", "B", "B", "C"),
    target = c("B", "C", "C", "D", "D"),
    value = c(10, 5, 8, 3, 6)
  )
}

test_that("[BDD] layout_chord: angular budget and proportional sectors", {
  g <- as_graph(.chord_edges()) |>
    plotit() |>
    layout_chord()
  gr <- g@graph
  expect_setequal(names(gr), c("nodes", "edges", "arcs", "ribbons"))

  n <- nrow(gr$nodes)
  spans <- gr$nodes$arc_hi - gr$nodes$arc_lo
  # full angular coverage: spans + gaps == 2*pi
  expect_equal(sum(spans) + 0.03 * n, 2 * pi, tolerance = 1e-9)
  # span exactly proportional to flow_total
  expected <- gr$nodes$flow_total * (2 * pi - 0.03 * n) / sum(gr$nodes$flow_total)
  expect_equal(spans, expected, tolerance = 1e-12)
})

test_that("[BDD] layout_chord orders sectors by descending total by default", {
  g_total <- as_graph(.chord_edges()) |>
    plotit() |>
    layout_chord()
  g_app <- as_graph(.chord_edges()) |>
    plotit() |>
    layout_chord(order_by = "appearance")

  # clockwise sequence from 12 o'clock (max arc_hi) is descending total
  circ <- g_total@graph$nodes[order(-g_total@graph$nodes$arc_hi), ]
  expect_true(!is.unsorted(rev(circ$flow_total)))

  # appearance mode starts with the first input node at 12 o'clock
  top_app <- g_app@graph$nodes[which.max(g_app@graph$nodes$arc_hi), ]
  expect_identical(top_app$id, "A")
})

test_that("[BDD] layout_chord ribbons attach at the ring and bow inward", {
  g <- as_graph(.chord_edges()) |>
    plotit() |>
    layout_chord()
  gr <- g@graph
  r_in <- 0.65
  np <- 60

  # every ribbon point stays inside (or on) the attach radius
  expect_lte(max(sqrt(gr$ribbons$x^2 + gr$ribbons$y^2)), r_in + 1e-9)

  for (r in seq_len(nrow(gr$edges))) {
    rb <- gr$ribbons[gr$ribbons$.ribbon_id == r, ]
    # first chain = source attach arc: every point exactly on the ring
    src_r <- sqrt(rb$x[1:np]^2 + rb$y[1:np]^2)
    expect_equal(unique(round(src_r, 10)), r_in)
    # interior bows strictly below the ring (nonzero curvature)
    expect_lt(min(sqrt(rb$x^2 + rb$y^2)), r_in - 0.05)
    # angular containment of the source sub-span within its node arc
    src_row <- gr$edges$source[r]
    arc <- gr$nodes[gr$nodes$id == src_row, ]
    th <- atan2(rb$y[src_idx <- 1:np], rb$x[src_idx])
    # wrap sampled angles into the arc's own domain (arcs may cross -pi)
    th_wrapped <- arc$arc_lo + ((th - arc$arc_lo) %% (2 * pi))
    expect_true(all(th_wrapped <= arc$arc_hi + 1e-9))
  }
})

test_that("[BDD] layout_chord aggregates duplicate pairs; self-loops split", {
  e_dup <- rbind(.chord_edges(), .chord_edges()[1, ]) # duplicate A->B
  g2 <- as_graph(e_dup) |> layout_chord()
  expect_equal(nrow(g2$ribbons) / (4 * 60 - 2), 5) # still 5 bands
  # duplicated A->B rows sum into that pair only: A = (10+10) + 5
  a_total <- g2$nodes$flow_total[g2$nodes$id == "A"]
  expect_equal(a_total, 25)

  e_sl <- data.frame(
    source = c("X", "X"), target = c("Y", "X"),
    value = c(4, 2)
  )
  g3 <- as_graph(e_sl) |> layout_chord()
  expect_equal(nrow(g3$nodes), 2)
  expect_equal(nrow(g3$ribbons), 2 * (4 * 60 - 2))
  # X: out(4) + self-loop counted at both ends (2 + 2)
  expect_equal(g3$nodes$flow_total[g3$nodes$id == "X"], 8)
  expect_equal(g3$nodes$flow_total[g3$nodes$id == "Y"], 4)
})

test_that("layout_chord validates inputs", {
  neg <- data.frame(source = "a", target = "b", value = -1)
  expect_error(layout_chord(as_graph(neg)), "non-negative")

  empty <- as_graph(data.frame(
    source = character(),
    target = character()
  ))
  expect_error(layout_chord(empty), "at least one edge")
})

test_that("layout_chord is fully deterministic", {
  g1 <- as_graph(.chord_edges()) |> layout_chord()
  g2 <- as_graph(.chord_edges()) |> layout_chord()
  expect_identical(g1$nodes, g2$nodes)
  expect_identical(g1$arcs, g2$arcs)
  expect_identical(g1$ribbons, g2$ribbons)
})

# ---- self-contained force engine (no igraph) -------------------------------

test_that("layout_force preserves the caller's RNG stream", {
  set.seed(7)
  ref <- rnorm(3)
  invisible(layout_force(mk_graph(), seed = 9))
  set.seed(7)
  expect_equal(ref, c(rnorm(1), rnorm(1), rnorm(1)))
})

test_that("layout_force output stays finite inside the unit box", {
  g <- layout_force(mk_graph(), seed = 3, iterations = 200)
  expect_true(all(is.finite(g$nodes$x)) && all(is.finite(g$nodes$y)))
  # B5 (design/03 <U+00A7>5.4): coordinates land in the [0.05, 0.95]^2 canvas
  expect_gte(min(g$nodes$x), 0.05 - 1e-9)
  expect_lte(max(g$nodes$x), 0.95 + 1e-9)
  expect_gte(min(g$nodes$y), 0.05 - 1e-9)
  expect_lte(max(g$nodes$y), 0.95 + 1e-9)
})

test_that("layout_force weights change attraction and validate input", {
  base <- layout_force(mk_graph(), seed = 5)$nodes
  weighted <- layout_force(mk_graph(), seed = 5, weights = c(9, 9, 9, 9))$nodes
  expect_false(isTRUE(all.equal(base$x, weighted$x)))

  expect_error(
    layout_force(mk_graph(), seed = 1, weights = c(-1, 1, 1, 1)),
    "non-negative"
  )
})

test_that("layout_force warns on unknown passthrough arguments", {
  expect_warning(
    layout_force(mk_graph(), seed = 1, area = 3),
    "weights"
  )
})

test_that("layout_force tolerates self-loops and single nodes", {
  solo <- as_graph(data.frame(source = "solo", target = "solo"))
  g <- layout_force(solo, seed = 1)
  expect_length(g$nodes$id, 1)
  expect_true(is.finite(g$nodes$x))

  expect_error(
    layout_force(as_graph(data.frame(
      source = character(), target = character()
    )), seed = 1),
    "at least one node"
  )
})

# ---- self-contained tree engine (no igraph) --------------------------------

mk_tree <- function() {
  as_graph(data.frame(
    id = c("r", "A", "B", "a1", "a2"),
    parent = c(NA, "r", "r", "A", "A")
  ))
}

test_that("layout_tree orders leaves left-to-right with internal means", {
  g <- layout_tree(mk_tree(), "down")
  pos <- stats::setNames(g$nodes$x, g$nodes$id)
  # leaves a1 < a2 strictly ordered; parent A sits at their mean
  expect_lt(pos[["a1"]], pos[["a2"]])
  expect_equal(pos[["A"]], mean(c(pos[["a1"]], pos[["a2"]])))
  # root sits above its children (down: y decreases from the root)
  ypos <- stats::setNames(g$nodes$y, g$nodes$id)
  expect_lt(max(ypos[c("A", "B")]), ypos[["r"]])
})

test_that("layout_tree supports all four orientations and forests", {
  h <- data.frame(
    id = c("r1", "r2", "x"),
    parent = c(NA, NA, "r1")
  )
  for (dir in c("down", "up", "left", "right")) {
    g <- layout_tree(as_graph(h), dir)
    expect_true(all(is.finite(g$nodes$x)), info = dir)
    expect_false(anyNA(g$nodes$y), info = dir)
  }
  # forest: two roots, x under r1
  gr <- layout_tree(as_graph(h), "right")
  xpos <- stats::setNames(gr$nodes$x, gr$nodes$id)
  expect_gt(xpos[["x"]], xpos[["r1"]]) # depth grows to the right
})

test_that("layout_tree rejects cycles and edgeless input", {
  cyclic <- data.frame(source = c("a", "b"), target = c("b", "a"))
  expect_error(layout_tree(as_graph(cyclic)), "root|cycle|unreachable")

  lonely <- as_graph(data.frame(id = "only", parent = NA_character_))
  expect_error(layout_tree(lonely), "at least one edge")
})
