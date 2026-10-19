# Core plot templates

Every template assumes the helpers from [`scripts/style.R`](../scripts/style.R) have been pasted above
it (`theme_figure`, `pal_okabe_ito`, `okabe_ito`, `tol_schemes`,
`figure_neutrals`, `label_figure`, `axis_order`,
`contrast_text`, `pt`, `save_figure`). Data frames here are illustrative —
substitute the real data and keep the structure. Numeric text, point and stroke
sizes below describe the 7 x 5.5in reference figure. Export through `save_figure()`
or `preview_figure()` to scale them together with the output dimensions; do not
apply the export factor manually as well. When composing panels, first choose
smaller marker reference sizes using [multi-panel sizing](multi-panel.md#sizing-a-composed-figure);
the facet template below already includes that panel adjustment.

Apply the **title** / **no title** rules in [`SKILL.md`](../SKILL.md) to every template:
papers and presentations default to no title; other destinations default to
title, unless the user specifies otherwise. Remove overall titles, subtitles,
captions and footnotes from no title exports and supply that text separately.

Because `theme_figure` draws no internal grid, every template labels its values
directly or relies on ticks and a clean axis line. That is deliberate: a reader
recovering a number from a label is more accurate than one sighting along a grid
line.

## Choosing a plot type

Pick the encoding from what the reader has to do:

| The reader needs to | Use |
|---|---|
| Follow a value over time or an ordered sequence | Line, with points at observations |
| Follow one named product/group while retaining peers as context | One shared trend panel per metric; highlight that group and mute peers |
| Compare a value across a handful of named categories | Horizontal bars from zero, sorted |
| Compare two groups across categories | Dodged horizontal bars |
| Judge an estimate against zero or a null | Coefficient plot with intervals |
| Compare several estimates of the same outcome | Coefficient plot, dodged within outcome |
| See one case against its peers | Ranked bars, one highlighted, rest grey |
| Judge a relationship between two continuous variables | Scatter, fit only if it means something |
| See a distribution shape | Histogram or density |
| Compare distributions across groups | Box or violin with the raw points |
| Read one value from a two-way grid | Square-tile heatmap with a Tol scheme |
| Compare many small series | Faceted small multiples, shared scales |
| See composition | Stacked proportion bars, or better, plot the share directly |

## Contents

- [Line / trend](#line--trend)
- [One focal series with peer context](#one-focal-series-with-peer-context)
- [Grouped horizontal bars with value labels](#grouped-horizontal-bars-with-value-labels)
- [Coefficient plot, one estimate per outcome](#coefficient-plot-one-estimate-per-outcome)
- [Coefficient plot, several estimates per outcome](#coefficient-plot-several-estimates-per-outcome)
- [Ranked bars with one highlighted](#ranked-bars-with-one-highlighted)
- [Scatter with fitted line](#scatter-with-fitted-line)
- [Distributions: box / violin with points](#distributions-box--violin-with-points)
- [Histogram and density](#histogram-and-density)
- [Heatmap / square tiles](#heatmap--square-tiles)
- [Cleveland dot plot](#cleveland-dot-plot)
- [Stacked proportion bars](#stacked-proportion-bars)
- [Faceted small multiples](#faceted-small-multiples)
- [Labelled scatter with ggrepel](#labelled-scatter-with-ggrepel)

---

## Line / trend

Colour plus `linetype` is the redundant encoding that keeps this readable in
greyscale. Points mark actual observations, so the reader can tell interpolation
from data.

```r
trend <- data.frame(
  wave  = rep(1:5, 2),
  group = factor(rep(c("Comparison", "Programme"), each = 5),
                 levels = c("Comparison", "Programme")),
  value = c(40, 43, 42, 47, 49, 40, 46, 51, 57, 62)
)

## Blue and vermillion: the most separable pair under colour-vision deficiency,
## both clear 3:1 contrast on white, which thin lines and small points need.
## Orange and sky blue are fills-only.
group_colors <- c(Comparison = okabe_ito[["vermillion"]],
                  Programme  = okabe_ito[["blue"]])

p_line <- ggplot(trend, aes(wave, value, color = group, linetype = group)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3) +
  scale_color_manual(values = group_colors, guide = legend_figure()) +
  scale_linetype_manual(values = c(Comparison = "dashed", Programme = "solid"), guide = legend_figure()) +
  scale_x_continuous(breaks = 1:5) +
  scale_y_continuous(breaks = breaks_with_zero(), labels = label_axis) +
  labs(x = "Survey wave", y = "Outcome (units)") +
  theme_figure()
p_line <- bank_plot(p_line, layers = 1)
```

Both axes carry values here, so the default `ticks = "both"` is right.

**Label the lines directly** instead of using a legend when there is room at the
right edge — it removes a lookup step and survives being cropped. Note the
`expand` on the x scale: without the extra 22% the labels are clipped. Build
this as one plot rather than adding a second `scale_x_continuous` to `p_line`,
which would replace the first and emit a warning.

```r
ends <- subset(trend, wave == max(wave))

p_line_direct <- ggplot(trend, aes(wave, value, color = group, linetype = group)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3) +
  geom_text(data = ends, aes(label = group), hjust = 0, nudge_x = 0.12,
            size = pt(11), fontface = "bold", color = figure_neutrals[["ink"]],
            show.legend = FALSE) +
  scale_color_manual(values = group_colors, guide = legend_figure()) +
  scale_linetype_manual(values = c(Comparison = "dashed", Programme = "solid"), guide = legend_figure()) +
  scale_x_continuous(breaks = 1:5, expand = expansion(mult = c(0.03, 0.22))) +
  labs(x = "Survey wave", y = "Outcome (units)") +
  theme_figure(legend = "none")
p_line_direct <- bank_plot(p_line_direct, layers = 1)
```

Direct labels inherit the series colour if you map them, which is what makes
them work — but orange, yellow and sky blue fall below 3:1 on white and go mushy
as 10pt text. A colour scale applies to every layer that maps it, so you cannot
darken only the text within one scale. Two clean options:

```r
# (a) let the line carry the colour and set the text to ink (used above)
geom_text(data = ends, aes(label = group), color = figure_neutrals[["ink"]], ...)

# (b) pre-darken the label colour in the data, then use it unmapped
ends$label_color <- colorspace::darken(group_colors[as.character(ends$group)], 0.3)
geom_text(data = ends, aes(label = group), color = ends$label_color, ...)
```

**Uncertainty band**: draw the ribbon first so lines sit on top of it. Keep it
in the series colour at `alpha = 0.28` and out of the legend. Check that the
band remains visible at final size, including where bands overlap.

```r
geom_ribbon(aes(ymin = lower, ymax = upper, fill = group), alpha = 0.28,
            color = NA, show.legend = FALSE) +
  scale_fill_manual(values = group_colors)
```

**Dates**: `scale_x_date(date_breaks = "1 year", date_labels = "%Y")`. For long
axes, dropping to every second break is cleaner than rotating labels.

---

## One focal series with peer context

When a request focuses on one named product/group and asks how it compares with
peers over time, keep all series in a shared panel for each metric. Draw peers
first in subdued neutral colours and the focal series last in the accent colour.
Map colour to the product identity with a named palette, keeping that identity
consistent across metrics; only the focal series should visually stand out.
Do not automatically facet by product because there are more than seven series:
the focus-and-context comparison avoids the need for nine saturated colours.

Use direct endpoint labels (or a compact legend when they cannot fit), with a
bold label for the focal series so the emphasis survives greyscale. Keep the
underlying values unchanged, retain all peers, and put distinct units in separate
panels with descriptive headings. A request for "Product 5 in the context of the
others" expresses an analytical focus; it need not prescribe these visual details.
Use black indicator lines for grey peers, with their colour set explicitly rather
than inherited. Use `bank_panels()` to calculate one common ratio for all metric
panels from their range-normalised data segments, excluding indicator lines.

## Grouped horizontal bars with value labels

Horizontal bars give category names room without rotation. The critical detail
is that bars and their labels must share one `position_dodge` object and the same
`group` mapping, or the labels drift off their bars.

```r
bars <- data.frame(
  category = rep(c("Activity A", "Activity B", "Activity C"), 2),
  group = factor(rep(c("Comparison", "Programme"), each = 3),
                 levels = c("Comparison", "Programme")),
  share = c(0.32, 0.22, 0.12, 0.43, 0.30, 0.18)
)
## Activity A at the top, reading downwards.
bars$category <- axis_order(bars$category,
                            c("Activity A", "Activity B", "Activity C"), axis = "y")

## reverse = TRUE puts the first group at the top of each pair, matching the
## reading order of the legend.
dodge <- position_dodge(width = 0.70, orientation = "y", reverse = TRUE)

p_bar <- ggplot(bars, aes(share, category, fill = group, group = group)) +
  geom_col(width = 0.62, position = dodge) +
  geom_text(aes(label = label_percent(accuracy = 1)(share)),
            position = dodge, hjust = -0.18, size = pt(11),
            family = figure_family, color = figure_neutrals[["ink"]]) +
  scale_fill_manual(values = pal_okabe_ito(2), guide = legend_figure()) +
  scale_x_continuous(limits = c(0, NA), breaks = breaks_with_zero(),
                     labels = function(x) label_axis(x, label_percent(accuracy = 1)),
                     expand = expansion(mult = c(0, 0.20))) +
  labs(x = "Share within group (%)", y = NULL) +
  theme_figure(ticks = "x") +
  theme(axis.text.y = element_text(face = "bold"))
```

Notes that matter:

### Axes and baselines

- **Bars must include zero.** `limits = c(0, NA)` states it explicitly rather
  than relying on the default. Bar length *is* the quantity, so a cut baseline
  exaggerates differences; if the interesting variation sits in a narrow range
  well above zero, switch to a dot plot where position carries the value.
- `ticks = "x"` because the values are on x; the category labels sit against the
  y axis line and need no ticks.

### Value labels and precision

- `expand = expansion(mult = c(0, 0.20))` is what stops the outermost value
  label from being clipped. Rather than guessing the number, compute it from the
  longest label and the panel width:

  ```r
  pad <- label_headroom(label_percent(accuracy = 1)(bars$share),
                        size_pt = 11, panel_width_in = 4.0)
  scale_x_continuous(limits = c(0, NA), expand = expansion(mult = c(0, pad)))
  ```

  Then check the preview. If labels are clipped, wrap them or reserve more
  internal space. Widen the figure only when the destination allows it; keep
  a mandated column width fixed.
- Match `accuracy` to the precision the data supports. `accuracy = 0.1` on
  values rounded to whole percents prints "43.0%", claiming a decimal place that
  is not there. For unformatted numbers use `label_figure()`, which applies the
  house rounding rule across the whole set at once.

### Bars with error bars

Dodge the bars and the intervals by the same width. The detail that catches
people out is the **value label**: anchored to the end of the bar it lands on top
of the interval, because the interval extends past the bar. Anchor it to the top
of the interval instead.

```r
bars$upper <- bars$share + 1.96 * bars$se
dodge <- position_dodge(width = 0.70, orientation = "y", reverse = TRUE)

ggplot(bars, aes(share, category, fill = group, group = group)) +
  geom_col(width = 0.6, position = dodge) +
  geom_errorbar(aes(xmin = share - 1.96 * se, xmax = upper),
                position = dodge, orientation = "y",
                width = 0.14, linewidth = 0.7,
                color = "#000000") +
  ## label anchored to `upper`, not to `share`, so it clears the interval
  geom_text(aes(x = upper, label = label_figure(share)), position = dodge,
            hjust = -0.2, size = pt(11), family = figure_family) +
  scale_x_continuous(limits = c(0, NA), breaks = breaks_with_zero(), labels = label_axis,
                     expand = expansion(mult = c(0, 0.22))) +
  labs(x = "Share within group (%)", y = NULL) +
  theme_figure(ticks = "x")
```

Widen the `expand` when you do this — the label now starts further right, so it
needs more headroom than a bare bar would. And once a bar carries both an
interval and a label, consider whether the value axis is still earning its
space: labels plus ticks plus an interval is a lot of numbers.

For vertical bars, swap the aesthetics and use `theme_figure(ticks = "y")` with
`scale_y_continuous(limits = c(0, NA))`.

---

## Coefficient plot, one estimate per outcome

Four things distinguish a good coefficient plot:

1. The reference line at zero reads as **structure** (dashed, charcoal) and is
   drawn **first**, so it sits behind the estimates.
2. Value labels sit **above their own points**, centred horizontally on the
   estimates. Allocate enough vertical space to clear the point/interval above.
3. Make **both the point and interval visible**. Use `linewidth = 0.7`,
   visible T-shaped end caps and full-opacity series colours. Check at least
   3:1 contrast against the background; use black for intervals over bar fills.
4. Outcomes are ordered deliberately, first at the top.

```r
outcomes <- c("Outcome A", "Outcome B", "Outcome C")
effects <- data.frame(
  outcome  = axis_order(outcomes, outcomes, axis = "y"),
  estimate = c(0.184, 0.092, -0.041),
  lower    = c(0.081, -0.024, -0.121),
  upper    = c(0.287, 0.201, 0.039)
)

p_coef <- ggplot(effects, aes(estimate, outcome)) +
  geom_vline(xintercept = 0, color = figure_neutrals[["charcoal"]],
             linetype = "dashed", linewidth = 0.6) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = 0.14, linewidth = 0.7,
                color = okabe_ito[["blue"]]) +
  geom_point(size = 3.4, color = okabe_ito[["blue"]]) +
  geom_text(aes(label = label_figure(estimate)), vjust = -0.8,
            size = pt(10), family = figure_family) +
  scale_x_continuous(limits = zero_limits(c(effects$lower, effects$upper)),
                     breaks = breaks_with_zero(), labels = label_axis,
                     expand = expansion(mult = c(0.04, 0.08))) +
  scale_y_discrete(expand = expansion(add = c(0.5, 0.8))) +
  labs(x = "Effect (standard deviations)", y = NULL) +
  theme_figure(ticks = "x") +
  theme(axis.text.y = element_text(face = "bold"))
```

- `width = 0.14` gives T caps on a discrete row scale. Keep caps shorter than
  the gap between adjacent estimates; use the same width across like figures.
- Labels stay above points. Add height and top-row headroom before increasing
  their upward offset; moving a label farther up can collide with the row above.
- State in the caption what the interval is and where it came from — an interval
  without a stated method is not interpretable.
- Do not colour or annotate by significance threshold unless asked; it invites
  reading the figure as a verdict rather than an estimate.

---

## Coefficient plot, several estimates per outcome

When the same outcome carries several estimates — treatment arms, specifications,
subgroups — they belong on **one row per outcome**, sharing a single y-axis
label, distinguished from each other by colour *and* shape.

The spacing rule that makes this readable: the gap between estimates within an
outcome must be visibly smaller than the gap between outcomes, so the eye groups
them correctly. Since ggplot spaces discrete categories one unit apart, any
`position_dodge(width < 1)` achieves this — `0.75` with three series leaves
0.25 between estimates and 0.50 between outcomes. Physical label clearance also
depends on figure height: allocate about 0.4in per estimate plus axes/legend space
and inspect at final size. Do not assume the dodge width alone prevents overlap.

```r
models <- c("OLS", "Instrumented", "With controls")
pal <- setNames(pal_okabe_ito(3), models)
outcomes <- c("Outcome A", "Outcome B", "Outcome C")

multi <- data.frame(
  outcome  = rep(outcomes, each = 3),
  model    = factor(rep(models, 3), levels = models),
  estimate = c(0.184, 0.152, 0.201, 0.092, 0.071, 0.110, -0.041, -0.062, -0.028),
  se       = c(0.052, 0.061, 0.048, 0.058, 0.066, 0.055, 0.041, 0.049, 0.038)
)
multi$lower <- multi$estimate - 1.96 * multi$se
multi$upper <- multi$estimate + 1.96 * multi$se
multi$outcome <- axis_order(multi$outcome, outcomes, axis = "y")

## Interval colour as an unmapped column, NOT a second colour scale. A single
## colour scale is what lets colour and shape merge into one legend; adding
## extra values to the scale produces two legends side by side.
multi$ci_color <- unname(pal[as.character(multi$model)])

## reverse = TRUE so the first model sits at the TOP of each outcome group,
## matching the reading order of the legend.
dodge <- position_dodge(width = 0.75, orientation = "y", reverse = TRUE)

p_coef_multi <- ggplot(multi, aes(estimate, outcome, group = model)) +
  geom_vline(xintercept = 0, color = figure_neutrals[["charcoal"]],
             linetype = "dashed", linewidth = 0.6) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                position = dodge, width = 0.14, linewidth = 0.7,
                color = multi$ci_color) +
  geom_point(aes(color = model, shape = model), position = dodge, size = 3.3) +
  geom_text(aes(label = label_figure(estimate)), position = dodge,
            vjust = -0.8, size = pt(9.5), family = figure_family) +
  scale_color_manual(values = pal, guide = legend_figure()) +
  scale_shape_manual(values = c(16, 17, 15), guide = legend_figure()) +
  scale_x_continuous(limits = zero_limits(c(multi$lower, multi$upper)),
                     breaks = breaks_with_zero(), labels = label_axis,
                     expand = expansion(mult = c(0.04, 0.08))) +
  scale_y_discrete(expand = expansion(add = c(0.5, 0.8))) +
  labs(x = "Effect (standard deviations)", y = NULL) +
  theme_figure(ticks = "x") +
  theme(axis.text.y = element_text(face = "bold"))

save_figure(p_coef_multi, "coefficients.png", width = 7, height = 5.4)
```

Things that go wrong here, all of which the preview catches:

### Legends and series order

- **Two legends.** Caused by the colour and shape scales having different sets
  of keys. Keep one colour scale over the model levels only, and pass the
  interval colour unmapped as above.
- **Series order inverted.** Without `reverse = TRUE` the first model lands at
  the bottom of each group while the legend lists it first.

### Colours and shapes

- Shapes: `c(16, 17, 15, 18)` (filled circle, triangle, square, diamond). Filled
  shapes read better than open ones at small sizes.
- Keep one model pinned to one colour and shape across every figure in the
  document.

### Label spacing and plot height

- **Labels overlapping the next estimate.** Give the figure roughly 0.4in of
  height per estimate drawn plus axes and legend space; nine estimates want about 5.4in.

---

## Ranked bars with one highlighted

One colour against grey is the most legible way to answer "where does this one
sit?". The `guide = "none"` matters: a legend for TRUE/FALSE is noise.

```r
programmes <- c("Programme A", "Focus programme", "Programme B")
ranking <- data.frame(
  programme = axis_order(programmes, programmes, axis = "y"),
  ratio = c(2.3, 1.6, 0.8)
)
ranking$focus <- ranking$programme == "Focus programme"

p_rank <- ggplot(ranking, aes(ratio, programme)) +
  # Reference line FIRST: layers paint in the order they are added, so putting
  # geom_vline after geom_col slices a dashed line across every bar.
  geom_vline(xintercept = 1, color = figure_neutrals[["charcoal"]],
             linewidth = 0.6, linetype = "dashed") +
  geom_col(aes(fill = focus, color = focus), width = 0.62, linewidth = 0.5) +
  geom_text(aes(label = label_figure(ratio)), hjust = -0.2,
            size = pt(11), family = figure_family) +
  scale_fill_manual(values = c(`FALSE` = figure_neutrals[["muted"]],
                               `TRUE`  = okabe_ito[["blue"]]), guide = "none") +
  scale_color_manual(values = c(`FALSE` = figure_neutrals[["muted_line"]],
                                `TRUE`  = okabe_ito[["blue"]]), guide = "none") +
  scale_x_continuous(limits = c(0, NA), breaks = breaks_with_zero(), labels = label_axis,
                     expand = expansion(mult = c(0, 0.20))) +
  labs(subtitle = "Dashed line marks break-even",
       x = "Benefit-cost ratio", y = NULL) +
  theme_figure(ticks = "x", legend = "none") +
  theme(axis.text.y = element_text(face = "bold"))
```

The border on the grey bars (`color = muted_line`) keeps pale fills from
dissolving into the background. Annotate the reference line in the subtitle
rather than leaving the reader to guess what `1` means — and for a no title
version, hand that sentence over as separate caption or slide copy instead of
rendering it. If a value label
lands on the reference line, nudge it or move it inside the bar.

---

## Scatter with fitted line

Both numeric axes start at zero by default for nonnegative data. When both do,
remove both zero ticks and their ordinary labels, and place one zero diagonally outside
the common corner. Keep negative data visible when present and label zero on
each axis that contains it; add the relevant dashed grey reference line.

```r
p_scatter <- ggplot(mtcars, aes(wt, mpg)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              color = figure_neutrals[["charcoal"]],
              fill = okabe_ito[["blue"]], alpha = 0.28, linewidth = 1.0) +
  geom_point(size = 3, alpha = 0.8, color = okabe_ito[["blue"]]) +
  scale_x_continuous(limits = c(0, NA), breaks = function(limits) setdiff(breaks_with_zero()(limits), 0),
                     labels = label_axis,
                     expand = expansion(mult = c(0, 0.05))) +
  scale_y_continuous(limits = c(0, NA), breaks = function(limits) setdiff(breaks_with_zero()(limits), 0),
                     labels = label_axis,
                     expand = expansion(mult = c(0, 0.05))) +
  annotate("text", x = 0, y = 0, label = "0", hjust = 1.4, vjust = 1.4,
           size = pt(11), family = figure_family) +
  coord_cartesian(clip = "off") +
  labs(x = "Weight (1,000 lbs)", y = "Fuel economy (mpg)") +
  theme_figure()
p_scatter <- bank_plot(p_scatter, layers = 1)  # bank the drawn fitted curve
```

- Add a fit only when a model is being claimed. `geom_smooth()` defaults to a
  loess curve, which reads as a finding but is only a smoother — always state
  `method` explicitly so the code says what it is.
- Groups: map `color` **and** `shape` so they separate in greyscale.
- Dense data: `alpha = 0.25` and `size = 1.7`; past a few thousand points switch
  to `geom_hex(bins = 40)` or `geom_density_2d`, since a saturated cloud shows
  neither the mass nor the outliers.
- Never let a fit extend past the data range — it implies extrapolation you have
  not tested. `fullrange = FALSE` is the default; keep it.

---

## Distributions: box / violin with points

Show the raw points whenever n is small enough to plot; a box plot of 6
observations hides that it is 6 observations.

```r
p_box <- ggplot(iris, aes(Species, Petal.Length, fill = Species)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.35, linewidth = 0.5,
               color = figure_neutrals[["ink"]], width = 0.55) +
  geom_jitter(aes(color = Species), width = 0.12, height = 0,
              size = 2.2, alpha = 0.7, show.legend = FALSE) +
  scale_fill_manual(values = pal_okabe_ito(3), guide = "none") +
  scale_color_manual(values = pal_okabe_ito(3)) +
  labs(x = NULL, y = "Petal length (cm)") +
  theme_figure(ticks = "y", legend = "none")
```

- `outlier.shape = NA` prevents outliers appearing twice once points are drawn.
- `height = 0` in `geom_jitter` — jittering the value axis moves the data.
- Grouped: `position_jitterdodge(jitter.width = 0.15, dodge.width = 0.75)` on
  the points and `position_dodge(width = 0.75)` on the boxes.
- Above a few hundred points, drop the points for a violin, or a violin with a
  narrow box inside (`geom_violin(width = 0.8) + geom_boxplot(width = 0.12)`).
- Report n per group in the caption or the axis labels; a distribution plot
  without n invites over-reading.

---

## Histogram and density

```r
p_hist <- ggplot(faithful, aes(waiting)) +
  geom_histogram(binwidth = 3, fill = okabe_ito[["blue"]], color = "white",
                 linewidth = 0.3) +
  scale_y_continuous(limits = c(0, NA), breaks = breaks_with_zero(), labels = label_axis) +
  labs(x = "Waiting time (minutes)", y = "Eruptions") +
  theme_figure()
```

Always set `binwidth` deliberately and state it — the default 30 bins is a
placeholder, and bin width changes the shape of the story. Bars start at zero
here for the same reason they do everywhere else. For comparing a few
distributions, overlaid densities beat overlaid histograms:

```r
geom_density(aes(color = group, fill = group), alpha = 0.15, linewidth = 0.9)
```

Densities of bounded variables (proportions, counts, ages) leak past the bound;
either clip with `coord_cartesian(xlim = ...)` or use a histogram.

---

## Heatmap / square tiles

Cells should be **square**: an unequal aspect ratio makes the same value look
different depending on where it sits, and a square grid signals that rows and
columns are equally weighted. `coord_fixed()` does it.

```r
months  <- month.abb[1:6]
regions <- paste("Region", 1:6)

grid_df <- expand.grid(month = months, region = regions)
grid_df$share <- runif(nrow(grid_df), 0.05, 0.95)
grid_df$month  <- axis_order(grid_df$month, months, axis = "x")
grid_df$region <- axis_order(grid_df$region, regions, axis = "y")

## Legend runs to a round ceiling chosen from the data, not to the data max.
fill_scale <- share_scale(grid_df$share)

## after_scale() uses the actual rendered fill, including limits and NA colours.
p_tile <- ggplot(grid_df, aes(month, region, fill = share)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = label_figure(share),
                colour = after_scale(contrast_text(fill))),
            size = pt(9), family = figure_family) +
  scale_fill_gradientn(colours = tol_schemes$YlOrBr,
                       na.value = tol_bad[["YlOrBr"]],
                       limits = fill_scale$limits, breaks = fill_scale$breaks,
                       labels = fill_scale$labels, name = "Share adopting") +
  scale_x_discrete(expand = expansion(0)) +
  scale_y_discrete(expand = expansion(0)) +
  coord_fixed() +
  labs(x = NULL, y = NULL) +
  theme_figure(legend = "top", legend_title = TRUE, ticks = "none") +
  guides(fill = guide_colourbar(theme = theme(
    legend.key.width = unit(2.8, "in"), legend.key.height = unit(0.12, "in")))) +
  theme(legend.title.position = "top")
```

### Legends and breaks

- **Legend width**: the 2.8in colourbar leaves room for the six low-range
  labels at this template's default text size. Adjust it to the actual panel
  width and inspect the legend when changing size or label precision.
- **Legend breaks**: `share_scale()` runs the legend from zero to a round ceiling
  chosen from the data (0.25, 0.5 or 1), so the reader sees a full scale rather
  than the range this sample happened to cover — without collapsing low-valued
  data into two bins. Non-proportion variables keep the principle: fixed, evenly
  spaced breaks including both ends, from `breaks_pretty()` or `breaks_width()`.

### Colours and missing values

- **Sequential vs diverging**: diverging (`sunset`, `BuRd`) only when zero or
  another value is a real midpoint, with
  `rescaler = ~ rescale_mid(.x, mid = 0)`. Otherwise sequential (`YlOrBr`,
  `iridescent`), which is monotonic in lightness and so survives greyscale.
- A **binned** scale (`scale_fill_stepsn`) is easier to read off than a gradient,
  because the reader matches a swatch instead of interpolating.
- `na.value = tol_bad[[...]]` so missing cells never read as low values.

### Tile order, borders and axes

- Order rows and columns meaningfully. An alphabetical heatmap hides its own
  structure.
- White tile borders separate cells without adding a grid, and `ticks = "none"`
  because the tiles themselves mark the categories.

---

## Cleveland dot plot

The right answer whenever the interesting variation is small relative to the
values, since position does the work and no baseline is implied — this is the
chart to offer when someone asks for a bar chart that does not start at zero.

This does not override the house rule for coefficient plots: they include zero
unless the user explicitly requests another range. Offer a zoom; do not silently
apply one to a coefficient/scatter plot just because differences are small.

```r
items <- c("Item A", "Item B", "Item C", "Item D")
dots <- data.frame(item = items, value = c(72.4, 74.1, 69.8, 75.2))
## No natural order, so rank by value: largest at the top.
dots$item <- axis_order(dots$item, items[order(-dots$value)], axis = "y")

p_dot <- ggplot(dots, aes(value, item)) +
  geom_segment(aes(x = min(value) - 1, xend = value, yend = item),
               color = figure_neutrals[["muted"]], linewidth = 1.4) +
  geom_point(size = 3.7, color = okabe_ito[["blue"]]) +
  geom_text(aes(label = label_figure(value)), hjust = -0.35,
            size = pt(11), family = figure_family) +
  scale_x_continuous(breaks = breaks_with_zero(), labels = label_axis,
                     expand = expansion(mult = c(0.02, 0.14))) +
  labs(x = "Value (units)", y = NULL) +
  theme_figure(ticks = "x")
```

For before/after or two-group comparisons, a dumbbell: one `geom_segment`
joining the pair, then a point per group in its palette colour.

---

## Stacked proportion bars

Legitimate for composition, but only the bottom segment can be compared across
bars. If the question is about a specific category, plot that share directly.

The in-segment labels are what usually goes wrong: white bold text is legible on
dark blue and illegible on light grey or sky blue. Compute the label colour from
the fill instead of picking one for all segments — `contrast_text()` returns dark
`ink` for every Okabe-Ito fill except blue and black.

```r
status_fills <- c(Adopted = okabe_ito[["blue"]],
                  Partial = okabe_ito[["skyblue"]],
                  None    = figure_neutrals[["muted"]])
regions <- c("North", "Central", "South")   # cardinal order: north at the top

comp <- data.frame(
  region = rep(regions, each = 3),
  status = factor(rep(c("Adopted", "Partial", "None"), 3),
                  levels = c("None", "Partial", "Adopted")),
  share  = c(0.50, 0.30, 0.20, 0.40, 0.35, 0.25, 0.25, 0.30, 0.45)
)
comp$region <- axis_order(comp$region, regions, axis = "y")
comp$label_color <- contrast_text(status_fills[as.character(comp$status)])

p_stack <- ggplot(comp, aes(share, region, fill = status)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = label_percent(accuracy = 1)(share)),
            position = position_stack(vjust = 0.5), size = pt(10),
            color = comp$label_color, fontface = "bold",
            family = figure_family) +
  scale_fill_manual(values = status_fills, guide = legend_figure()) +
  scale_x_continuous(limits = c(0, NA), breaks = breaks_with_zero(),
                     labels = function(x) label_axis(x, label_percent()), expand = expansion(mult = c(0, .04))) +
  labs(x = "Share (%)", y = NULL) +
  theme_figure(ticks = "x")
```

- Order the stack so the category of interest sits at the shared baseline.
- Ordered categories (none → partial → full) suit a sequential ramp of one hue
  better than separate hues; the ordering then lives in the colour itself.
- If a segment is too narrow for its label, drop the label rather than shrink the
  text below 7pt:
  `aes(label = ifelse(share > 0.08, label_percent()(share), ""))`.

---

## Faceted small multiples

Often the honest answer to "too many series", and the recommended fix once a
figure would need seven or more colours. Shared scales are what make panels
comparable — `scales = "free_y"` quietly forbids cross-panel comparison, so use
it only when the panels genuinely are not comparable, and say so in the caption.

```r
# Two columns; include empty cells when sizing markers for the panel grid.
facet_cells <- 2 * ceiling(length(unique(trend$group)) / 2)
p_facet <- ggplot(trend, aes(wave, value)) +
  geom_line(linewidth = 0.9, color = okabe_ito[["blue"]]) +
  geom_point(size = 3 / sqrt(facet_cells), stroke = .5 / sqrt(facet_cells),
             color = okabe_ito[["blue"]]) +
  facet_wrap(~ group, ncol = 2) +
  ## Regular intervals. `seq()` or a breaks_* rule, never a hand-picked vector
  ## like c(1, 4, 8), whose uneven gaps read as if they meant something.
  scale_x_continuous(breaks = seq(1, 5, by = 1)) +
  labs(x = "Survey wave", y = "Outcome (units)") +
  theme_figure(legend = "none")
```

- Sort panels by a meaningful quantity, not alphabetically:
  `facet_wrap(~ fct_reorder(group, value, .fun = max, .desc = TRUE))`.
- Grow the figure height with the number of rows (roughly 1.6in per row plus 1in
  of chrome) rather than squeezing panels.
- Colour is redundant with the strip label when faceting by group — drop the
  legend and use one colour, or keep colour and drop the strips.
- A faint grey copy of all series behind each panel gives the reader a reference:
  add a second `geom_line` with the facet variable removed from its data, in
  `figure_neutrals[["muted"]]`, drawn first.

---

## Labelled scatter with ggrepel

Apply the zero-baseline and origin-label rules from the scatter section above:
both numeric ranges include zero by default, and a wholly nonnegative region
has one shared corner label. Labels are not a reason to truncate either axis.

```r
library(ggrepel)

xr <- zero_limits(df$x)
yr <- zero_limits(df$y)
shared_origin <- xr[1] == 0 && yr[1] == 0
scatter_breaks <- function(limits) {
  b <- breaks_with_zero()(limits)
  if (shared_origin) setdiff(b, 0) else b
}
scatter_labels <- function(x) {
  out <- label_axis(x)
  if (shared_origin) out[x == 0 & !is.na(x)] <- ""
  out
}
p_labelled <- ggplot(df, aes(x, y)) +
  {if (xr[1] < 0 && xr[2] > 0) geom_vline(xintercept = 0,
     color = figure_neutrals[["charcoal"]], linetype = "dashed", linewidth = 0.45)} +
  {if (yr[1] < 0 && yr[2] > 0) geom_hline(yintercept = 0,
     color = figure_neutrals[["charcoal"]], linetype = "dashed", linewidth = 0.45)} +
  geom_point(size = 3.2, color = okabe_ito[["blue"]], alpha = 0.85) +
  geom_text_repel(aes(label = name), size = pt(10), family = figure_family,
                  color = figure_neutrals[["ink"]],
                  max.overlaps = 12, box.padding = 0.4, point.padding = 0.25,
                  min.segment.length = 0.15, force = 2,
                  segment.color = "#000000",
                  segment.size = 0.3, seed = 42) +
  scale_x_continuous(limits = xr, breaks = scatter_breaks, labels = scatter_labels,
                     expand = expansion(mult = c(if (xr[1] == 0) 0 else .08, .08))) +
  scale_y_continuous(limits = yr, breaks = scatter_breaks, labels = scatter_labels,
                     expand = expansion(mult = c(if (yr[1] == 0) 0 else .08, .08))) +
  {if (shared_origin) annotate("text", x = 0, y = 0, label = "0",
     hjust = 1.4, vjust = 1.4, size = pt(11), family = figure_family)} +
  coord_cartesian(clip = "off") +
  labs(x = "X (units)", y = "Y (units)") +
  theme_figure()
```

- `seed` makes the layout reproducible; without it every render nudges labels and
  the figure changes between runs.
- Label the points that carry the argument, not all of them — filter the data
  by setting the other labels to `""` in the data passed to `geom_text_repel`.
  Keep all rows so unlabelled points remain collision obstacles. Twenty labels
  on forty points is unreadable. Give the repel layer sufficient `point.padding`
  for the point radius and verify clearance after export.
- `max.overlaps` silently drops labels once exceeded. If the preview is missing
  labels you expected, that is why — raise it, or label fewer points.
- Add upper/right scale expansion and figure margins so repelled labels have
  room; retain zero at the lower boundary of nonnegative axes.
