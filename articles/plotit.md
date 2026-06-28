# Getting Started with plotit

## Overview

**plotit** is a declarative plotting package built on ggplot2. It wraps
ggplot2 with a **verb-prefix API** — every function starts with a verb
that tells you what it does: `mark_*()` adds marks, `scale_*()` controls
scales, `label_*()` sets labels.

All functions return a plotit object, so you can chain them with `|>`:

``` r

library(plotit)

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_color(range = "viridis") |>
  label_title("Iris Sepal Dimensions") |>
  label_axis(text = "Sepal Width", aes = "x") |>
  label_axis(text = "Sepal Length", aes = "y")
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : chr "Iris Sepal Dimensions"
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : chr "Sepal Width"
#>  .. .. @ y       : chr "Sepal Length"
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   :List of 3
#>  .. .. .. $ title: logi TRUE
#>  .. .. .. $ x    : logi TRUE
#>  .. .. .. $ y    : logi TRUE
```

## Pipeline Grammar

Every plotit pipeline follows the same six-step grammar:

    data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> style() |> export()

| Step | Function | Job |
|:---|:---|:---|
| 1\. Init | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) | Create plot with data & aesthetics |
| 2\. Mark | `mark_*()` | Add geometric layers |
| 3\. Scale | `scale_*()` | Control data-to-visual mapping |
| 4\. Label | `label_*()` | Set titles, axis labels, legends |
| 5\. Style | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | Apply a ggplot2 theme |
| 6\. Export | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | Render to file |

## Function Families

### `mark_*()` — Geometric Layers

Six mark functions add visual elements to your plot. All share a unified
signature: `mapping`, `data`, `position`, `rasterize`, and `...`
forwarded to the underlying geom.

``` r

# Scatter plot
mtcars |>
  plotit(encode(x = wt, y = mpg, colour = factor(cyl))) |>
  mark_point(size = 3, alpha = 0.8)
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

``` r

# Bar chart — auto-detects geom_col vs geom_bar
iris |>
  plotit(encode(x = Species, y = Sepal.Length)) |>
  mark_bar()
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0.8
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

``` r

# Boxplot
iris |>
  plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
  mark_boxplot()
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0.8
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

``` r

# Histogram
iris |>
  plotit(encode(x = Sepal.Length, fill = Species)) |>
  mark_histogram(bins = 20, alpha = 0.5)
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

### `scale_*()` — Data-to-Visual Mapping

Eight scale functions, all with identical parameters: `name`, `trans`,
`limits`, `range`, `breaks`, `labels`, and `...`.

``` r

mtcars |>
  plotit(encode(x = wt, y = mpg, colour = hp, size = hp)) |>
  mark_point(alpha = 0.7) |>
  scale_color(range = "viridis") |>
  scale_x(trans = "log10") |>
  scale_size(range = c(0.5, 8))
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

The `range` parameter accepts colour scheme names (`"viridis"`,
`"brewer"`, `"hue"`) or custom vectors:

``` r

mtcars |>
  plotit(encode(x = wt, y = mpg, colour = factor(cyl))) |>
  mark_point(size = 3) |>
  scale_color(range = c("#E41A1C", "#377EB8", "#4DAF4A"))
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

### `label_*()` — Text Labels

Five label functions use a three-parameter protocol:

| Call                    | Behaviour                            |
|:------------------------|:-------------------------------------|
| `label_*(text = "str")` | Set custom text                      |
| `label_*(hide = TRUE)`  | Remove element and its space         |
| `label_*(reset = TRUE)` | Restore variable name or remove text |

``` r

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color(range = "brewer") |>
  label_title("Iris Measurements") |>
  label_subtitle("Anderson's Iris Data") |>
  label_caption("Source: R.A. Fisher, 1936") |>
  label_axis("Sepal Width (cm)", aes = "x") |>
  label_axis("Sepal Length (cm)", aes = "y") |>
  label_legend("Species", aes = "colour")
#> Warning: Aesthetic "colour" is not present in the plot mapping.
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : chr "Iris Measurements"
#>  .. .. @ subtitle: chr "Anderson's Iris Data"
#>  .. .. @ caption : chr "Source: R.A. Fisher, 1936"
#>  .. .. @ x       : chr "Sepal Width (cm)"
#>  .. .. @ y       : chr "Sepal Length (cm)"
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   :List of 5
#>  .. .. .. $ title   : logi TRUE
#>  .. .. .. $ subtitle: logi TRUE
#>  .. .. .. $ caption : logi TRUE
#>  .. .. .. $ x       : logi TRUE
#>  .. .. .. $ y       : logi TRUE
```

### `project_*()` — Coordinate Systems

``` r

# Flipped coordinates
iris |>
  plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
  mark_boxplot() |>
  project_cartesian(flip = TRUE)
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0.8
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

``` r

# Zoom via xlim/ylim
mtcars |>
  plotit(encode(x = wt, y = mpg)) |>
  mark_point() |>
  project_cartesian(xlim = c(2, 4), ylim = c(15, 25))
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
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

### `split_*()` — Facets

``` r

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  split_wrap(~ Species, ncol = 3)
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
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

### `style()` — Themes

``` r

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color(range = "viridis") |>
  style(ggplot2::theme_minimal(base_size = 14))
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```

## Export

``` r

p <- mtcars |>
  plotit(encode(x = wt, y = mpg, colour = factor(cyl))) |>
  mark_point(size = 2) |>
  label_title("Fuel Economy")

export(p, "mtcars_plot.png", width = 8, height = 5, dpi = 300)
```
