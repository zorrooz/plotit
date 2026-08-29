# Beeswarm plot layer

Adds a beeswarm (quasirandom scatter) layer to avoid overplotting for
one-dimensional distributions. Requires the ggbeeswarm package.

## Usage

``` r
mark_beeswarm(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  method = c("swarm", "compactswarm", "hex", "square", "center", "centre"),
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

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_beeswarm`

- method:

  Method for point placement: `"swarm"`, `"compactswarm"`, `"hex"`,
  `"square"`, `"center"`, or `"centre"`.

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

R:
[`ggbeeswarm::geom_beeswarm()`](https://rdrr.io/pkg/ggbeeswarm/man/geom_beeswarm.html)
(collision-avoidance rendering) AntV G2:
[Beeswarm](https://g2.antv.antgroup.com/en/api/mark/beeswarm) (corelib)

## Examples

``` r
plotit(iris, encode(x = Species, y = Sepal.Length)) |>
  mark_beeswarm()
```
