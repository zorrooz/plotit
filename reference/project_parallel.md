# Parallel coordinates

Reshapes the plot data so that the selected columns become parallel
vertical axes. Each observation is drawn as a polyline connecting its
values across all axes. Values are optionally normalised per column to
share a common 0-1 scale.

## Usage

``` r
project_parallel(
  plot,
  columns,
  group = NULL,
  scale = c("std", "global", "none"),
  alpha = 0.5,
  size = 1,
  clip = "on",
  ...
)
```

## Arguments

- plot:

  A plotit object.

- columns:

  Character vector of column names to use as parallel axes. Order
  matters: the first column is the leftmost axis.

- group:

  Column name for colouring lines. `NULL` = no grouping.

- scale:

  `"std"` (default): min-max normalise each column to 0-1. `"global"`:
  min-max normalise across all columns to 0-1. `"none"`: no
  normalisation, each column keeps its own range.

- alpha, size:

  Passed to `geom_line()` / `geom_point()`.

- clip:

  Currently unused (parallel coordinates do not apply a coordinate
  system). Accepted for signature consistency.

- ...:

  Passed to `geom_line()`.

## Value

Modified plotit object.

## Details

Adds `geom_line()` and `geom_point()` layers. Call *after* any `mark_*`
layers that should sit beneath the parallel-coordinate lines.

## Examples

``` r
plotit(iris, encode()) |>
  project_parallel(columns = c("Sepal.Width", "Sepal.Length", "Petal.Width", "Petal.Length"))
```
