# Multi-panel figures

Two different jobs get confused here, and picking the wrong one costs a lot of
fiddling:

- **Small multiples** — the *same* plot repeated over subsets of one dataset.
  Use `facet_wrap` / `facet_grid`. Scales, theme and legend are shared for free.
  See the faceting section of `core-plots.md`.
- **Composed figures** — *different* plots assembled into one labelled figure
  (panel A a map, B a time series, C a coefficient plot). Use `patchwork`.

Use faceting whenever it will do the job. Composition is for when the panels
genuinely answer different questions.

## Contents

- [patchwork basics](#patchwork-basics)
- [Panel headings and tags](#panel-headings-and-tags)
- [Theming a composition, and the version trap](#theming-a-composition-and-the-version-trap)
- [Shared legends](#shared-legends)
- [Shared scales](#shared-scales)
- [Alignment](#alignment)
- [Sizing a composed figure](#sizing-a-composed-figure)
- [When patchwork is unavailable](#when-patchwork-is-unavailable)

## patchwork basics

```r
library(patchwork)

(p_line | p_bar) / p_coef                    # two on top, one below
p_line + p_bar + p_coef + plot_layout(ncol = 2)
p_map | (p_line / p_bar)                     # nesting sets relative widths
```

- `|` places side by side, `/` stacks, `+` fills the `plot_layout` grid.
- Parentheses control nesting and therefore proportions — `p_map | (a / b)` gives
  the map half the width and stacks the other two in the remaining half.
- Uneven sizes: `plot_layout(widths = c(2, 1), heights = c(1, 1.4))`.
- Leave a cell empty with `plot_spacer()`.

## Panel headings and tags

### Descriptive headings and title versions

Give every composed panel a short descriptive heading, such as `Units sold`,
`Revenue (USD)`, `Adoption by region` or `Ranked adoption rates`. A letter alone
does not identify what a panel shows. Facet strips count as small-multiple
headings. In **no title** versions (the default for papers and presentations),
omit the composition's overall title, subtitle and caption, and remove subtitles
and footnotes from every panel. Supply explanatory and source text separately;
panel headings remain. **Title** versions are the default for other destinations.
User instructions override these defaults. The titled examples below illustrate
title versions; adapt their annotations for no title exports.

### Heading alignment and spacing

Use consistent heading size, weight, alignment and spacing throughout.
Centre each heading over the full plot region including the width of its axis
labels: `plot.title.position = "plot"` and `plot.title = element_text(hjust = 0.5)`.
Headings in one row must sit on the same baseline; stacked headings must share
a centre line. Reserve equal heading height if one title wraps.
Use identical title `vjust`, top/bottom margins and outer top margins across
the row; mixing `theme_void` and Cartesian defaults can shift title baselines.
Omit legend titles when panel headings are present; put essential units into headings/axes.

### Panel tags and captions

Let `patchwork` number panels separately, with tags placed above the headings
or in a separate margin position. Alternatively put `A. Units sold` into the
heading and omit automatic tags; never print the letter twice.

```r
(p_line | p_bar) / p_coef +
  plot_annotation(
    tag_levels = "A",
    tag_suffix = ".",
    title = "Programme effects across outcomes",
    caption = "Panel C shows 95% confidence intervals from OLS with controls."
  )
```

- Keep descriptive per-panel headings when tags are present. Ensure the tag
  and heading occupy different space; inspect the assembled figure for collisions.
- In title versions, use one caption on the composed figure instead of a caption
  per panel. In no title versions, supply the caption separately.
- Set the tag style through whichever theme route works on the installed
  patchwork (see below): `theme(plot.tag = element_text(face = "bold"))`.

## Theming a composition, and the version trap

Patchwork's documented idioms are `&` (apply a theme to **every** panel) and
`plot_annotation(theme = ...)` (style the composed figure's title, caption and
tags):

```r
(p_a | p_b) & theme(legend.position = "top")
(p_a | p_b) + plot_annotation(title = "T", theme = theme_figure())
```

**Historical compatibility note:** on patchwork 1.3.0 with ggplot2 4.0.0,
both idioms were broken. Check installed versions before applying this workaround. `&` and `*` error outright:

```
Error: Can't find method for generic `&(e1, e2)`: e1: <patchwork>, e2: <theme>
```

and `plot_annotation(theme = ...)` warns `annotation$theme is not a valid theme`
and silently ignores the theme, leaving the title in ggplot's default styling.
ggplot2 4.0 rebuilt themes on S7 and patchwork 1.3.0 predates it. `|`, `/`, `+`,
`plot_layout` and `plot_annotation`'s other arguments are unaffected.

A fallback for that combination is to set the theme globally, then
compose. `theme_set` styles both the panels and patchwork's annotation, because
the annotation falls back to the default theme.

```r
old_theme <- theme_set(
  theme_figure(base_size = 12, legend = "top") +
    theme(plot.tag = element_text(face = "bold", size = rel(1.05)))
)

combined <- (p_a | p_b) / p_c +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A", tag_suffix = ".",
                  title = "Programme effects across outcomes",
                  caption = "Panel C shows 95% confidence intervals.")

save_figure(combined, "figure2.png", width = 7, height = 7.5)
theme_set(old_theme)   # restore, so the global state doesn't leak
```

Use the global-theme fallback only for that historical version combination.
It does not replace a theme already attached to a component; set each component's
theme explicitly before composition when needed. Capture the old
theme and restore it, so sourcing the script doesn't change how unrelated plots
render later in the session.

Individual panels that need to differ (a map, a panel with no legend) still take
their own theme with `+`, which overrides the global default for that panel.

## Shared legends

Repeating the same legend three times wastes space and invites the reader to
think the panels use different encodings.

```r
old_theme <- theme_set(theme_figure(legend = "top"))
combined <- wrap_plots(list(p_a, p_b, p_c), nrow = 1) +
  plot_layout(guides = "collect")
theme_set(old_theme)
```

`guides = "collect"` gathers legends into one strip but only *merges* those that
are genuinely identical — same aesthetic, same labels, same scale. Two things
prevent merging, and both are easy to miss until you look at the render:

- **Different aesthetics.** A panel using `color`/`linetype` and a panel using
  `fill` for the same variable produce two legends side by side, however
  identical their labels. Map the same aesthetics in every panel — add a
  redundant `fill` or `color` with `guide = "none"` where a panel doesn't need
  it — or accept one legend and drop the other with `guides(fill = "none")`.
- **Different factor levels.** A category absent from one panel changes that
  panel's scale. Fix it by pinning the levels everywhere:

```r
scale_color_manual(values = group_colors, limits = names(group_colors),
                   drop = FALSE)
```

`drop = FALSE` also keeps a category in the legend when it is absent from one
panel, which is what makes the panels comparable.

## Shared scales

Faceting shares scales by default; composition does not. Panels that look
comparable but aren't are actively misleading, so set the limits explicitly:

```r
y_limits <- range(c(df_a$value, df_b$value))
p_a <- p_a + scale_y_continuous(limits = y_limits)
p_b <- p_b + scale_y_continuous(limits = y_limits)
```

Use `coord_cartesian(ylim = ...)` instead when you want to zoom without dropping
data — `scale_*_continuous(limits =)` removes out-of-range points and will
silently change fitted lines and summary statistics computed by geoms.

When panels genuinely cannot share a scale (different units, different orders of
magnitude), say so in the caption. The reader will otherwise assume they can
compare panel heights.

## Alignment

`patchwork` aligns panel regions, so axes line up even when tick labels differ
in width. Two things break it:

- **Different-length axis text** between stacked panels is handled; different
  *axis titles* are not always. Drop the redundant one:
  `p_top + labs(x = NULL) + theme(axis.text.x = element_blank())`.
- **A legend inside one panel** pushes its panel in. Collect the guides, or move
  the legend outside.

For stacked time series sharing an x-axis, remove the axis from all but the
bottom panel — but keep the axis *line*, since that is what marks the data
region once the grid is gone:

```r
strip_x <- theme(axis.title.x = element_blank(),
                 axis.text.x  = element_blank(),
                 axis.ticks.x = element_blank())
(p_top + strip_x) / (p_mid + strip_x) / p_bottom + plot_layout(heights = c(1, 1, 1))
```

Keep the actual panel heights equal; allocate axis-label space outside those
heights. Inspect the assembled result rather than assigning a larger data panel
to the bottom row to compensate for its labels.

### A map beside another panel

`geom_sf` fixes its own aspect ratio, so a map placed in an equal-width cell
renders small inside bands of white space while its neighbour fills the cell.

**Relative widths cannot solve this.** A relative share is resolved against the
row width, but the map panel sizes itself from the row *height* and its own
aspect ratio, so the two never agree and the result depends on the figure
dimensions. Give the map cell an absolute width instead, computed from the panel
height you are allocating, and let the other panel take what is left:

```r
bb    <- sf::st_bbox(regions)
ratio <- as.numeric((bb$ymax - bb$ymin) / (bb$xmax - bb$xmin))  # height / width

panel_height_in <- 4.6                      # row height minus title and caption
map_width_in    <- panel_height_in / ratio  # what the map actually needs

(p_map | p_bars) +
  plot_layout(widths = grid::unit(c(map_width_in, 1), c("in", "null")))
```

`unit(c(x, 1), c("in", "null"))` fixes the first cell at `x` inches and gives the
remainder to the second. That makes the geometry deterministic rather than a
function of the export size.

Then check the preview: if the map still floats in white space, the row is taller
than you assumed — lower `panel_height_in` or crop the extent tighter. A
map-only legend belongs above its map panel. Collect a legend above the whole
composition only when its encoding applies to all the panels. Keep it horizontal
and within the available width.

## Sizing a composed figure

### Composition scaling and fonts

Choose per-panel reference sizes, then export the whole composition through
`save_figure()`. Its single factor scales every panel and the overall annotations
together, including physical layout widths. For patchwork, do not scale component
plots before passing the composition to `save_figure()`: that applies the export
factor twice. The grob-based fallbacks below instead scale components once and
bypass scaling of the assembled result. The reference composition is 7 x 5.5in;
`base_size` applies per panel. A 2×2 composition at 7in wide gives each panel roughly 3.4in — so
`base_size = 14` in each panel yields text that is proportionally *larger* than
the same value on a single 7in figure. Either drop `base_size` by 1–2 points for
the panels, or accept slightly heavier type, but check the preview.

### Point sizes within panels

Size point markers for the space within each panel before assembling the
composition. Start with the standalone reference diameter multiplied by
`sqrt(panel_area / composition_area)`: for four equal cells, a 3.4mm coefficient
point becomes 1.7mm, a 3.7mm dot becomes 1.85mm, and a 2.2mm jitter point becomes
1.1mm. Reduce marker `stroke` by the same factor. Apply these sizes when creating
the panel's point/jitter layers; for mapped sizes, reduce the size scale's output
range (and its legend) instead. Use the same factor across comparable panels.
For unequal cells, use their allocated area fractions; facets follow the same
rule, counting the full grid including empty cells.

This is a starting point for marker sizing, not a reason to shrink all panel text
or confidence intervals. Keep labels readable and intervals visible, then check
for overlap and adjust for data density. `save_figure()` still applies the overall
export factor once, so the finished composition scales proportionally when resized.
Do not call `scale_figure()` on components to make this marker adjustment.

### Shared aspect ratio and fallback dimensions

For line/curve panels, compute one common MAS ratio with `bank_panels()` and
use equal data-panel sizes; do not optimise each panel independently. Align and
centre all headings; see `aspect-ratio.md`. The following are fallback sizes for
panels without bankable segments, not fixed aspect-ratio defaults:

| Reference layout at 7in wide | Height | Per-panel reference `base_size` |
|---|---|---|
| 1 × 2 (side by side) | 3.5 | 12 |
| 2 × 1 (stacked) | 7.0 | 13 |
| 2 × 2 | 7.5 | 12 |
| 3 × 1 stacked time series | 8.0 | 12 |
| map beside a bar chart | from the map aspect | 12 |

```r
# Build p_a ... p_d with descriptive headings and panel-sized point layers.
# For example: geom_point(size = 3.4 * sqrt(1/4), stroke = .5 * sqrt(1/4)).
panel_theme <- theme_figure(base_size = 12, legend = "top")
combined <- ((p_a + panel_theme) | (p_b + panel_theme)) /
            ((p_c + panel_theme) | (p_d + panel_theme)) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A", tag_suffix = ".", theme = panel_theme)
save_figure(combined, "figure2.png", width = 7, height = 7.5)
```

Render and look at the composition, not just the individual panels — collisions
between a panel's legend and its neighbour's axis are invisible in the code and
obvious in the preview.

## When patchwork is unavailable

`cowplot::plot_grid()` covers most of the same ground, but its embedded grobs
must be scaled before assembly. Choose panel-sized markers first, then apply the
whole-figure export factor to each component exactly once:

```r
panels <- lapply(list(p_a, p_b), scale_figure, width = 7, height = 5.5)
combined <- cowplot::plot_grid(plotlist = panels, align = "hv")
# Headings are already in each panel; avoid adding unscaled labels here.
save_figure(combined, "figure2.png", 7, 5.5, reference = NULL)
```

Failing both packages, print already-scaled components into a `grid` layout:

```r
# Direct device calls bypass save_figure(), so scale each component once here.
plots <- lapply(list(p_a, p_b, p_c, p_d), scale_figure, width = 7, height = 7.5)
if (requireNamespace("ragg", quietly = TRUE)) {
  ragg::agg_png("figure2.png", width = 7, height = 7.5, units = "in", res = 800, background = "white")
} else {
  png("figure2.png", width = 7, height = 7.5, units = "in", res = 800, bg = "white")
}
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
for (i in seq_along(plots)) {
  print(plots[[i]], newpage = FALSE, vp = grid::viewport(
    layout.pos.row = (i - 1) %/% 2 + 1, layout.pos.col = (i - 1) %% 2 + 1))
}
dev.off()
```

This does not align panel regions, so axes will not line up — acceptable for a
contact sheet used to review several figures at once, not for a published
figure. Say which one you produced.
