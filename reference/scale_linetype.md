# Linetype scale

Maps data values to line types. Supports discrete and reverse scales;
continuous variables are not supported.

## Usage

``` r
scale_linetype(
  plot,
  name = ggplot2::waiver(),
  trans = "discrete",
  limits = NULL,
  range = NULL,
  breaks = NULL,
  labels = NULL,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- name:

  Scale title (legend name).

- trans:

  Scale transformation. Default `"discrete"`. Allowed: `"discrete"`,
  `"reverse"`. `"identity"` and `"binned"` are rejected with targeted
  error messages.

- limits:

  Data domain.

- range:

  Linetype names or codes (`c("solid","dashed")`). `NULL` = ggplot2
  defaults.

- breaks:

  Legend key positions.

- labels:

  Legend key labels.

- ...:

  Passed to the underlying ggplot2 scale function.

## Value

A modified plotit object.

## Examples

``` r
plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
  mark_line() |>
  scale_linetype()
#> <plotit::plotit>
#>  @ gg  : <ggplot2::ggplot>
#>  .. @ data       : spc_tbl_ [574 × 6] (S3: spec_tbl_df/tbl_df/tbl/data.frame)
#>  $ date    : Date[1:574], format: "1967-07-01" "1967-08-01" ...
#>  $ pce     : num [1:574] 507 510 516 512 517 ...
#>  $ pop     : num [1:574] 198712 198911 199113 199311 199498 ...
#>  $ psavert : num [1:574] 12.6 12.6 11.9 12.9 12.8 11.8 11.7 12.3 11.7 12.3 ...
#>  $ uempmed : num [1:574] 4.5 4.7 4.6 4.9 4.7 4.8 5.1 4.5 4.1 4.6 ...
#>  $ unemploy: num [1:574] 2944 2945 2958 3143 3066 ...
#>  .. @ layers     :List of 1
#>  .. .. $ geom_fun:Classes 'LayerInstance', 'Layer', 'ggproto', 'gg' <ggproto object: Class LayerInstance, Layer, gg>
#>     aes_params: list
#>     compute_aesthetics: function
#>     compute_geom_1: function
#>     compute_geom_2: function
#>     compute_position: function
#>     compute_statistic: function
#>     computed_geom_params: NULL
#>     computed_mapping: NULL
#>     computed_stat_params: NULL
#>     constructor: call
#>     data: waiver
#>     draw_geom: function
#>     finish_statistics: function
#>     geom: <ggproto object: Class GeomLine, GeomPath, Geom, gg>
#>         aesthetics: function
#>         default_aes: ggplot2::mapping, uneval, gg, S7_object
#>         draw_group: function
#>         draw_key: function
#>         draw_layer: function
#>         draw_panel: function
#>         extra_params: na.rm orientation
#>         handle_na: function
#>         non_missing_aes: linewidth colour linetype
#>         optional_aes: 
#>         parameters: function
#>         rename_size: TRUE
#>         required_aes: x y
#>         setup_data: function
#>         setup_params: function
#>         use_defaults: function
#>         super:  <ggproto object: Class GeomPath, Geom, gg>
#>     geom_params: list
#>     inherit.aes: TRUE
#>     layer_data: function
#>     layout: NULL
#>     map_statistic: function
#>     mapping: NULL
#>     name: NULL
#>     position: <ggproto object: Class PositionIdentity, Position, gg>
#>         aesthetics: function
#>         compute_layer: function
#>         compute_panel: function
#>         default_aes: ggplot2::mapping, uneval, gg, S7_object
#>         required_aes: 
#>         setup_data: function
#>         setup_params: function
#>         use_defaults: function
#>         super:  <ggproto object: Class Position, gg>
#>     print: function
#>     setup_layer: function
#>     show.legend: NA
#>     stat: <ggproto object: Class StatIdentity, Stat, gg>
#>         aesthetics: function
#>         compute_group: function
#>         compute_layer: function
#>         compute_panel: function
#>         default_aes: ggplot2::mapping, uneval, gg, S7_object
#>         dropped_aes: 
#>         extra_params: na.rm
#>         finish_layer: function
#>         non_missing_aes: 
#>         optional_aes: 
#>         parameters: function
#>         required_aes: 
#>         retransform: TRUE
#>         setup_data: function
#>         setup_params: function
#>         super:  <ggproto object: Class Stat, gg>
#>     stat_params: list
#>     super:  <ggproto object: Class Layer, gg> 
#>  .. @ scales     :Classes 'ScalesList', 'ggproto', 'gg' <ggproto object: Class ScalesList, gg>
#>     add: function
#>     add_defaults: function
#>     add_missing: function
#>     backtransform_df: function
#>     clone: function
#>     find: function
#>     get_scales: function
#>     has_scale: function
#>     input: function
#>     map_df: function
#>     n: function
#>     non_position_scales: function
#>     scales: list
#>     set_palettes: function
#>     train_df: function
#>     transform_df: function
#>     super:  <ggproto object: Class ScalesList, gg> 
#>  .. @ guides     :Classes 'Guides', 'ggproto', 'gg' <ggproto object: Class Guides, gg>
#>     add: function
#>     assemble: function
#>     build: function
#>     draw: function
#>     get_custom: function
#>     get_guide: function
#>     get_params: function
#>     get_position: function
#>     guides: list
#>     merge: function
#>     missing: <ggproto object: Class GuideNone, Guide, gg>
#>         add_title: function
#>         arrange_layout: function
#>         assemble_drawing: function
#>         available_aes: any
#>         build_decor: function
#>         build_labels: function
#>         build_ticks: function
#>         build_title: function
#>         draw: function
#>         draw_early_exit: function
#>         elements: list
#>         extract_decor: function
#>         extract_key: function
#>         extract_params: function
#>         get_layer_key: function
#>         hashables: list
#>         measure_grobs: function
#>         merge: function
#>         override_elements: function
#>         params: list
#>         process_layers: function
#>         setup_elements: function
#>         setup_params: function
#>         train: function
#>         transform: function
#>         super:  <ggproto object: Class GuideNone, Guide, gg>
#>     package_box: function
#>     print: function
#>     process_layers: function
#>     setup: function
#>     subset_guides: function
#>     train: function
#>     update_params: function
#>     super:  <ggproto object: Class Guides, gg> 
#>  .. @ mapping    : <ggplot2::mapping> List of 4
#>  .. .. $ x     : language ~date
#>  .. ..  ..- attr(*, ".Environment")=<environment: 0x55ce939c54d0> 
#>  .. .. $ y     : language ~unemploy
#>  .. ..  ..- attr(*, ".Environment")=<environment: 0x55ce939c54d0> 
#>  .. .. $ colour: 'AsIs' chr "#4E79A7"
#>  .. .. $ fill  : 'AsIs' chr "#4E79A7"
#>  .. @ theme      : <theme> List of 144
#>  .. .. $ line                            : <ggplot2::element_line>
#>  .. ..  ..@ colour       : chr "black"
#>  .. ..  ..@ linewidth    : num 0.5
#>  .. ..  ..@ linetype     : num 1
#>  .. ..  ..@ lineend      : chr "butt"
#>  .. ..  ..@ linejoin     : chr "round"
#>  .. ..  ..@ arrow        : logi FALSE
#>  .. ..  ..@ arrow.fill   : chr "black"
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ rect                            : <ggplot2::element_rect>
#>  .. ..  ..@ fill         : chr "white"
#>  .. ..  ..@ colour       : chr "black"
#>  .. ..  ..@ linewidth    : num 0.5
#>  .. ..  ..@ linetype     : num 1
#>  .. ..  ..@ linejoin     : chr "round"
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ text                            : <ggplot2::element_text>
#>  .. ..  ..@ family       : chr ""
#>  .. ..  ..@ face         : chr "plain"
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : chr "black"
#>  .. ..  ..@ size         : num 11
#>  .. ..  ..@ hjust        : num 0.5
#>  .. ..  ..@ vjust        : num 0.5
#>  .. ..  ..@ angle        : num 0
#>  .. ..  ..@ lineheight   : num 0.9
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 0 0 0
#>  .. ..  ..@ debug        : logi FALSE
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ title                           : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : NULL
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ point                           : <ggplot2::element_point>
#>  .. ..  ..@ colour       : chr "black"
#>  .. ..  ..@ shape        : num 19
#>  .. ..  ..@ size         : num 1.5
#>  .. ..  ..@ fill         : chr "white"
#>  .. ..  ..@ stroke       : num 0.5
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ polygon                         : <ggplot2::element_polygon>
#>  .. ..  ..@ fill         : chr "white"
#>  .. ..  ..@ colour       : chr "black"
#>  .. ..  ..@ linewidth    : num 0.5
#>  .. ..  ..@ linetype     : num 1
#>  .. ..  ..@ linejoin     : chr "round"
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ geom                            : <ggplot2::element_geom>
#>  .. ..  ..@ ink        : chr "black"
#>  .. ..  ..@ paper      : chr "white"
#>  .. ..  ..@ accent     : chr "#3366FF"
#>  .. ..  ..@ linewidth  : num 0.5
#>  .. ..  ..@ borderwidth: num 0.5
#>  .. ..  ..@ linetype   : int 1
#>  .. ..  ..@ bordertype : int 1
#>  .. ..  ..@ family     : chr ""
#>  .. ..  ..@ fontsize   : num 3.87
#>  .. ..  ..@ pointsize  : num 1.5
#>  .. ..  ..@ pointshape : num 19
#>  .. ..  ..@ colour     : NULL
#>  .. ..  ..@ fill       : NULL
#>  .. .. $ spacing                         : 'simpleUnit' num 5.5points
#>  .. ..  ..- attr(*, "unit")= int 8
#>  .. .. $ margins                         : <ggplot2::margin> num [1:4] 5.5 5.5 5.5 5.5
#>  .. .. $ aspect.ratio                    : NULL
#>  .. .. $ axis.title                      : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : 'rel' num 0.9
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : NULL
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ axis.title.x                    : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : num 1
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 2.75 0 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.title.x.top                : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : num 0
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 0 2.75 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.title.x.bottom             : NULL
#>  .. .. $ axis.title.y                    : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : num 1
#>  .. ..  ..@ angle        : num 90
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 2.75 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.title.y.left               : NULL
#>  .. .. $ axis.title.y.right              : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : num 1
#>  .. ..  ..@ angle        : num -90
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 0 0 2.75
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text                       : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : chr "#4D4D4DFF"
#>  .. ..  ..@ size         : 'rel' num 0.8
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : NULL
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ axis.text.x                     : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : num 1
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 2.2 0 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.x.top                 : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 0 4.95 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.x.bottom              : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 4.95 0 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.y                     : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : num 1
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 2.2 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.y.left                : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 4.95 0 0
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.y.right               : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 0 0 4.95
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.text.theta                 : NULL
#>  .. .. $ axis.text.r                     : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : num 0.5
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : <ggplot2::margin> num [1:4] 0 2.2 0 2.2
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ axis.ticks                      : <ggplot2::element_line>
#>  .. ..  ..@ colour       : chr "grey50"
#>  .. ..  ..@ linewidth    : num 0.3
#>  .. ..  ..@ linetype     : NULL
#>  .. ..  ..@ lineend      : NULL
#>  .. ..  ..@ linejoin     : NULL
#>  .. ..  ..@ arrow        : logi FALSE
#>  .. ..  ..@ arrow.fill   : chr "grey50"
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ axis.ticks.x                    : NULL
#>  .. .. $ axis.ticks.x.top                : NULL
#>  .. .. $ axis.ticks.x.bottom             : NULL
#>  .. .. $ axis.ticks.y                    : NULL
#>  .. .. $ axis.ticks.y.left               : NULL
#>  .. .. $ axis.ticks.y.right              : NULL
#>  .. .. $ axis.ticks.theta                : NULL
#>  .. .. $ axis.ticks.r                    : NULL
#>  .. .. $ axis.minor.ticks.x.top          : NULL
#>  .. .. $ axis.minor.ticks.x.bottom       : NULL
#>  .. .. $ axis.minor.ticks.y.left         : NULL
#>  .. .. $ axis.minor.ticks.y.right        : NULL
#>  .. .. $ axis.minor.ticks.theta          : NULL
#>  .. .. $ axis.minor.ticks.r              : NULL
#>  .. .. $ axis.ticks.length               : 'rel' num 0.5
#>  .. .. $ axis.ticks.length.x             : NULL
#>  .. .. $ axis.ticks.length.x.top         : NULL
#>  .. .. $ axis.ticks.length.x.bottom      : NULL
#>  .. .. $ axis.ticks.length.y             : NULL
#>  .. .. $ axis.ticks.length.y.left        : NULL
#>  .. .. $ axis.ticks.length.y.right       : NULL
#>  .. .. $ axis.ticks.length.theta         : NULL
#>  .. .. $ axis.ticks.length.r             : NULL
#>  .. .. $ axis.minor.ticks.length         : 'rel' num 0.75
#>  .. .. $ axis.minor.ticks.length.x       : NULL
#>  .. .. $ axis.minor.ticks.length.x.top   : NULL
#>  .. .. $ axis.minor.ticks.length.x.bottom: NULL
#>  .. .. $ axis.minor.ticks.length.y       : NULL
#>  .. .. $ axis.minor.ticks.length.y.left  : NULL
#>  .. .. $ axis.minor.ticks.length.y.right : NULL
#>  .. .. $ axis.minor.ticks.length.theta   : NULL
#>  .. .. $ axis.minor.ticks.length.r       : NULL
#>  .. .. $ axis.line                       : <ggplot2::element_line>
#>  .. ..  ..@ colour       : chr "grey50"
#>  .. ..  ..@ linewidth    : num 0.3
#>  .. ..  ..@ linetype     : NULL
#>  .. ..  ..@ lineend      : NULL
#>  .. ..  ..@ linejoin     : NULL
#>  .. ..  ..@ arrow        : logi FALSE
#>  .. ..  ..@ arrow.fill   : chr "grey50"
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ axis.line.x                     : NULL
#>  .. .. $ axis.line.x.top                 : NULL
#>  .. .. $ axis.line.x.bottom              : NULL
#>  .. .. $ axis.line.y                     : NULL
#>  .. .. $ axis.line.y.left                : NULL
#>  .. .. $ axis.line.y.right               : NULL
#>  .. .. $ axis.line.theta                 : NULL
#>  .. .. $ axis.line.r                     : NULL
#>  .. .. $ legend.background               : <ggplot2::element_rect>
#>  .. ..  ..@ fill         : logi NA
#>  .. ..  ..@ colour       : logi NA
#>  .. ..  ..@ linewidth    : NULL
#>  .. ..  ..@ linetype     : NULL
#>  .. ..  ..@ linejoin     : NULL
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ legend.margin                   : NULL
#>  .. .. $ legend.spacing                  : 'rel' num 2
#>  .. .. $ legend.spacing.x                : NULL
#>  .. .. $ legend.spacing.y                : NULL
#>  .. .. $ legend.key                      : <ggplot2::element_rect>
#>  .. ..  ..@ fill         : logi NA
#>  .. ..  ..@ colour       : logi NA
#>  .. ..  ..@ linewidth    : NULL
#>  .. ..  ..@ linetype     : NULL
#>  .. ..  ..@ linejoin     : NULL
#>  .. ..  ..@ inherit.blank: logi FALSE
#>  .. .. $ legend.key.size                 : 'simpleUnit' num 1.2lines
#>  .. ..  ..- attr(*, "unit")= int 3
#>  .. .. $ legend.key.height               : NULL
#>  .. .. $ legend.key.width                : NULL
#>  .. .. $ legend.key.spacing              : NULL
#>  .. .. $ legend.key.spacing.x            : NULL
#>  .. .. $ legend.key.spacing.y            : NULL
#>  .. .. $ legend.key.justification        : NULL
#>  .. .. $ legend.frame                    : NULL
#>  .. .. $ legend.ticks                    : NULL
#>  .. .. $ legend.ticks.length             : 'rel' num 0.2
#>  .. .. $ legend.axis.line                : NULL
#>  .. .. $ legend.text                     : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : 'rel' num 0.8
#>  .. ..  ..@ hjust        : NULL
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : NULL
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ legend.text.position            : NULL
#>  .. .. $ legend.title                    : <ggplot2::element_text>
#>  .. ..  ..@ family       : NULL
#>  .. ..  ..@ face         : NULL
#>  .. ..  ..@ italic       : chr NA
#>  .. ..  ..@ fontweight   : num NA
#>  .. ..  ..@ fontwidth    : num NA
#>  .. ..  ..@ colour       : NULL
#>  .. ..  ..@ size         : NULL
#>  .. ..  ..@ hjust        : num 0
#>  .. ..  ..@ vjust        : NULL
#>  .. ..  ..@ angle        : NULL
#>  .. ..  ..@ lineheight   : NULL
#>  .. ..  ..@ margin       : NULL
#>  .. ..  ..@ debug        : NULL
#>  .. ..  ..@ inherit.blank: logi TRUE
#>  .. .. $ legend.title.position           : NULL
#>  .. .. $ legend.position                 : chr "right"
#>  .. .. $ legend.position.inside          : NULL
#>  .. .. $ legend.direction                : NULL
#>  .. .. $ legend.byrow                    : NULL
#>  .. .. $ legend.justification            : chr "center"
#>  .. .. $ legend.justification.top        : NULL
#>  .. .. $ legend.justification.bottom     : NULL
#>  .. .. $ legend.justification.left       : NULL
#>  .. .. $ legend.justification.right      : NULL
#>  .. .. $ legend.justification.inside     : NULL
#>  .. ..  [list output truncated]
#>  .. .. @ complete: logi TRUE
#>  .. .. @ validate: logi TRUE
#>  .. @ coordinates:Classes 'CoordCartesian', 'Coord', 'ggproto', 'gg' <ggproto object: Class CoordCartesian, Coord, gg>
#>     aspect: function
#>     backtransform_range: function
#>     clip: on
#>     default: TRUE
#>     distance: function
#>     draw_panel: function
#>     expand: TRUE
#>     is_free: function
#>     is_linear: function
#>     labels: function
#>     limits: list
#>     modify_scales: function
#>     range: function
#>     ratio: NULL
#>     render_axis_h: function
#>     render_axis_v: function
#>     render_bg: function
#>     render_fg: function
#>     reverse: none
#>     setup_data: function
#>     setup_layout: function
#>     setup_panel_guides: function
#>     setup_panel_params: function
#>     setup_params: function
#>     train_panel_guides: function
#>     transform: function
#>     super:  <ggproto object: Class CoordCartesian, Coord, gg> 
#>  .. @ facet      :Classes 'FacetNull', 'Facet', 'ggproto', 'gg' <ggproto object: Class FacetNull, Facet, gg>
#>     attach_axes: function
#>     attach_strips: function
#>     compute_layout: function
#>     draw_back: function
#>     draw_front: function
#>     draw_labels: function
#>     draw_panel_content: function
#>     draw_panels: function
#>     finish_data: function
#>     format_strip_labels: function
#>     init_gtable: function
#>     init_scales: function
#>     map_data: function
#>     params: list
#>     set_panel_size: function
#>     setup_data: function
#>     setup_panel_params: function
#>     setup_params: function
#>     shrink: TRUE
#>     train_scales: function
#>     vars: function
#>     super:  <ggproto object: Class FacetNull, Facet, gg> 
#>  .. @ layout     :Classes 'Layout', 'ggproto', 'gg' <ggproto object: Class Layout, gg>
#>     coord: NULL
#>     coord_params: list
#>     facet: NULL
#>     facet_params: list
#>     finish_data: function
#>     get_scales: function
#>     layout: NULL
#>     map_position: function
#>     panel_params: NULL
#>     panel_scales_x: NULL
#>     panel_scales_y: NULL
#>     render: function
#>     render_labels: function
#>     reset_scales: function
#>     resolve_label: function
#>     setup: function
#>     setup_panel_guides: function
#>     setup_panel_params: function
#>     train_position: function
#>     super:  <ggproto object: Class Layout, gg> 
#>  .. @ labels     : <ggplot2::labels>  Named list()
#>  .. @ meta       : list()
#>  .. @ plot_env   :<environment: 0x55ce93ce6c18> 
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: chr "#4E79A7"
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```
