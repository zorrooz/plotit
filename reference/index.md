# Package index

## Plot Construction

- [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) :
  Initialize a plotit object
- [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) :
  Create aesthetic mapping

## Geometric Layers

Add visual marks to your plot.

- [`mark_area()`](https://zorrooz.github.io/plotit/reference/mark_area.md)
  : Area layer
- [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md)
  : Bar layer
- [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md)
  : Boxplot layer
- [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md)
  : Density layer
- [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md)
  : Histogram layer
- [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md)
  : Line layer
- [`mark_map()`](https://zorrooz.github.io/plotit/reference/mark_map.md)
  : Map layer
- [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md)
  : Point layer
- [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)
  : Text layer
- [`mark_violin()`](https://zorrooz.github.io/plotit/reference/mark_violin.md)
  : Violin layer

## Scales

Control how data maps to visual properties.

- [`scale_alpha()`](https://zorrooz.github.io/plotit/reference/scale_alpha.md)
  : Alpha (transparency) scale
- [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
  : Color scale
- [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
  : Fill scale
- [`scale_linetype()`](https://zorrooz.github.io/plotit/reference/scale_linetype.md)
  : Linetype scale
- [`scale_shape()`](https://zorrooz.github.io/plotit/reference/scale_shape.md)
  : Shape scale
- [`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md)
  : Size scale
- [`scale_x()`](https://zorrooz.github.io/plotit/reference/scale_x.md) :
  X-axis position scale
- [`scale_y()`](https://zorrooz.github.io/plotit/reference/scale_y.md) :
  Y-axis position scale

## Labels

Set titles, axis labels, and legend text.

- [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md)
  : Generic for setting axis titles
- [`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md)
  : Generic for setting plot caption
- [`label_legend()`](https://zorrooz.github.io/plotit/reference/label_legend.md)
  : Generic for setting legend title(s)
- [`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md)
  : Generic for setting plot subtitle
- [`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
  : Generic for setting plot title

## Coordinate Systems

Transform the coordinate space.

- [`project_cartesian()`](https://zorrooz.github.io/plotit/reference/project_cartesian.md)
  : Cartesian coordinate system
- [`project_map()`](https://zorrooz.github.io/plotit/reference/project_map.md)
  : Map coordinate system
- [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md)
  : Parallel coordinates
- [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md)
  : Polar / radial coordinate system

## Facets

Split data into subplots.

- [`split_grid()`](https://zorrooz.github.io/plotit/reference/split_grid.md)
  : Generic for grid facets
- [`split_wrap()`](https://zorrooz.github.io/plotit/reference/split_wrap.md)
  : Generic for wrapping facets

## Composition

Combine multiple plots into layouts.

- [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md)
  : Assemble multiple plots into a grid layout
- [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md)
  : Overlay an inset plot on a base plot
- [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md)
  : Scatter plot with marginal distributions

## Theme & Export

Style and save your plots.

- [`style()`](https://zorrooz.github.io/plotit/reference/style.md) :
  Modify plot theme (aligns with ggplot2::theme)
- [`style_default()`](https://zorrooz.github.io/plotit/reference/style_default.md)
  : Apply the default plotit theme (convenience wrapper for style())
- [`export()`](https://zorrooz.github.io/plotit/reference/export.md) :
  Export a plotit object to a file
