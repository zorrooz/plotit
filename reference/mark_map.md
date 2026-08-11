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

  Position adjustment (ignored for sf layers).

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

## References

Vega-Lite:
[Geoshape](https://vega.github.io/vega-lite/docs/geoshape.html)

AntV G2: [GeoPath](https://g2.antv.antgroup.com/en/api/mark/geo-path)

## Examples

``` r
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
plotit(nc, encode(geometry = geometry)) |> mark_map()
```
