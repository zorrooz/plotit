# Export a plotit object to a file

Export a plotit object to a file

## Usage

``` r
export(
  plot,
  filename,
  width = NULL,
  height = NULL,
  dpi = 300,
  device = NULL,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- filename:

  Output filename (extension determines device, e.g., ".pdf").

- width:

  Output width (if NULL, uses meta then package default).

- height:

  Output height (if NULL, uses meta then package default).

- dpi:

  Resolution for raster formats (default 300).

- device:

  Graphics device to use (if NULL, auto-detected from filename).

- ...:

  Additional arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

Invisibly, the original `plotit` object.

## Examples

``` r
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
export(p, tempfile(fileext = ".png"), dpi = 72)
```
