# Maps

Maps are the one figure type where the *frame* carries meaning: what is drawn
grey, what is drawn water blue, and where the boundaries sit all tell the reader
what is in scope. The neutrals in the style preamble (`land`, `water`,
`boundary`, `outline`) exist for exactly this.

Maps have no axes, so the axis-line and tick rules do not apply — `theme_void`
strips them. Every other house rule still holds: Tol schemes for the fill,
`label_figure()` for legend numbers, fixed legend breaks, and a rate rather than
a count. Sizes below are reference values at 7 x 5.5in; `save_figure()` scales
text, symbols and strokes with the overall export size. Follow the title/no title
rules in [SKILL.md](../SKILL.md), including removal of map footnotes in no title
exports and preservation of descriptive headings in composed maps.

## Contents

- [Country context and map colours](#country-context-and-map-colours)
- [The map theme](#the-map-theme)
- [Choropleth](#choropleth)
- [Labelling regions](#labelling-regions)
- [Point maps](#point-maps)
- [Projections](#projections)
- [Scale bar and north arrow](#scale-bar-and-north-arrow)
- [Insets](#insets)
- [Aspect ratio and export size](#aspect-ratio-and-export-size)
- [When sf is unavailable](#when-sf-is-unavailable)

## Country context and map colours

### Country extent and neighbouring land

Full-country maps must include a visible margin of neighbouring countries, not
just a country silhouette. Start with 5–10% padding around its projected bounding
box and inspect all four edges. Include neighbouring land before drawing the
featured country; do not accidentally label missing polygons as water.

### Base-map colours

Use these base-map colours consistently for country maps and locator insets:

| Feature | CMYK (%) | RGB preview approximation |
|---|---|---|
| Featured country | 0, 0, 0, 0 | `#FFFFFF` |
| Surrounding countries | 7, 7, 7, 0 | `#EDEDED` |
| Water bodies | 10, 2, 0, 0 | `#E6FAFF` |
| Water-body outline | 53, 22, 11, 0 | `#78C7E3` |

### Water geometry and outlines

Water outlines are **0.3 pt at the reference size**, i.e. `linewidth = pt(0.3)` in ggplot, not 0.3 mm.
Draw actual ocean/lake geometry and its outline; a blue panel background alone
does not draw the shoreline. Check islands and lake holes in the land geometry.

### Data-driven fills

These colours are **fallback defaults only where no data variable, source or
explicit style defines the fill**. For a choropleth, map the variable to the
region fill normally; the white-country default must not override it. Do not
replace a choropleth with symbols merely to preserve white land. The user need
not explicitly say "choropleth" for a region-level rate to justify one. Keep
default colours only on unmapped context, such as surrounding land and water.
The same precedence applies to any map whose fill encodes data.

### RGB previews and CMYK export

The hex values are simple RGB preview conversions, not a claim of a CMYK file.
PNG and the default cairo PDF workflow are RGB. For press-ready CMYK delivery,
obtain the printer's ICC profile and use a colour-managed export/conversion;
preserve the specified CMYK targets and verify separations. Never describe an
RGB PNG/PDF as CMYK merely because it uses these approximations.

## The map theme

```r
theme_figure_map <- function(base_size = 14, base_family = figure_family,
                             water = TRUE, legend = "top", legend_title = FALSE) {
  theme_void(base_size = base_size, base_family = base_family) +
    theme(
      text             = element_text(color = figure_neutrals[["ink"]]),
      panel.background = element_rect(
        fill = if (water) figure_neutrals[["water"]] else "white", color = NA),
      plot.background  = element_rect(fill = "white", color = NA),
      plot.title       = element_text(face = "bold", size = rel(1.15), hjust = 0.5,
                                      vjust = 1, margin = margin(b = 8)),
      plot.subtitle    = element_text(size = rel(0.95), hjust = 0,
                                      color = figure_neutrals[["charcoal"]]),
      plot.caption     = element_text(size = rel(0.75), hjust = 0,
                                      color = figure_neutrals[["charcoal"]]),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      legend.position   = legend,
      legend.direction  = if (legend %in% c("top", "bottom")) "horizontal" else "vertical",
      legend.box        = "horizontal",
      legend.byrow      = TRUE,
      legend.title      = if (legend_title) element_text(size = rel(0.9)) else element_blank(),
      ## A horizontal legend puts its title beside the bar by default, where it
      ## collides with the first break label. Above the bar, it never does.
      legend.title.position = "top",
      legend.text       = element_text(size = rel(0.93)),
      legend.key        = element_rect(fill = "white", color = NA),
      legend.key.height = unit(0.5, "lines"),
      plot.margin       = margin(base_size * 0.6, base_size * 0.6,
                                 base_size * 0.6, base_size * 0.6)
    )
}
```

`theme_void` rather than `theme_minimal`: latitude and longitude gridlines are
almost never what the reader needs, and axis titles on a map are noise. An
untitled map may use `legend_title = TRUE` to identify its mapped variable.
When the map has a title or is part of a titled-panel figure, omit the legend
title and place any necessary variable name/units in its panel heading instead.

### Water

**If the mapped area includes sea, ocean or a large lake, that water should be
light blue.** It orients the reader instantly and stops a coastline reading as
an arbitrary boundary. `water = TRUE` sets the panel background to
`figure_neutrals[["water"]]`.

The catch is that a panel background fills the whole bounding-box rectangle, so
any land outside your polygons — a neighbouring country in the corner of the
extent — also comes out blue, claiming sea where there is none. The fix is to
draw the neighbours over the water before the study area, so only genuine sea is
left showing:

```r
## Decide the display window first, then crop the basemap to exactly it.
bb   <- sf::st_bbox(regions)
padx <- 0.06 * (bb[["xmax"]] - bb[["xmin"]])
pady <- 0.06 * (bb[["ymax"]] - bb[["ymin"]])
win  <- c(xmin = bb[["xmin"]] - padx, xmax = bb[["xmax"]] + padx,
          ymin = bb[["ymin"]] - pady, ymax = bb[["ymax"]] + pady)

## Filter out the study country, but do NOT crop to `win` — see below.
neighbours <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
neighbours <- sf::st_make_valid(neighbours)
neighbours <- neighbours[neighbours$admin != "Kenya", ]

p_map <- ggplot() +
  ## 1. neighbours first, over the blue background, so only real sea stays blue
  geom_sf(data = neighbours, fill = figure_neutrals[["land"]],
          color = figure_neutrals[["outline"]], linewidth = 0.2) +
  ## 2. data-driven fill takes precedence over the white country fallback
  geom_sf(data = regions, aes(fill = rate),
          color = figure_neutrals[["outline"]], linewidth = 0.2) +
  geom_sf(data = country_border, fill = NA,
          color = figure_neutrals[["boundary"]], linewidth = 0.5) +
  ## 3. actual water features, including lakes, with the specified 0.3 pt edge
  geom_sf(data = water_bodies, fill = figure_neutrals[["water"]],
          color = figure_neutrals[["water_edge"]], linewidth = pt(0.3)) +
  coord_sf(xlim = win[c("xmin", "xmax")], ylim = win[c("ymin", "ymax")],
           expand = FALSE) +
  theme_figure_map(water = TRUE)
```

For a wholly inland extent with no water in frame, use `water = FALSE`; retain
surrounding-country context on a full-country map even when there is no water.

`water_bodies` above must come from actual ocean/lake features, not from gaps
between independently sourced country polygons. Validate geometry before clipping
or projection. Global ocean polygons may need planar clipping before projection
to avoid spherical ring-orientation inversions; confirm that land is still land
in the preview. Draw data marks and labels after the water layer.

### Map extent and clipping

**Do not crop the basemap to the display window.** `coord_sf` already clips
what it draws, so cropping buys nothing on a country-scale Natural Earth layer —
and it introduces a failure mode: a rectangle in longitude/latitude is not a
rectangle in a projected CRS, so once `coord_sf(crs = )` reprojects, the corners
of the projected view can fall outside the lon/lat box you cropped to. The
basemap then does not cover them, and the gap renders as panel background —
which on a water-blue panel means **fake sea where there is land**. If you must
crop for performance, pad several degrees beyond the window and check the
preview for background-coloured patches where land belongs.

**Do not reach for `coord_sf(clip = "off")` on a map either.** It is the usual
way to let a repelled label sit in the margin, but on a fixed-aspect map it also
lets the basemap polygons draw outside the panel, where they paint over the
legend and caption. Pad the window instead, as above.

## Choropleth

```r
library(sf)

## Ceiling chosen from the data: rates topping out near 45% get a 0-50% legend
## in 10-point bins, not a 0-100% legend that would leave the map two colours.
fill_scale <- share_scale(regions$rate, percent = TRUE)

p_map <- ggplot(regions) +
  geom_sf(aes(fill = rate), color = figure_neutrals[["outline"]],
          linewidth = 0.2) +
  geom_sf(data = country_border, fill = NA,
          color = figure_neutrals[["boundary"]], linewidth = 0.5) +
  scale_fill_stepsn(colours = tol_schemes$YlOrBr,
                    na.value = tol_bad[["YlOrBr"]],
                    limits = fill_scale$limits, breaks = fill_scale$breaks,
                    labels = fill_scale$labels, name = "Adoption rate") +
  coord_sf(expand = FALSE) +
  labs(title = expression("Adoption by region"^a),
       caption = expression(""^a * " Districts with fewer than 30 observations are shown in grey.")) +
  theme_figure_map() +
  theme(legend.key.width = unit(2.4, "lines"))
```

The details that make or break it:

### Mapped values, colours and missing data

- **Map a rate or share, never a raw count.** A district map of counts shows
  where the big districts are, because polygon area does the talking. If counts
  are genuinely the point, use proportional symbols on centroids:
  `geom_sf(data = centroids, aes(size = n))` with
  `scale_size_area(max_size = 8)` — `scale_size_area` matters, since plain
  `scale_size` maps to radius and so exaggerates by squaring.
- **Binned fills beat continuous ones on maps.** Readers match a polygon to a
  swatch rather than interpolating a gradient, and 4–6 bins are far easier to
  read off. `scale_fill_stepsn` with a Tol scheme.
- **`na.value` is not optional.** Missing regions must be visibly different from
  low values, or the map claims data it does not have. Tol supplies a distinct
  bad-data colour per scheme in `tol_bad`; say in the caption why they are
  missing.

### Legends and breaks

- **Fixed legend breaks from `share_scale()`.** The ceiling steps up with the
  data (0.25, 0.5 or 1) so the legend describes a round scale rather than this
  sample's range, without wasting half the ramp on values that never occur.
  Binned maps are where this matters most: with 0-1 quarters, eight regions
  between 13% and 45% would occupy two colours.
- **Wide legend keys** — a horizontal binned legend needs
  `legend.key.width = unit(2.4, "lines")` to be readable under a map.

### Boundaries and padding

- **Thin pale internal outlines, darker outer boundary.** `outline` at
  `linewidth = 0.2` inside, `boundary` at `0.5` around the frame. Heavy internal
  borders on a small map turn the fill into confetti.
- **`coord_sf(expand = FALSE)`** removes the default padding, so the water
  background does not get a frame of dead space.

## Labelling regions

### Country names

For country-name text use `toupper(name)`; this uppercase
rule applies to country names, not region names or other labels.

### Region labels

**A region label belongs inside its own polygon, centred.** Where it will not
fit, move it outside and connect it with a leader line from the centre of the
region, so the association stays unambiguous.

`st_centroid` can fall outside a concave or crescent-shaped polygon, so use
`st_point_on_surface`, which is guaranteed to land inside. Then split the
regions into those that can hold their label and those that cannot. The test
that works is the rendered text width against the polygon width, both in data
units — which needs the panel width in inches, so pass it in rather than
guessing:

```r
library(ggrepel)

## Does the polygon span more longitude than the label needs to draw?
label_fits <- function(sf_obj, labels, size_pt, panel_width_in, x_span) {
  bbs  <- lapply(sf::st_geometry(sf_obj), sf::st_bbox)
  span <- vapply(bbs, function(b) as.numeric(b["xmax"] - b["xmin"]), 0)
  text_in <- nchar(labels) * 0.5 * size_pt / 72   # roughly 0.5 em per character
  needed  <- text_in / panel_width_in * x_span
  data.frame(span = span, needed = needed, fits = span > needed)
}

pts <- suppressWarnings(sf::st_point_on_surface(sf::st_geometry(regions)))
lab <- data.frame(name = regions$name, sf::st_coordinates(pts))
lab <- cbind(lab, label_fits(regions, lab$name, size_pt = 10,
                             panel_width_in = 6.5,
                             x_span = as.numeric(win[["xmax"]] - win[["xmin"]])))

## Label colour from the fill it sits on, not hard-coded.
fill_at <- colorRampPalette(tol_schemes$YlOrBr)(101)
lab$col <- contrast_text(fill_at[round(regions$rate * 100) + 1])

p_map +
  ## fits: centred inside the polygon, colour chosen from the fill beneath it
  geom_text(data = subset(lab, fits), aes(X, Y, label = name),
            size = pt(10), family = figure_family, fontface = "bold",
            color = subset(lab, fits)$col) +
  ## does not fit: pushed outside with a leader line back to the region centre
  geom_text_repel(data = subset(lab, !fits), aes(X, Y, label = name),
                  size = pt(10), family = figure_family, fontface = "bold",
                  color = figure_neutrals[["ink"]],
                  segment.color = figure_neutrals[["boundary"]],
                  segment.size = 0.4, min.segment.length = 0,
                  box.padding = 0.8, force = 8, seed = 42,
                  nudge_x = -1.2, nudge_y = -1.0)
```

### Leader lines and label placement

- `min.segment.length = 0` forces the leader line to draw even for short
  distances. Without it, a nudged label can end up floating with no connection.
- `nudge_x`/`nudge_y` give `ggrepel` a direction to push towards; on a map it
  has no empty space to find on its own, so aim it at the nearest quiet area.
- Pad the window enough that a displaced label lands inside the panel. That is
  cheaper than fighting the clipping.

### Label contrast and selection

- Label text on a dark polygon needs `contrast_text()` on the fill colour, the
  same as in-bar labels. Alternatively a halo:
  `geom_sf_label(..., fill = alpha("white", 0.7), label.size = 0)`.
- Label only the regions the argument depends on. `geom_sf_text(...,
  check_overlap = TRUE)` silently drops colliding labels, which is fine for a
  reference map and dangerous when a specific label matters — check the preview
  for what disappeared.

## Point maps

```r
p_points <- ggplot() +
  geom_sf(data = admin, fill = figure_neutrals[["land"]],
          color = figure_neutrals[["outline"]], linewidth = 0.2) +
  geom_sf(data = sites, aes(color = type, shape = type), size = 3, alpha = 0.85) +
  scale_color_manual(values = pal_okabe_ito(3)) +
  scale_shape_manual(values = c(16, 17, 15)) +
  coord_sf(expand = FALSE) +
  theme_figure_map(water = FALSE)
```

Basemap first, points last. Colour *and* shape, as everywhere else. For dense
points, `alpha = 0.4` and a smaller size, or aggregate to a hex grid — a
saturated blob of markers is not a map of anything.

## Projections

`coord_sf` reprojects on the fly; the underlying data does not change.

```r
coord_sf(crs = sf::st_crs(3857))                                  # web mercator
coord_sf(crs = sf::st_crs("+proj=laea +lat_0=0 +lon_0=20"))       # equal-area
```

Web Mercator inflates area with latitude, so any map where the reader might
compare region sizes — or where a choropleth's visual weight matters — should use
an equal-area projection suited to the extent. Note the projection in the caption
when it is not obvious.

Crop to an extent rather than filtering features, which would cut polygons
crossing the boundary:

```r
coord_sf(xlim = c(33.9, 41.9), ylim = c(-4.7, 5.5), expand = FALSE)
```

## Scale bar and north arrow

```r
if (requireNamespace("ggspatial", quietly = TRUE)) {
  p_map +
    ggspatial::annotation_scale(
      location = "bl", width_hint = 0.25, height = unit(0.15, "cm"),
      text_family = figure_family, text_cex = 0.7,
      line_col = figure_neutrals[["ink"]], text_col = figure_neutrals[["ink"]]) +
    ggspatial::annotation_north_arrow(
      location = "tr", height = unit(1.3, "cm"), width = unit(1.3, "cm"),
      pad_x = unit(0.3, "cm"), pad_y = unit(0.3, "cm"),
      style = ggspatial::north_arrow_minimal(
        line_col = figure_neutrals[["ink"]], text_col = figure_neutrals[["ink"]]))
}
```

A scale bar earns its space when distance matters. A north arrow on a
conventionally-oriented map of a familiar region is usually decoration — include
it for unfamiliar extents or rotated projections, skip it otherwise.

The unit arguments above are reference sizes; `save_figure()` scales physical
lengths with the overall figure. Custom annotation grobs may also contain
internal text or stroke sizes: inspect and adapt those explicitly. In particular, below about 1.2cm the north arrow collapses into an illegible
scribble, and either one placed in a corner that contains data will sit on top of
it. Check the preview for exactly this — invisible in the code, obvious in the
image.

## Insets

### Inset placement

When zooming to a subregion of a country, include a locator inset **inside an
open corner of the map**. It must show the full country and a square indicating
the zoomed area. Do not cover the featured region, marks, labels, water keys or
leader lines. Pick the corner by inspecting the rendered map; do not hard-code
the same corner for all extents. If no corner is free, enlarge the map window
to create an open corner before shrinking the inset or its labels.

### Locator geometry

Construct the locator square in the same suitable projected CRS used by both
maps: centre it on the region's bounding box, with side length equal to the
larger of that box's width and height, plus modest padding. Use that square as
the actual main-map viewing window where practical. Draw its outline without
fill in the locator so the indicated extent corresponds to the zoomed view.
Keep the full-country locator context and fallback base colours defined above;
data-driven or explicitly specified locator fills take precedence there too.

```r
bb <- sf::st_bbox(zoom_region)  # already transformed to a local projected CRS
cx <- mean(c(bb[["xmin"]], bb[["xmax"]]))
cy <- mean(c(bb[["ymin"]], bb[["ymax"]]))
half <- 0.55 * max(bb[["xmax"]] - bb[["xmin"]], bb[["ymax"]] - bb[["ymin"]])
zoom_box <- sf::st_as_sfc(sf::st_bbox(c(xmin = cx-half, ymin = cy-half,
                                     xmax = cx+half, ymax = cy+half),
                                   crs = sf::st_crs(zoom_region)))
locator <- locator + geom_sf(data = zoom_box, fill = NA,
                             color = figure_neutrals[["ink"]], linewidth = 0.5)
```

### Inset layout and styling

After choosing an unoccupied corner, place the inset (example coordinates only):

```r
library(patchwork)

main + inset_element(locator, left = 0.68, bottom = 0.02,
                     right = 0.99, top = 0.33)
```

Give the inset the same theme with `water = FALSE` and no legend, and outline it
so it reads as a separate frame:
`theme(plot.background = element_rect(color = figure_neutrals[["boundary"]], linewidth = 0.4))`.

## Aspect ratio and export size

`geom_sf` fixes the aspect ratio from the projection, so `width` and `height`
must roughly match the extent's shape or the figure gets bands of white space.
Check the bounding box before choosing dimensions:

```r
bb <- sf::st_bbox(regions)
ratio <- as.numeric((bb$ymax - bb$ymin) / (bb$xmax - bb$xmin))
save_figure(p_map, "map.png", width = 6.5, height = 6.5 * ratio + 1.0)
```

The `+ 1.0` is headroom for title, caption and a top legend; adjust from the
preview. The same arithmetic matters when composing a map beside another panel —
give the map the share of the width its aspect ratio needs via
`plot_layout(widths = )`, or it renders small inside a wide empty cell. See
`references/multi-panel.md`.

Maps are also where 800 dpi matters most: thin boundary lines and small place
labels are the first things to mush at lower resolutions.

## When sf is unavailable

Do not fall back to `maps`/`ggplot2::map_data` for anything analytical: the
built-in boundaries are coarse and out of date. Say that `sf` is required, and
offer a non-spatial alternative in the meantime — a ranked bar chart of the same
regional values usually answers the question more precisely than a small
choropleth does anyway.
