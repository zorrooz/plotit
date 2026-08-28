#' S7 class definitions for plotit
#'

#' @name plotit-class
#' @keywords internal
NULL

plotit_labels <- S7::new_class(
  "plotit_labels",
  properties = list(
    title = S7::class_character | S7::class_logical | NULL,
    subtitle = S7::class_character | S7::class_logical | NULL,
    caption = S7::class_character | S7::class_logical | NULL,
    x = S7::class_character | S7::class_logical | NULL,
    y = S7::class_character | S7::class_logical | NULL,
    legend = S7::class_list | NULL,
    dirty = S7::class_list
  ),
  constructor = function(
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    x = NULL,
    y = NULL,
    legend = NULL
  ) {
    S7::new_object(
      S7::S7_object(),
      title = title,
      subtitle = subtitle,
      caption = caption,
      x = x,
      y = y,
      legend = legend,
      dirty = list()
    )
  }
)

plotit_metadata <- S7::new_class(
  "plotit_metadata",
  properties = list(
    autofit = S7::class_logical,
    width = S7::class_numeric | NULL,
    height = S7::class_numeric | NULL,
    unit = S7::class_character | NULL,
    dodge = S7::class_numeric | NULL,
    default_color = S7::class_character | NULL,
    labels = plotit_labels
  ),
  constructor = function(
    autofit = FALSE,
    width = NULL,
    height = NULL,
    unit = "in",
    dodge = NULL,
    default_color = NULL,
    labels = plotit_labels()
  ) {
    if (!is.null(unit)) {
      valid_units <- c("in", "cm", "mm")
      if (!(unit %in% valid_units)) {
        ._abort_arg_enum("unit", valid_units, got = unit)
      }
    }
    S7::new_object(
      S7::S7_object(),
      autofit = autofit,
      width = width,
      height = height,
      unit = unit,
      dodge = dodge,
      default_color = default_color,
      labels = labels
    )
  }
)

# ---- plotit_graph: relational multi-table container ----
# An S3 class registered with S7 so that it can type the plotit@graph
# property, validate table contents on assignment, and serve as a method
# dispatch target for layout_*.  A graph is a named list of data.frames
# (canonical tables: nodes / edges; composite layouts may add more, e.g.
# ribbons).  Instances are plain lists -- value semantics throughout.
plotit_graph_cls <- S7::new_S3_class(
  c("plotit_graph", "list"),
  constructor = function(.data = list()) {
    class(.data) <- c("plotit_graph", "list")
    .data
  },
  validator = function(x) {
    nms <- names(x)
    if (is.null(nms) || any(!nzchar(nms))) {
      return("all tables must be named")
    }
    if (anyDuplicated(nms) > 0) {
      return("table names must be unique")
    }
    bad <- !vapply(x, is.data.frame, logical(1))
    if (any(bad)) {
      return(paste0("table(s) not a data frame: ", paste(nms[bad], collapse = ", ")))
    }
    NULL
  }
)

# Convenience constructor used internally (as_graph, layout engines).
._new_graph <- function(tables, directed = FALSE) {
  out <- tables
  class(out) <- c("plotit_graph", "list")
  attr(out, "directed") <- directed
  out
}

is_graph <- function(x) {
  inherits(x, "plotit_graph")
}

plotit_class <- S7::new_class(
  "plotit",
  properties = list(
    gg = S7::class_any,
    meta = plotit_metadata,
    graph = S7::new_property(plotit_graph_cls | NULL, default = NULL)
  ),
  validator = function(self) {
    if (!inherits(self@gg, "ggplot")) {
      "gg must be a ggplot object"
    } else {
      NULL
    }
  }
)

# ---- plotit_composite: inherits from plotit ----
plotit_composite <- S7::new_class(
  "plotit_composite",
  parent = plotit_class,
  properties = list(
    plots       = S7::class_list,
    layout      = S7::class_list,
    annotations = S7::class_list
  ),
  constructor = function(gg, plots, layout, annotations) {
    out <- S7::new_object(
      plotit_class(gg = gg, meta = plotit_metadata(autofit = TRUE)),
      plots = plots, layout = layout, annotations = annotations
    )
    class(out) <- c("plotit_composite", class(out))
    out
  },
  validator = function(self) {
    if (!inherits(self@gg, "ggplot")) {
      "gg must be a ggplot object"
    } else if (length(self@plots) == 0) {
      "plots must contain at least one plot"
    } else {
      NULL
    }
  }
)
