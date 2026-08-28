#' @include class.R
#' @include utils.R
#' @include mark_style.R
#' @include mark.R
NULL

# ---- mark_image (D-02, design/03 <U+00A7>3) ----
# Self-built image-scatter geom (Observable Plot `Image` mark, G2 `image`):
# positions a raster image per (x, y) row.  Sources are local file paths
# (png/jpeg), http(s) URLs, or pre-read raster arrays (e.g. from magick).
# Rendering is a thin wrapper over grid::rasterGrob; image reading is cached
# per source string for the session.  No ggimage dependency (judged
# unsuitable in research/01 <U+00A7>8.1-3): raster decoding uses the optional
# lightweight `png` / `jpeg` packages, arrays pass straight through.

# Session-level image cache keyed by source string; raster arrays bypass it.
._image_cache <- new.env(parent = emptyenv())

#' Read an image source into a raster array.
#' @noRd
#' @keywords internal
._read_image_src <- function(src) {
  if (is.array(src) && length(dim(src)) >= 3) {
    return(src)
  }
  key <- as.character(src)
  if (is.na(key) || !nzchar(key)) {
    return(NULL)
  }
  cached <- get0(key, envir = ._image_cache, inherits = FALSE)
  if (!is.null(cached)) {
    return(cached)
  }
  path <- key
  if (grepl("^https?://", path)) {
    tmp <- tempfile(fileext = paste0(".", tolower(tools::file_ext(path))))
    utils::download.file(path, tmp, quiet = TRUE, mode = "wb")
    path <- tmp
  }
  ext <- tolower(tools::file_ext(path))
  raster <- switch(ext,
    png = {
      ._require_pkg("png", "Reading {.fn png} images")
      png::readPNG(path)
    },
    jpg = ,
    jpeg = {
      ._require_pkg("jpeg", "Reading {.fn jpeg} images")
      jpeg::readJPEG(path)
    },
    ._abort_arg_enum(
      "src", c("png file", "jpeg file", "http(s) URL", "raster array"),
      got = ext,
      hint = "Image sources are png/jpeg paths, URLs, or pre-read raster arrays."
    )
  )
  assign(key, raster, envir = ._image_cache)
  raster
}

# Build one image grob: aspect-preserved single `size` (npc) applied to the
# image's larger dimension; optional circular clipping via a viewport.
#' Build a single positioned image grob.
#' @noRd
#' @keywords internal
._image_grob <- function(raster, x, y, size, clip, interpolate) {
  dims <- dim(raster)
  height_px <- dims[1]
  width_px <- dims[2]
  if (is.null(dims) || width_px < 1 || height_px < 1) {
    return(grid::nullGrob())
  }
  aspect <- height_px / width_px
  # Wide image: width = `size` npc, height follows aspect; tall image:
  # height = `size` npc, width follows aspect (rasterGrob preserves the
  # aspect ratio when only one dimension is set).
  if (aspect >= 1) {
    grob <- grid::rasterGrob(
      raster,
      x = x, y = y, height = grid::unit(size, "npc"),
      interpolate = interpolate
    )
  } else {
    grob <- grid::rasterGrob(
      raster,
      x = x, y = y, width = grid::unit(size, "npc"),
      interpolate = interpolate
    )
  }
  if (identical(clip, "circle")) {
    grid::rasterGrob(._circle_mask(raster),
      x = x, y = y,
      height = if (aspect >= 1) grid::unit(size, "npc") else NULL,
      width = if (aspect >= 1) NULL else grid::unit(size, "npc"),
      interpolate = interpolate
    )
  } else {
    grob
  }
}

# Multiply an alpha channel into the raster so pixels outside the inscribed
# circle become transparent (device-independent circular clipping).
#' Apply a circular alpha mask to a raster array.
#' @noRd
#' @keywords internal
._circle_mask <- function(raster) {
  dims <- dim(raster)
  h <- dims[1]
  w <- dims[2]
  y <- (seq_len(h) - (h + 1) / 2) / h
  x <- (seq_len(w) - (w + 1) / 2) / w
  d <- sqrt(outer(y^2, rep(1, w)) + outer(rep(1, h), x^2))
  mask <- d <= 0.5
  if (dims[3] == 4) {
    raster[, , 4] <- raster[, , 4] * mask
    raster
  } else {
    out <- array(NA_real_, dim = c(h, w, 4))
    out[, , 1:3] <- raster
    out[, , 4] <- mask
    out
  }
}

GeomPlotitImage <- ggplot2::ggproto(
  "GeomPlotitImage",
  ggplot2::Geom,
  required_aes = c("x", "y", "src"),
  draw_panel = function(data, panel_params, coord, size = 0.05,
                        clip = "rectangle", interpolate = TRUE,
                        na.rm = FALSE) {
    data <- data[!is.na(data$src) & !is.na(data$x) & !is.na(data$y), , drop = FALSE]
    if (nrow(data) == 0) {
      return(grid::nullGrob())
    }
    coords <- coord$transform(data, panel_params)
    grobs <- lapply(seq_len(nrow(coords)), function(i) {
      raster <- ._read_image_src(coords$src[i])
      if (is.null(raster)) {
        return(grid::nullGrob())
      }
      ._image_grob(
        raster, coords$x[i], coords$y[i],
        size = size, clip = clip,
        interpolate = interpolate
      )
    })
    ggplot2:::ggname("geom_plotit_image", do.call(grid::grobTree, grobs))
  }
)

# Internal layer constructor consumed by mark_image through the shared
# mark path (extra params are do.call'ed onto this constructor).
#' Image layer constructor.
#' @noRd
#' @keywords internal
._geom_plotit_image <- function(mapping = NULL, data = NULL,
                                stat = "identity", position = "identity",
                                size = 0.05, clip = "rectangle",
                                interpolate = TRUE, na.rm = FALSE,
                                show.legend = NA, inherit.aes = TRUE, ...) {
  ggplot2::layer(
    geom = GeomPlotitImage, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = rlang::list2(
      size = size, clip = clip, interpolate = interpolate, na.rm = na.rm, ...
    )
  )
}

#' Image layer
#'
#' Places an image at each (x, y): the isotype / photo-scatter mark
#' (Observable Plot `Image`).  Sources are png/jpeg file paths, http(s)
#' URLs, or pre-read raster arrays (e.g. via \pkg{magick}); arrays skip
#' decoding entirely.  A single `size` sets the image's larger dimension
#' as a fraction of the panel and the aspect ratio is preserved
#' (`clip = "circle"` crops to a disc).
#'
#' Rows with `NA` or empty `src` are dropped.  Images are decoded once per
#' source and cached for the session.  Like any glyph, an image that would
#' extend past the data range is clipped by the panel: boundary placements
#' should widen the scale limits (e.g. `scale_x(limits = c(0, 4))`).
#'
#' @param plot A plotit object
#' @param mapping Optional aesthetics: `x`, `y`, `src`
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param size Larger image dimension as a fraction of the panel
#'   (default 0.05).
#' @param clip `"rectangle"` (default) or `"circle"` (crop to a disc).
#' @param interpolate Pass smooth interpolation to the raster (default
#'   `TRUE`; `FALSE` keeps pixel edges crisp, useful for large-scale
#'   isotype tiles).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the internal layer constructor.
#'   Rotation (Observable Plot `rotate`) is a recorded extension position,
#'   not implemented.
#' @return Modified plotit object
#' @references
#' Observable Plot: `Plot.image` (src channel, round clip, imageRendering)
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/examples}{image} (via G2 mark extensions)
#' @examplesIf requireNamespace("png", quietly = TRUE)
#' # build a small in-memory png, then scatter it
#' tmp_png <- tempfile(fileext = ".png")
#' png::writePNG(array(c(0.2, 0.4, 0.8), dim = c(1, 1, 3)), tmp_png)
#' df <- data.frame(x = c(1, 2), y = c(1, 2), src = tmp_png)
#' plotit(df, encode(x = x, y = y, src = src)) |>
#'   mark_image(size = 0.2)
#' @export
mark_image <- S7::new_generic(
  "mark_image", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           size = 0.05, clip = "rectangle",
           interpolate = TRUE,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_image, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  size = 0.05, clip = "rectangle", interpolate = TRUE,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  clip_choices <- c("rectangle", "circle")
  if (length(clip) != 1 || is.na(clip) || !clip %in% clip_choices) {
    ._abort_arg_enum("clip", clip_choices, got = clip)
  }
  if (!is.numeric(size) || length(size) != 1 || is.na(size) || size <= 0 || size > 1) {
    ._abort_arg_range("size", "in (0, 1] (panel fraction)", got = size)
  }
  ._impl_with(plot, mapping, data, position, ._geom_plotit_image,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_image, mark_name = "mark_image",
    extra = rlang::list2(size = size, clip = clip, interpolate = interpolate, ...)
  )
}
