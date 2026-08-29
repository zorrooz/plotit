# Export a plotit object to a file

Exports a single plot, a composite, or a list of plots as a multi-page
PDF (each list element becomes one page, in order).

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

  A plotit object, a `plotit_composite`, or a list of
  `plotit`/`plotit_composite` objects. A list is exported as a
  multi-page PDF and therefore requires a `.pdf` filename (or
  `device = "pdf"`): single-page devices would silently keep only the
  last page.

- filename:

  Output filename (extension determines device, e.g., ".pdf").

- width:

  Output width (if NULL, uses meta then package default; for a list,
  applied to every page).

- height:

  Output height (if NULL, uses meta then package default; for a list,
  applied to every page).

- dpi:

  Resolution for raster formats (default 300).

- device:

  Graphics device to use (if NULL, auto-detected from filename).

- ...:

  Additional arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

Invisibly, the original `plot` argument.

## Examples

``` r
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
export(p, tempfile(fileext = ".png"), dpi = 72)
```
