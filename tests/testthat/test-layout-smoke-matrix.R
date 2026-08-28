# ============================================================
# C1 relational smoke matrix (design/07; prompt C1) -- BDD tests
# Every layout x every consumer combination must draw something:
# "layout computed but nothing rendered" = 0 broken chains.
# ============================================================
library(plotit)

smoke_rows <- function(p, min_rows = 1) {
  b <- ggplot2::ggplot_build(p@gg)
  total <- sum(vapply(b$data, nrow, numeric(1)))
  expect_gte(total, min_rows)
  total
}

tree_edges <- data.frame(
  id = c("root", "A", "B", "a1", "a2", "b1"),
  parent = c(NA, "root", "root", "A", "A", "B")
)
flow_edges <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value = c(10, 5, 8, 3, 6)
)
hier <- data.frame(
  id = c("root", "L", "R", "l1", "l2", "r1"),
  parent = c(NA, "root", "root", "L", "L", "R"),
  value = c(NA, NA, NA, 30, 20, 50)
)
hcl <- stats::hclust(stats::dist(USArrests[sample(seq_len(15), 8), ]))

test_that("[C1] layout_force draws through mark_network and the explicit pipeline", {
  # sugar form
  p1 <- plotit(tree_edges, encode()) |>
    mark_network(edges = flow_edges, seed = 1)
  smoke_rows(p1)
  # explicit pipeline
  p2 <- as_graph(flow_edges) |> plotit() |>
    layout_force(seed = 1) |>
    mark_point(data = ~nodes) |>
    mark_rule(data = ~edges, color = "grey70")
  smoke_rows(p2, min_rows = 3)
})

test_that("[C1] layout_circle draws through mark_network and the explicit pipeline", {
  p1 <- as_graph(flow_edges) |> plotit() |>
    mark_network(edges = flow_edges, layout = "circle")
  smoke_rows(p1)
  p2 <- as_graph(flow_edges) |> plotit() |>
    layout_circle() |>
    mark_point(data = ~nodes) |>
    mark_rule(data = ~edges, color = "grey70")
  smoke_rows(p2, min_rows = 3)
})

test_that("[C1] layout_tree draws through the explicit pipeline (both edge shapes)", {
  for (ed in c("straight", "elbow")) {
    p <- as_graph(tree_edges) |> plotit() |>
      layout_tree(direction = "down", edge = ed) |>
      mark_rule(data = ~edges) |>
      mark_point(data = ~nodes)
    smoke_rows(p, min_rows = 3)
  }
})

test_that("[C1] layout_dendrogram draws through the explicit pipeline", {
  p <- as_graph(hcl) |> plotit() |>
    layout_dendrogram(direction = "down") |>
    mark_rule(data = ~edges) |>
    mark_point(data = ~nodes)
  smoke_rows(p, min_rows = 3)
})

test_that("[C1] layout_chord draws through mark_chord and the explicit pipeline", {
  p1 <- plotit(flow_edges, encode(
    source = source, target = target, value = value, fill = source
  )) |>
    mark_chord()
  smoke_rows(p1)
  p2 <- as_graph(flow_edges) |> plotit() |>
    layout_chord() |>
    mark_polygon(data = ~ribbons, alpha = 0.5) |>
    mark_polygon(data = ~arcs)
  smoke_rows(p2)
})

test_that("[C1] layout_sankey draws through mark_sankey and the explicit pipeline", {
  p1 <- plotit(flow_edges, encode(
    source = source, target = target, value = value, fill = source
  )) |>
    mark_sankey()
  smoke_rows(p1)
  p2 <- as_graph(flow_edges) |> plotit() |>
    layout_sankey() |>
    mark_polygon(data = ~ribbons, alpha = 0.5) |>
    mark_rect(data = ~nodes)
  smoke_rows(p2)
})

test_that("[C1] layout_treemap draws through mark_treemap and the explicit pipeline", {
  p1 <- plotit(hier, encode(fill = id)) |> mark_treemap()
  smoke_rows(p1)
  p2 <- as_graph(hier) |> plotit() |>
    layout_treemap() |>
    mark_rect(data = ~leaves)
  smoke_rows(p2)
})
