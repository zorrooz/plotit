# Map layer

Adds a geographic map layer for sf spatial data frames. Requires the sf
package.

## Usage

``` r
mark_map(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics

- data:

  Optional sf data frame for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_sf`

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object

## Examples

``` r
if (FALSE) { # \dontrun{
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
plotit(nc, encode(geometry = geometry)) |> mark_map()
} # }
```
