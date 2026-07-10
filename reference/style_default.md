# Apply the default plotit theme (convenience wrapper for style())

Apply the default plotit theme (convenience wrapper for style())

## Usage

``` r
style_default(plot, ..., base_size = NULL, base_family = NULL)
```

## Arguments

- plot:

  A plotit object.

- base_size:

  Base font size in pts (default 11).

- base_family:

  Base font family (default `""` = system sans-serif).

## Value

Modified plotit object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  style_default()
```
