# Map coordinate system

Applies a geographic projection. Uses
[`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
by default (for simple features), or
[`ggplot2::coord_map()`](https://ggplot2.tidyverse.org/reference/coord_map.html)
when a `projection` string is provided (requires mapproj).

## Usage

``` r
project_map(
  plot,
  projection = NULL,
  xlim = NULL,
  ylim = NULL,
  clip = "on",
  ...
)
```

## Arguments

- plot:

  A plotit object.

- projection:

  Map projection name (e.g. `"mercator"`, `"orthographic"`). `NULL` uses
  `coord_sf()` default.

- xlim, ylim:

  Longitude/latitude limits. `NULL` = auto.

- clip:

  Should drawing be clipped? `"on"` or `"off"`.

- ...:

  Passed to `coord_sf()` or `coord_map()`.

## Value

Modified plotit object.

## Examples

``` r
# requires the sf package
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
plotit(nc, encode()) |> project_map()
```
