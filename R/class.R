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
        cli::cli_abort("{.arg unit} must be one of {.val {valid_units}}.")
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

plotit_class <- S7::new_class(
  "plotit",
  properties = list(
    gg = S7::class_any,
    meta = plotit_metadata
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
    S7::new_object(
      plotit_class(gg = gg, meta = plotit_metadata(autofit = TRUE)),
      plots = plots, layout = layout, annotations = annotations
    )
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
