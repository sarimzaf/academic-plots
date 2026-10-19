# academic-plots plotting helpers. See ../LICENSE.md and ../NOTICE.md.
library(ggplot2)
library(scales)

## ---- categorical palette ---------------------------------------------------
## Okabe-Ito is the default qualitative palette for colour-vision deficiency.
## Source: Okabe and Ito, "Color Universal Design" (see ../NOTICE.md).
## No palette guarantees distinguishability at every mark size or against
## every background. Inspect simulations and keep redundant encoding.
okabe_ito <- c(
  orange     = "#E69F00",
  skyblue    = "#56B4E9",
  green      = "#009E73",
  yellow     = "#F0E442",
  blue       = "#0072B2",
  vermillion = "#D55E00",
  purple     = "#CC79A7",
  black      = "#000000"
)

## Canonical order above; drawing order below. Yellow (#F0E442) is deferred to
## last because it sits at roughly 1.3:1 contrast against white -- fine as a
## large fill with a border, too low for essential lines, points or labels.
## Blue and vermillion lead because both clear 3:1 against white; still check
## contrast for the actual use and provide a cue beyond hue.
okabe_draw_order <- c("blue", "vermillion", "green", "purple",
                      "orange", "skyblue", "yellow", "black")

pal_okabe_ito <- function(n = 8, order = okabe_draw_order) {
  if (n > length(order)) {
    stop("Okabe-Ito provides 8 colours; ", n, " requested. Collapse small ",
         "categories into Other, or encode with facets instead of colour.")
  }
  unname(okabe_ito[order][seq_len(n)])
}

## ---- continuous palettes ---------------------------------------------------
## Okabe-Ito is qualitative and must never be interpolated into a gradient. For
## ordered data use the Paul Tol schemes below: built for colour-vision
## deficiency, and the sequential ones are monotonic in lightness so they also
## survive greyscale. Palette coordinates: Paul Tol, Colour Schemes (see ../NOTICE.md).
tol_schemes <- list(
  ## sequential -- lightness runs monotonically from one end to the other
  YlOrBr       = c("#FFFFE5","#FFF7BC","#FEE391","#FEC44F","#FB9A29","#EC7014",
                   "#CC4C02","#993404","#662506"),
  iridescent   = c("#FEFBE9","#FCF7D5","#F5F3C1","#EAF0B5","#DDECBF","#D0E7CA",
                   "#C2E3D2","#B5DDD8","#A8D8DC","#9BD2E1","#8DCBE4","#81C4E7",
                   "#7BBCE7","#7EB2E4","#88A5DD","#9398D2","#9B8AC4","#9D7DB2",
                   "#9A709E","#906388","#805770","#684957","#46353A"),
  incandescent = c("#CEFFFF","#C6F7D6","#A2F49B","#BBE453","#D5CE04","#E7B503",
                   "#F19903","#F6790B","#F94902","#E40515","#A80003"),
  ## diverging -- light in the middle, dark at both ends
  sunset       = c("#364B9A","#4A7BB7","#6EA6CD","#98CAE1","#C2E4EF","#EAECCC",
                   "#FEDA8B","#FDB366","#F67E4B","#DD3D2D","#A50026"),
  nightfall    = c("#125A56","#00767B","#238F9D","#42A7C6","#60BCE9","#9DCCEF",
                   "#C6DBED","#DEE6E7","#ECEADA","#F0E6B2","#F9D576","#FFB954",
                   "#FD9A44","#F57634","#E94C1F","#D11807","#A01813"),
  BuRd         = c("#2166AC","#4393C3","#92C5DE","#D1E5F0","#F7F7F7","#FDDBC7",
                   "#F4A582","#D6604D","#B2182B"),
  PRGn         = c("#762A83","#9970AB","#C2A5CF","#E7D4E8","#F7F7F7","#D9F0D3",
                   "#ACD39E","#5AAE61","#1B7837")
)
## Tol gives each scheme a distinct out-of-range colour, so missing data never
## reads as a low value. Use it for na.value.
tol_bad <- c(YlOrBr = "#888888", iridescent = "#999999", incandescent = "#888888",
             sunset = "#FFFFFF", nightfall = "#FFFFFF",
             BuRd = "#FFEE99", PRGn = "#FFEE99")

## ---- neutrals --------------------------------------------------------------
## Data gets colour; structure gets grey. Anything that is not the data itself --
## axis lines, baselines, comparators, borders -- lives here.
figure_neutrals <- c(
  ink        = "#222222",  # all text, axis lines, ticks
  charcoal   = "#5C5858",  # reference lines, captions
  muted      = "#C9C9C9",  # de-emphasised / comparator series
  muted_line = "#8F8F8F",  # border for muted fills
  grid       = "#EBEBEB",  # grid lines, for the rare figure that needs them
  country    = "#FFFFFF",  # map base: CMYK 0,0,0,0
  land       = "#EDEDED",  # neighbouring land: CMYK 7,7,7,0
  boundary   = "#6F6F6F",  # map: administrative borders
  outline    = "#B6B6B6",  # map: internal outlines
  water      = "#E6FAFF",  # water fill: CMYK 10,2,0,0
  water_edge = "#78C7E3"   # water outline: CMYK 53,22,11,0; 0.3 pt
)

## Mix a colour towards white for deliberately de-emphasised fills.
## Confidence-interval strokes should retain full contrast; do not lighten them.
lighten_color <- function(color, amount = 0.10) {
  m <- grDevices::col2rgb(color) / 255
  grDevices::rgb(t(m + (1 - m) * amount))
}

## ---- typography ------------------------------------------------------------
figure_font <- function(
    prefer   = "Libre Franklin",
    fallback = c("Source Sans 3", "Source Sans Pro", "Segoe UI",
                 "Helvetica Neue", "Helvetica", "Arial")) {
  installed <- character()
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    installed <- unique(systemfonts::system_fonts()$family)
  }
  available <- c(prefer, fallback)
  available <- available[available %in% installed]
  chosen <- if (length(available)) available[1] else "sans"
  if (length(prefer) && chosen != prefer[1])
    warning("Preferred font '", prefer[1], "' was not discovered; using '", chosen,
            "'. Set up the requested font before final export and verify embedding.", call. = FALSE)
  chosen
}
figure_family <- figure_font()

## ---- theme -----------------------------------------------------------------
## The defaults encode the house rules: no internal grid, both axis lines drawn,
## ticks on the axes that carry values. Spacing scales with base_size so a
## single-column figure is not swamped by its own chrome.
theme_figure <- function(base_size = 14,
                         base_family = figure_family,
                         grid = c("none", "y", "x", "both"),
                         legend = "top",
                         legend_title = FALSE,
                         ticks = c("both", "x", "y", "none")) {
  grid <- match.arg(grid); ticks <- match.arg(ticks)
  grid_line <- element_line(color = figure_neutrals[["grid"]], linewidth = 0.35)
  axis_line <- element_line(color = figure_neutrals[["ink"]], linewidth = 0.5, lineend = "butt")
  tick_line <- element_line(color = figure_neutrals[["ink"]], linewidth = 0.4)
  none <- element_blank()
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      text               = element_text(color = figure_neutrals[["ink"]]),
      plot.background    = element_rect(fill = "white", color = NA),
      panel.background   = element_rect(fill = "white", color = NA),
      panel.border       = none,
      panel.grid.minor   = none,
      panel.grid.major.x = if (grid %in% c("x", "both")) grid_line else none,
      panel.grid.major.y = if (grid %in% c("y", "both")) grid_line else none,
      axis.line.x        = axis_line,
      axis.line.y        = axis_line,
      axis.ticks.x       = if (ticks %in% c("x", "both")) tick_line else none,
      axis.ticks.y       = if (ticks %in% c("y", "both")) tick_line else none,
      axis.ticks.length  = unit(3.5, "pt"),
      axis.text          = element_text(size = rel(0.86),
                                        color = figure_neutrals[["ink"]]),
      axis.title         = element_text(size = rel(0.9)),
      axis.title.x       = element_text(margin = margin(t = 8)),
      axis.title.y       = element_text(margin = margin(r = 10)),
      strip.text         = element_text(face = "bold", size = rel(0.9)),
      strip.background   = none,
      plot.title         = element_text(face = "bold", size = rel(1.15), hjust = 0.5,
                                        vjust = 1, margin = margin(b = 8)),
      plot.subtitle      = element_text(size = rel(0.95), hjust = 0,
                                        color = figure_neutrals[["charcoal"]]),
      plot.caption       = element_text(size = rel(0.75), hjust = 0,
                                        color = figure_neutrals[["charcoal"]]),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      legend.position    = legend,
      legend.direction   = if (legend %in% c("top", "bottom")) "horizontal" else "vertical",
      legend.box         = "horizontal",
      legend.byrow       = TRUE,
      legend.title       = if (legend_title) element_text(size = rel(0.9)) else none,
      legend.text        = element_text(size = rel(0.93)),
      legend.key         = element_rect(fill = "white", color = NA),
      legend.key.size    = unit(base_size * 0.9, "pt"),
      legend.margin      = margin(0, 0, 0, 0),
      legend.box.spacing = unit(base_size * 0.5, "pt"),
      panel.spacing      = unit(1, "lines"),
      plot.margin        = margin(base_size * 0.6, base_size * 1.4,
                                  base_size * 0.6, base_size * 0.6)
    )
}

## Discrete guides: explicitly use one row; increase only after measuring overflow.
legend_figure <- function(nrow = 1) guide_legend(nrow = nrow, byrow = TRUE)

## Median absolute slope banking. Returns physical PANEL height / width.
## dx/dy are adjacent drawn segments, already in transformed axis coordinates.
bank_ratio <- function(dx, dy, x_range, y_range) {
  ok <- is.finite(dx) & is.finite(dy) & dx != 0
  slopes <- abs(dy[ok] / dx[ok])  # retain horizontal segments in the median
  m <- if (length(slopes)) median(slopes) else NA_real_
  rx <- diff(range(x_range)); ry <- diff(range(y_range))
  if (!is.finite(m) || m <= 0 || !is.finite(rx) || !is.finite(ry) || rx <= 0 || ry <= 0) {
    warning("No finite MAS aspect ratio; use and record readable fallback sizing.")
    return(NA_real_)
  }
  ry / (rx * m)
}

## Normalised slopes for common-size panels; never include leader lines.
bank_segments <- function(p, layers = 1L) {
  if (!inherits(p$coordinates, "CoordCartesian") || inherits(p$coordinates, "CoordFixed"))
    stop("Banking requires a Cartesian panel without a fixed coordinate ratio.")
  if (any(vapply(p$coordinates$limits, function(x) !is.null(x), logical(1))))
    stop("Clip segments to the coordinate window first, then use bank_ratio() on them.")
  b <- ggplot_build(p)
  if (length(b$layout$panel_params) != 1L) stop("Pass component plots together to bank_panels().")
  segments <- lapply(layers, function(i) {
    if (!any(vapply(c("GeomLine", "GeomPath", "GeomSmooth"),
                    function(cls) inherits(p$layers[[i]]$geom, cls), logical(1))))
      stop("Select drawn line/path/fit layers; unordered points have no banking segments.")
    d <- b$data[[i]]
    do.call(rbind, lapply(split(d, d$group), function(g) {
      # Build order follows the drawn path; missing values break adjacency.
      data.frame(dx = diff(g$x), dy = diff(g$y))
    }))
  })
  segments <- do.call(rbind, segments)
  panel <- b$layout$panel_params[[1]]
  ok <- is.finite(segments$dx) & is.finite(segments$dy) & segments$dx != 0
  abs(segments$dy[ok] / segments$dx[ok]) * diff(panel$x.range) / diff(panel$y.range)
}

## One pooled MAS ratio for the entire composition, after range normalisation.
bank_panels <- function(plots, layers = rep(list(1L), length(plots))) {
  if (!length(plots) || length(layers) != length(plots)) stop("Specify layers for each panel.")
  slopes <- unlist(Map(bank_segments, plots, layers), use.names = FALSE)
  slopes <- slopes[is.finite(slopes)]
  m <- if (length(slopes)) median(slopes) else NA_real_
  if (!is.finite(m) || m <= 0) {
    warning("No finite MAS ratio; choose one readable common panel size.")
    return(plots)
  }
  lapply(plots, function(p) p + theme(aspect.ratio = 1 / m))
}
bank_plot <- function(p, layers = 1L) bank_panels(list(p), list(layers))[[1]]

## ---- numbers ---------------------------------------------------------------
## House rounding: 3 decimals below 1, 2 up to 100, 1 up to 1000, integers
## above. label_figure() formats for display with a comma thousands separator.
digits_figure <- function(x) {
  a <- abs(x)
  ifelse(is.na(a), 0, ifelse(a < 1, 3, ifelse(a < 100, 2, ifelse(a < 1000, 1, 0))))
}
round_figure <- function(x) round(x, digits_figure(x))

## Two adjustments to the bare rule, both of which matter in practice:
##
## 1. Every value in a set is formatted to the SAME precision, taken from the
##    largest magnitude present. Mixing precisions inside one set of labels
##    reads as a mistake: c(1284.4, 962.75) should print 1,284 and 963, not
##    1,284 and 962.8.
## 2. Whole numbers never get decimals. Counts and round axis breaks are
##    already exact, so the rule would otherwise print a count of units as
##    "800.0" and an axis break of 20 as "20.00", claiming precision that is
##    not merely unsupported but meaningless.
##
## Pass per_value = TRUE for the literal per-number rule, which is right when a
## number stands alone in prose.
label_figure <- function(x, per_value = FALSE, ...) {
  is_whole <- function(v) abs(v - round(v)) < .Machine$double.eps^0.5
  all_whole <- function(v) { v <- v[!is.na(v)]; length(v) > 0 && all(is_whole(v)) }
  if (per_value) {
    d <- digits_figure(x)
    return(vapply(seq_along(x), function(i) {
      if (is.na(x[i])) return(NA_character_)
      acc <- if (is_whole(x[i])) 1 else 10^(-d[i])
      comma(x[i], accuracy = acc, ...)
    }, character(1)))
  }
  d <- digits_figure(suppressWarnings(max(abs(x), na.rm = TRUE)))
  if (!is.finite(d)) d <- 0
  if (all_whole(x)) d <- 0
  out <- comma(x, accuracy = 10^(-d), ...)
  out[!is.na(x) & x == 0] <- "0"
  out
}

## Preserve a literal zero on numeric axes, even when other ticks have units.
## Keep unit suffixes on the axis title and in legends/value labels.
label_axis <- function(x, formatter = scales::label_number(big.mark = ",")) {
  out <- formatter(x)
  out[!is.na(x) & x == 0] <- "0"
  out
}

## Include the baseline without dropping negative observations or CI endpoints.
zero_limits <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) stop("No finite values for axis limits")
  range(c(0, x))
}
## A zero inside the range must not disappear because pretty breaks skipped it.
breaks_with_zero <- function(n = 5) function(limits) {
  b <- scales::breaks_pretty(n)(limits)
  b <- b[b >= limits[1] & b <= limits[2]]
  if (limits[1] <= 0 && limits[2] >= 0) b <- c(b, 0)
  sort(unique(b))
}

## ---- proportion scales -----------------------------------------------------
## A legend or axis for a share should show the reader a full, round range
## rather than only the span this sample happened to cover -- but a fixed 0-1
## range wastes most of the scale when the data tops out low, collapsing every
## category into the first bin or two. So the ceiling steps up with the data:
## up to 0.25, up to 0.50, otherwise the full 0-1. Steps stay round at every
## ceiling, and the 0-1 case is the familiar quarters.
share_scale <- function(x, percent = FALSE) {
  m <- suppressWarnings(max(abs(x), na.rm = TRUE))
  if (!is.finite(m)) m <- 1
  ceilings <- c(0.25, 0.50, 1.00)
  steps    <- c(0.05, 0.10, 0.25)
  i <- which(ceilings >= m)[1]
  if (is.na(i)) i <- length(ceilings)
  brk <- seq(0, ceilings[i], steps[i])
  list(limits = c(0, ceilings[i]), breaks = brk,
       labels = if (percent) label_percent(accuracy = 1)(brk) else label_figure(brk))
}

## ---- label headroom --------------------------------------------------------
## Expansion needed on the value axis so the longest label is not clipped by the
## panel edge. Returns a multiplier for expansion(mult = c(0, .)).
label_headroom <- function(labels, size_pt, panel_width_in, pad = 0.01) {
  text_in <- max(nchar(as.character(labels))) * 0.5 * size_pt / 72
  text_in / panel_width_in + pad
}

## ---- categorical axis order ------------------------------------------------
## Put a categorical axis in a deliberate order. On y the first element of
## `order` ends up at the TOP, because a reader scans a list downwards; ggplot
## would otherwise place it at the bottom.
axis_order <- function(x, order, axis = c("y", "x")) {
  axis <- match.arg(axis)
  order <- as.character(order)
  extra <- setdiff(as.character(x), order)
  if (length(extra)) stop("Not in `order`: ", paste(extra, collapse = ", "))
  factor(as.character(x), levels = if (axis == "y") rev(order) else order)
}

## ---- proportional figure sizing --------------------------------------------
## All template sizes describe a 7 x 5.5 inch reference figure. One linear
## factor based on area scales visual sizes, never coordinates or data widths.
figure_size_factor <- function(width, height, reference = c(7, 5.5)) {
  if (length(width) != 1L || length(height) != 1L || length(reference) != 2L ||
      any(!is.finite(c(width, height, reference))) || any(c(width, height, reference) <= 0))
    stop("width, height and both reference dimensions must be finite and positive")
  sqrt((width / reference[1]) * (height / reference[2]))
}

.figure_size_names <- c("size", "linewidth", "stroke", "fontsize", "pointsize",
  "borderwidth", "label.size", "segment.size", "point.size", "outlier.size",
  "outlier.stroke", "median.linewidth", "box.linewidth", "whisker.linewidth",
  "staple.linewidth", "staple.size")

.figure_scale_units <- function(x, factor) {
  # lines/char already follow the scaled font; native/npc/null describe layout.
  types <- grid::unitType(x)
  physical <- types %in% c("inches", "cm", "mm", "points", "picas", "bigpts",
                          "dida", "cicero", "scaledpts")
  if (any(physical)) x[physical] <- x[physical] * factor
  x
}

.figure_scale_style <- function(x, factor, name = "") {
  if (inherits(x, "rel")) return(x)
  if (grid::is.unit(x)) return(.figure_scale_units(x, factor))
  if (inherits(x, c("element", "ggplot2::element"))) {
    for (key in names(S7::props(x)))
      S7::prop(x, key) <- .figure_scale_style(S7::prop(x, key), factor, key)
  } else if (is.list(x)) {
    for (i in seq_along(x)) {
      key <- if (is.null(names(x))) "" else names(x)[i]
      x[i] <- list(.figure_scale_style(x[[i]], factor, key))
    }
  } else if (is.numeric(x) && name %in% .figure_size_names) x <- x * factor
  x
}

.figure_clone <- function(parent) { force(parent); ggplot2::ggproto(NULL, parent) }

.figure_scale_guide <- function(guide, factor) {
  if (!inherits(guide, "Guide")) return(guide)
  guide <- .figure_clone(guide)
  guide$params <- .figure_scale_style(guide$params, factor)
  guide
}

scale_figure <- function(plot, width, height, reference = c(7, 5.5)) {
  factor <- figure_size_factor(width, height, reference)
  if (factor == 1) return(plot)
  if (!inherits(plot, "ggplot"))
    stop("Relative sizing supports ggplot and patchwork plots; use reference = NULL in save_figure() for other grobs")
  # Patchwork stores all but its last panel in patches. Scale the whole
  # composition once, including annotation themes and physical layout widths.
  is_patchwork <- inherits(plot, "patchwork")
  if (is_patchwork) {
    patches <- plot$patches
    saved_class <- class(plot)
    class(plot) <- setdiff(saved_class, "patchwork")
    plot$patches <- NULL
    patches$plots <- lapply(patches$plots, scale_figure, width=width, height=height, reference=reference)
    patches$annotation$theme <- .figure_scale_style(patches$annotation$theme, factor)
    patches$layout <- .figure_scale_style(patches$layout, factor)
  }
  # The preflight build must not consume random jitter or stochastic stats.
  had_seed <- exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE)
  seed <- if (had_seed) get(".Random.seed", envir=.GlobalEnv) else NULL
  on.exit({
    if (had_seed) assign(".Random.seed", seed, envir=.GlobalEnv)
    else if (exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE))
      rm(".Random.seed", envir=.GlobalEnv)
  }, add=TRUE)
  # Materialise automatic size scales before changing their output range.
  # A plot's data, limits and mapped relationships remain the same.
  built <- ggplot2::ggplot_build(plot)
  plot$scales <- built$plot$scales$clone()
  for (i in seq_along(plot$scales$scales)) {
    scale <- plot$scales$scales[[i]]
    if (any(scale$aesthetics %in% c("size", "linewidth", "stroke"))) {
      scale <- scale$clone()
      if (inherits(scale, c("ScaleContinuousIdentity", "ScaleDiscreteIdentity"))) {
        scale$map <- local({ k <- factor; function(x, ...) x * k })
      } else {
        scale$palette <- local({ palette <- scale$palette; k <- factor
          function(...) palette(...) * k
        })
        scale$palette.cache <- NULL
      }
    }
    scale$guide <- .figure_scale_guide(scale$guide, factor)
    plot$scales$scales[[i]] <- scale
  }
  plot$theme <- .figure_scale_style(ggplot2::theme_get() + plot$theme, factor)
  plot$layers <- lapply(plot$layers, function(layer) {
    layer <- .figure_clone(layer)
    layer$aes_params <- .figure_scale_style(layer$aes_params, factor)
    layer$geom_params <- .figure_scale_style(layer$geom_params, factor)
    # Legacy/custom geoms may have literal defaults instead of from_theme().
    layer$geom <- .figure_clone(layer$geom)
    defaults <- layer$geom$default_aes
    for (key in intersect(names(defaults), .figure_size_names)) {
      value <- rlang::get_expr(defaults[[key]])
      if (is.numeric(value)) defaults[[key]] <- value * factor
    }
    layer$geom$default_aes <- defaults
    layer
  })
  plot$guides <- .figure_clone(plot$guides)
  plot$guides$guides <- lapply(plot$guides$guides, .figure_scale_guide, factor=factor)
  if (is_patchwork) {
    plot$patches <- patches
    class(plot) <- saved_class
  }
  plot
}

## ---- export ----------------------------------------------------------------
## Uses ragg / cairo devices when available so non-default fonts actually render.
save_figure <- function(plot, path, width = 7, height = 5.5, dpi = 800,
                        bg = "white", reference = c(7, 5.5)) {
  if (!is.null(reference)) plot <- scale_figure(plot, width, height, reference)
  ext <- tolower(tools::file_ext(path))
  args <- list(filename = path, plot = plot, width = width, height = height,
               units = "in", bg = bg)
  if (ext %in% c("png", "tiff", "jpg", "jpeg")) {
    args$dpi <- dpi
    if (requireNamespace("ragg", quietly = TRUE)) {
      args$device <- switch(ext, png = ragg::agg_png, tiff = ragg::agg_tiff,
                            ragg::agg_jpeg)
    }
  } else if (ext == "pdf") {
    args$device <- grDevices::cairo_pdf
  } else if (ext == "svg" && requireNamespace("svglite", quietly = TRUE)) {
    args$device <- svglite::svglite
  }
  do.call(ggsave, args)
  invisible(normalizePath(path, winslash = "/"))
}

## Low-resolution twin of the real export, for looking at during development.
## The same dimensions and reference apply exactly the same scaling as export.
preview_figure <- function(plot, path = "preview.png", width = 7, height = 5.5,
                           reference = c(7, 5.5)) {
  save_figure(plot, path, width = width, height = height, dpi = 150, reference = reference)
}

## Text inside the panel (geom_text/geom_label) is sized in mm, not points.
pt <- function(points) points / .pt   # e.g. size = pt(10)

## ---- contrast --------------------------------------------------------------
## WCAG relative luminance and contrast ratio. contrast_text() picks the
## readable label colour for a given fill instead of hard-coding white, which is
## unreadable on every pale fill in the palette.
relative_luminance <- function(color) {
  rgb <- grDevices::col2rgb(color) / 255
  lin <- function(v) ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  as.numeric(0.2126 * lin(rgb[1, ]) + 0.7152 * lin(rgb[2, ]) + 0.0722 * lin(rgb[3, ]))
}

contrast_ratio <- function(color, background = "white") {
  l1 <- relative_luminance(color)
  l2 <- relative_luminance(background)
  (pmax(l1, l2) + 0.05) / (pmin(l1, l2) + 0.05)
}

contrast_text <- function(background, dark = figure_neutrals[["ink"]],
                          light = "white") {
  chosen <- ifelse(contrast_ratio(dark, background) >= contrast_ratio(light, background),
                   dark, light)
  # Ink (#222222) and white can BOTH miss 4.5:1 on a medium fill.
  ifelse(contrast_ratio(chosen, background) >= 4.5, chosen,
         ifelse(contrast_ratio("black", background) >= contrast_ratio("white", background),
                "black", "white"))
}

## ---- figure variants ------------------------------------------------------
## Explicit version overrides destination; NULL/unknown destinations use title.
figure_version <- function(destination = NULL, version = NULL) {
  if (!is.null(version)) return(match.arg(version, c("title", "no title")))
  if (is.null(destination)) return("title")
  if (length(destination) != 1L || is.na(destination))
    stop("destination must be a single non-missing string")
  destination <- tolower(destination)
  if (grepl("\\b(papers?|manuscripts?|journals?|presentations?|slides?)\\b",
            destination, perl = TRUE)) "no title" else "title"
}

## Apply only overall labels. Keep panel headings/facet strips; remove custom
## footnote annotations separately when constructing a no title figure.
figure_labels <- function(title, subtitle = NULL, caption = NULL,
                          destination = NULL, version = NULL) {
  if (figure_version(destination, version) == "no title") {
    labs(title = NULL, subtitle = NULL, caption = NULL)
  } else {
    labs(title = title, subtitle = subtitle, caption = caption)
  }
}
