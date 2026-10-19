# Aspect ratio: median absolute slope banking

The default for plots with meaningful ordered line segments is median absolute
slope (MAS) banking to 45°. The style preamble supplies `bank_ratio()` and
`bank_plot()` for a single plot and `bank_panels()` for a composition. This is
the median-slope criterion, not mean slope or mean angle.

For displayed ranges Rx and Ry and median absolute segment slope M:

`panel height / panel width = Ry / (Rx * M)`.

This makes the median physical absolute slope 1. The reciprocal is the
width/height convention used in [Heer and Agrawala, section 2.2](https://jheer.org/publications/2006-Banking-InfoVis.pdf).

## Apply it to the actual display

### Plot types and eligible layers

- Select data-line layers only. For line charts, use consecutive observations
  in each drawn series. Pool segments from all displayed series by default,
  never connect groups. For a scatter with an explicitly requested fitted curve,
  bank that drawn curve; do not fit a curve merely to obtain an aspect ratio.
- Do not bank label leaders, error bars, reference lines or arbitrary connections
  between unordered observations. For clipped/zoomed line charts, first construct
  the actually visible segments, including intersections at the viewport edge;
  the helper does not clip line segments for you. `GeomStep` similarly requires
  an explicitly justified meaningful trend rather than its horizontal/vertical
  rendering segments.

### Displayed ranges and degenerate segments

- Use transformed axis coordinates and the final visible ranges, including zero,
  label headroom and scale expansion. `bank_plot()` builds the plot to obtain
  those values. If you change limits or expansion afterward, bank it again.
- Missing endpoints break adjacency. Horizontal segments count as zero slopes;
  vertical/undefined segments cannot provide finite slopes. A zero/nonfinite
  median or degenerate range has no finite banked ratio: report the fallback.

```r
# Both data layers are lines: grey peers and a highlighted product.
p <- bank_plot(p, layers = c(1, 2))
# p$theme$aspect.ratio is physical panel height / width, not file height / width.
```

## Export and composition

### Plot and export dimensions

Fix the destination width, subtract axes/margins/guide widths to find panel width,
then allocate `panel_width * ratio` for panel height. Add headings, tick labels,
axis titles, top legend and caption to obtain export height. `theme(aspect.ratio)`
preserves the panel ratio, but the wrong file dimensions can leave large blank
bands or shrink the panel. Inspect the final assembled export, including its
outermost ticks, and adjust file height rather than silently overriding banking.

### Shared panel ratios

**Do not bank the panels of a composition independently.** Use one common panel
width and height wherever practical. For each compatible line panel, normalise
segment slopes by its own displayed ranges: `abs(dy/dx) * Rx/Ry`. Pool these
normalised slopes across panels and take their median M; the common panel
height/width ratio is `1/M`. This allows different units without pooling raw
sales and revenue slopes. All panels use that same ratio, even though individual
panels will generally not have median physical slope 1. The pooled set does.

```r
panels <- bank_panels(list(p_units, p_revenue), layers = list(c(1, 2), c(1, 2)))
combined <- (panels[[1]] / panels[[2]]) + patchwork::plot_layout(heights = c(1, 1))
```

### Panel alignment and geometry

Align plot regions and reserve equal space for headings, legends and axis labels.
Centre headings over the full region including labels; align their baselines
within a row and their centre lines when stacked. Prefer equal dimensions over
separate optimal ratios. Fixed geographic projection, square heatmap cells and
explicit user dimensions take precedence; explain any necessary size difference
in a mixed-geometry composition rather than distorting a map.

### Fallbacks and user dimensions

When there are no meaningful segments (bars, categorical coefficient plots or
unordered scatter without a fitted curve), MAS is undefined. Use the readable
fallback dimensions in [style-guide.md](style-guide.md#sizing-design-at-the-final-printed-size) and record the reason. Never call that result
banked. Extreme finite ratios must be disclosed and reviewed, not silently
clamped; a required dimension or readability constraint may justify a documented
departure.
