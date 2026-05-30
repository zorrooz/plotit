#' S7 class definitions for plotit
#'
#' @import S7 ggplot2 cli
#' @keywords internal
NULL

plotit_labels <- new_class(
  "plotit_labels",
  properties = list(
    title = class_character | NULL,
    subtitle = class_character | NULL,
    caption = class_character | NULL,
    x = class_character | NULL,
    y = class_character | NULL,
    legend = class_list | NULL
  ),
  constructor = function(
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    x = NULL,
    y = NULL,
    legend = list()
  ) {
    new_object(
      S7_object(),
      title = title,
      subtitle = subtitle,
      caption = caption,
      x = x,
      y = y,
      legend = legend
    )
  }
)

plotit_metadata <- new_class(
  "plotit_metadata",
  properties = list(
    autofit = class_logical,
    width = class_numeric | NULL,
    height = class_numeric | NULL,
    unit = class_character | NULL,
    dodge = class_numeric | NULL,
    default_color = class_character | NULL,
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
    new_object(
      S7_object(),
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

plotit <- new_class(
  "plotit",
  properties = list(
    gg = class_any,
    meta = plotit_metadata
  ),
  validator = function(self) {
    if (!inherits(self@gg, "ggplot")) {
      "`gg` must be a ggplot object"
    } else {
      NULL
    }
  }
)
