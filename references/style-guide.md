# Detailed plotting guidance

Load the helpers in [scripts/style.R](../scripts/style.R) before using the examples.
Read only the sections relevant to the current figure.

## Contents

- [Fonts, in practice](#fonts-in-practice)
- [Applying the palette](#applying-the-palette)
- [Sizing: design at the final printed size](#sizing-design-at-the-final-printed-size)
- [Legend placement and wrapping](#legend-placement-and-wrapping)
- [Axes, grid and ticks](#axes-grid-and-ticks)
- [Nothing may be clipped](#nothing-may-be-clipped)
- [Consistency across figures](#consistency-across-figures)
- [Numbers and rounding](#numbers-and-rounding)
- [Language and labels](#language-and-labels)
- [Render and inspect](#render-and-inspect)
- [Export](#export)
- [Known traps](#known-traps)
- [Reviewing an existing figure](#reviewing-an-existing-figure)
- [Dependencies](#dependencies)

## Fonts, in practice

Use **Libre Franklin** as the default font. `figure_font()` chooses an available family, but
font discovery by one graphics backend does not verify another backend's export.
The helper warns if it selects a fallback because the preferred font was not
discovered. Treat that warning as a setup issue before final delivery, especially
when Libre Franklin was explicitly requested; do not silently accept substitution.

### Raster fonts

- **PNG/TIFF previews:** `systemfonts` and `ragg` can use project-local fonts.
  Register the four bundled files explicitly if running outside the project root:

  ```r
  f <- file.path("fonts/Libre_Franklin/static",
                 paste0("LibreFranklin-",
                        c("Regular", "Bold", "Italic", "BoldItalic"), ".ttf"))
  stopifnot(all(file.exists(f)))
  systemfonts::register_font("Libre Franklin", plain=f[1], bold=f[2],
                             italic=f[3], bolditalic=f[4])
  figure_family <- "Libre Franklin"
  ```

### PDF fonts and platform setup

- **PDF:** `save_figure()` uses `grDevices::cairo_pdf`, which needs the family
  visible to its own platform font backend. `systemfonts::register_font()` alone
  does **not** register fonts with Windows or guarantee Cairo embedding.
- **Windows:** run [the current-user font installer](../scripts/install-fonts-windows.ps1)
  once, then start a fresh R process. It installs only the bundled Regular, Bold,
  Italic and BoldItalic faces and retains their OFL notice. No administrator-level
  font installation is needed. Use **R >= 4.6.0** for Cairo's corrected Windows
  font-style matching; the local four-face test reproduced an italic substitution
  for bold italic under R 4.5.2. See the
  [R developers' report](https://stat.ethz.ch/pipermail/r-devel/2026-January/084330.html).
- **macOS/Linux:** install the bundled fonts through the platform's user-font
  mechanism, or use a renderer that explicitly embeds the supplied font files.
  Keep the font licence with redistributed files.

### Font embedding checks

- **Verify the actual file:** run `pdffonts figure.pdf`. Expected names contain
  `LibreFranklin-Regular`, `LibreFranklin-Bold`, and any italic faces used;
  `emb` must say `yes`. Arial/Helvetica indicates substitution. Check representative
  regular, bold, italic and bold-italic text before a large export. Check
  font descriptors and embedded font streams in the delivered PDF.
  Text remains searchable vector text; do not convert it to outlines merely to
  hide an unresolved embedding problem.

## Applying the palette

### Categorical colours

Categorical data, three idioms:

```r
# Unnamed categories — take the first n colours in drawing order.
scale_color_manual(values = pal_okabe_ito(3), guide = legend_figure())
scale_fill_manual(values = pal_okabe_ito(3), guide = legend_figure())

# Named categories — pin each group to a colour. Use this whenever a group
# appears in more than one figure, so "Treatment" is the same blue everywhere.
group_colors <- c(Control = okabe_ito[["vermillion"]], Treatment = okabe_ito[["blue"]])
scale_color_manual(values = group_colors, guide = legend_figure())

# One series matters, the rest are context. Far more legible than 6 colours.
scale_fill_manual(values = c(`FALSE` = figure_neutrals[["muted"]],
                             `TRUE`  = okabe_ito[["blue"]]), guide = "none")
```

### Continuous and binned colours

Continuous data is a different problem, and Okabe-Ito is the wrong tool for it —
a qualitative palette interpolated into a gradient wanders in lightness and
invents boundaries the data does not have. Use the Tol schemes:

```r
# sequential
scale_fill_gradientn(colours = tol_schemes$YlOrBr, na.value = tol_bad[["YlOrBr"]])

# diverging, centred on a real midpoint
scale_fill_gradientn(colours = tol_schemes$sunset, na.value = tol_bad[["sunset"]],
                     limits = c(-1, 1), rescaler = ~ rescale_mid(.x, mid = 0))

# binned, which is easier to read off than any gradient
scale_fill_stepsn(colours = tol_schemes$YlOrBr, n.breaks = 5,
                  na.value = tol_bad[["YlOrBr"]])
```

### Scale breaks and legend ranges

Set breaks deliberately rather than accepting the default. For a proportion or
share, use `share_scale()`, which runs the legend from zero to a round ceiling
chosen from the data:

```r
sc <- share_scale(df$rate, percent = TRUE)
scale_fill_stepsn(colours = tol_schemes$YlOrBr, na.value = tol_bad[["YlOrBr"]],
                  limits = sc$limits, breaks = sc$breaks, labels = sc$labels,
                  name = "Share adopting")
```

| Data maximum | Legend runs | Steps |
|---|---|---|
| up to 0.25 | 0 to 0.25 | 0.05 |
| up to 0.50 | 0 to 0.50 | 0.10 |
| above 0.50 | 0 to 1 | 0.25 |

The point is to show a full, round range rather than only the span this sample
happened to cover — a legend fitted tightly to the data flatters small
differences. But a fixed 0–1 range does the opposite harm when the data tops out
low: rates between 13% and 45% would fall into two of four bins and most of the
map would be one colour. Stepping the ceiling keeps both properties.

For a variable that is not a proportion, keep the principle: fixed, evenly spaced
breaks including both endpoints, from `scales::breaks_pretty()` or
`breaks_width()` rather than an invented sequence.

### User-specified palettes

If the user names a palette (a journal, an organisation, a brand), use it — then
check it for the same properties these were chosen for and mention any problem
without refusing: adjacent hues that collapse under deuteranopia, any colour
below the contrast floor for how it is being used, non-monotonic lightness in a
continuous ramp, or fewer distinct hues than the data has categories.
`accessibility.md` has the checks.

## Sizing: design at the final printed size

### Proportional sizing

All example sizes are **reference values for a 7 x 5.5 inch figure**. At export,
`save_figure()` and `preview_figure()` multiply text, points, line widths, borders,
physical margins, legend keys and padding by one factor:

`s = sqrt((width / 7) * (height / 5.5))`

This is a linear scale derived from the overall figure area. Doubling both
dimensions doubles every visual size. Changing only one dimension changes the
factor by its square root. Coordinates, numeric ranges, bar widths in data units,
opacity, line types and aspect ratios are unchanged. `rel()` text ratios and
spacing in `lines` inherit the scaled font, so they are not multiplied twice.
The same export rule applies to maps, facets and complete multi-panel compositions.
First choose panel-appropriate marker reference sizes using
[multi-panel sizing](multi-panel.md#sizing-a-composed-figure). The export helper
does not infer panel area or automatically shrink markers in compositions.

| Export dimensions (in) | Factor | Base text | Typical point | CI stroke |
|---|---|---|---|---|
| 3.5 x 2.75 | 0.5 | 7pt | 1.5mm | 0.35 |
| 7 x 5.5 | 1 | 14pt | 3mm | 0.7 |
| 10.5 x 8.25 | 1.5 | 21pt | 4.5mm | 1.05 |
| 14 x 11 | 2 | 28pt | 6mm | 1.4 |

### Readability and custom reference sizes

At half size the default axis text is only 6pt. Do not silently clamp individual
sizes and break proportionality: simplify the layout, choose larger reference
text/marks together, or agree a larger output size. Essential text should be at
least 7pt in the delivered figure. User dimensions and size instructions prevail.

```r
# The same plot object, scaled once from its reference appearance.
save_figure(p, "figure.pdf", width = 10.5, height = 8.25)
preview_figure(p, "preview.png", width = 10.5, height = 8.25)
# If p was designed at another reference size, declare it explicitly.
save_figure(p, "wide.pdf", 12, 6, reference = c(8, 4))
# Explicit fixed physical sizes override the proportional default.
save_figure(p, "fixed.pdf", 7, 5.5, reference = NULL)
```

For direct ggplot inspection, `scale_figure(p, width, height)` returns a scaled
copy; the original is unchanged. Do not pass that copy through a second relative
export: use `reference = NULL` when saving it. Direct `ggsave()` bypasses this
workflow. Native PDFs/SVGs remain vector and text remains searchable.

The helper handles current core templates, mapped size/linewidth scales,
ordinary ggplot themes, guide overrides, physical-unit layout values and
patchwork compositions. Custom geoms or pre-rendered grobs may encode dimensions
outside these fields: inspect them and adapt explicitly; `reference = NULL`
supports exporting arbitrary grobs without claiming automatic scaling.

### Aspect ratios and panel sizes

**Default aspect selection is median absolute slope (MAS) banking to 45°.**
For a plot with meaningful ordered segments, use `bank_plot()` on the data-line
or fitted-curve layers. This computes the physical **panel height / width** from
the median absolute segment slope and the final displayed axis ranges, including
zero baselines and expansion. Keep the destination width and derive height from
the banked panel plus titles, axes, legend and margins; the file's height/width
is not the panel ratio. See [aspect-ratio guidance](aspect-ratio.md).

**Multipanel figures use one common panel size, not independent banked ratios.**
For compatible line panels use `bank_panels()` to pool slopes after normalising
each panel to its displayed ranges, then apply the resulting single ratio to
all panels. Equal panel dimensions and aligned headings take precedence over
banking each panel separately. Mixed map/chart figures preserve geographic
geometry while matching panel sizes as closely as practical.

### Fallback dimensions

Do not invent segments between unordered scatter points or categorical estimates.
For bars, coefficient plots, scatterplots without a drawn curve, constant/degenerate
series, maps and square-cell heatmaps, record why banking is undefined or geometry
takes precedence, then use readable fallback sizing. Explicit user dimensions
take precedence. Do not silently clamp a computed ratio to a preset rectangle.

Fallback height is a starting point: horizontal bar charts need roughly 0.35in per bar
plus 1in of chrome, faceted figures need the panel height times the number of
rows, and a coefficient plot needs roughly 0.4in per estimate drawn plus axes and legend space.

Below about 5in wide, chrome crowds the panel even with the scaled spacing in
`theme_figure`. Keep a top legend or use direct labels, and drop anything the
caption can carry instead.

### Points, lines and uncertainty

At the reference size, use: points `3.0` mm (roughly `1.7` with
`alpha` for dense data), lines `linewidth = 0.9`, error bars `linewidth = 0.7`
with T-shaped end caps (`width = 0.14` on a discrete outcome axis), axis lines
`0.5`, in-panel text `pt(10)` to `pt(12)`. Use full-opacity series colours for
interval strokes and black over coloured bars, checking contrast against both
the bar and the surrounding white. Avoid pale-grey or lightened intervals.
Uncertainty ribbons start at `alpha = 0.28` behind the data; inspect their
visibility and overlapping regions at the delivered size.

## Legend placement and wrapping

Place legends **at the top, in one horizontal row** by default. For discrete
scales use `guide = legend_figure()` or, for example,
`guides(colour = legend_figure(), shape = legend_figure())`; horizontal direction
alone does not guarantee one row. Merge guides for the same variable. Measure
keys and full labels at export size against the available plot width. Only if
that row overflows, wrap to the fewest rows that fit, still at the top, using
`legend_figure(nrow = 2)` as needed. Do not shrink below the text-size floor.
Continuous/stepped colourbars remain horizontal at the top, with their title
above when needed and a width that fits their panel. Do not replace them with discrete guides.
Collected multi-panel legends follow the same rule. Direct labels can remove
a redundant legend; an explicit user placement overrides the default.

### Legend titles

**If the plot has a title, or a multipanel figure has panel titles, omit legend
titles**, including continuous colourbar titles. Keep necessary variable names
and units in the plot/panel headings or axes, and retain legend keys/tick labels.
An untitled plot may retain a useful legend title.

## Axes, grid and ticks

The defaults in `theme_figure` are the rules, so following them takes no extra
code:

### Grid and axis lines

- **No internal grid.** A grid competes with the data for attention. When a
  reader needs to recover a value, label the marks directly — more accurate and
  less cluttered than making them sight along a line. `grid = "y"` or `"x"`
  exists for the rare case where a dense series genuinely cannot be labelled,
  and should be a choice you can justify.
- **Both axis lines drawn**, in `ink` at `linewidth = 0.5`. The axis line tells
  the reader where the data region starts, which matters more once the grid is
  gone.
- **Every axis line extends visibly beyond its last tick**, rather than ending
  exactly on it and forming an elbow. Leave a short tail (start with 3–4% of
  the displayed span, and check that it is visible at final size). Use full-panel
  axis lines (`guide_axis(cap = "none")`, the ggplot default), including for
  secondary or reversed axes. Do not draw a manual baseline ending at the last
  observation when ticks extend farther. Keep ticks within the panel range and
  inspect final grobs/exports after banking and composition. Set the intended
  breaks first and add upper/right expansion beyond them; do not let a new
  pretty break land on the extended endpoint. For reversed axes use the visual
  endpoint. This tail rule does not extend either axis past a shared zero origin.

### Ticks and intervals

- **Ticks on every axis that carries values.** `ticks = "both"` is the default;
  narrow it to the value axis when the other axis is categorical, since category
  labels already sit against the axis line:

  ```r
  theme_figure(ticks = "x")   # horizontal bars: values on x, categories on y
  ```
- **Ticks must sit at consistent intervals.** ggplot's default,
  `scales::extended_breaks()`, already does this and is usually right; on 1–8 it
  gives `0, 2, 4, 6, 8`. Hand-written break vectors are where irregular ticks
  come from — `breaks = c(1, 4, 8)` puts a gap of 3 next to a gap of 4, and the
  reader reads the spacing as meaning something. If the default is wrong for the
  data, replace it with another *rule*, not a list:

  ```r
  scale_x_continuous(breaks = breaks_with_zero(n = 5), labels = label_axis)
  scale_x_continuous(breaks = scales::breaks_width(2))     # every 2 units
  scale_x_continuous(breaks = seq(1, 8, by = 1))           # every wave
  ```

  An explicit vector is fine when it *is* regular (`seq()` above) or when the
  categories are genuinely irregular and labelled as such — survey waves at
  months 0, 6 and 18, for instance, where the spacing is the data.

### Zero and signed values

For **bar charts and coefficient plots**, start the quantitative axis at zero
by default. For **scatterplots**, start both quantitative axes at zero by
default. Use a different baseline only when explicitly requested. This applies
even when a dot/coefficient plot's observed values are far from zero; do not
silently zoom the scale for visual emphasis. Categorical axes are unaffected.
When data or confidence intervals extend below zero, retain their full range
and include zero rather than dropping negative values. `zero_limits()` computes
the baseline-inclusive range; include interval endpoints when calling it. Dates
and explicitly requested logarithmic scales do not have a numeric zero baseline.

Whenever **any axis range contains zero**, it must have a visible, plain `0`
label. `breaks_with_zero()` explicitly includes it, and `label_axis()` removes
decimal places/unit suffixes from that label. Keep other ticks regularly spaced
where practical. For percent axes use
`labels = function(x) label_axis(x, label_percent(accuracy = 1))`.

When the whole plotting region is **x >= 0 and y >= 0**, and both axes start at
zero, use **one shared `0` in the lower-left corner**, diagonally outside the
intersection; do not put it under the x tick or beside the y tick. Suppress both
ordinary zero tick labels and add this corner annotation with adequate margin
and Cartesian `clip = "off"`. **Remove both zero tick marks as well**, by
excluding zero from the breaks in this case; hiding just their labels leaves
two tick strokes that look like crossing axes. Both axis lines stop at their
shared origin and meet as a clean L, with no stroke continuing left or below it.
Use zero lower expansion and butt line ends. The shared annotation supplies the
required zero label. For all other layouts, each axis containing zero
keeps its own zero label; do not suppress one just because both axes contain it.
See `core-plots.md` for the positive-quadrant scatter example.

When a quantitative axis includes both positive and negative data, draw
a dashed grey reference line at zero on that axis, **before** the data layers:
`geom_hline(yintercept = 0, colour = figure_neutrals[["charcoal"]],
linetype = "dashed", linewidth = 0.45)`; use `geom_vline` for x.

### Categorical axis order

Alphabetical is almost never the order a reader wants, and ggplot orders factor
levels bottom-up on y, which inverts any list you write down. `axis_order()`
handles both:

```r
regions <- paste("Region", 1:6)
df$region <- axis_order(df$region, regions, axis = "y")   # Region 1 at the top

df$month <- axis_order(df$month, month.abb, axis = "x")   # Jan at the left
```

Three cases, in priority order:

1. **A natural sequence** — Region 1…6, Jan…Dec, wave 1…5, income quintiles.
   Follow it. Note that `sort()` puts "Region 10" before "Region 2", so write
   the order out (`paste("Region", 1:12)`) or use
   `stringr::str_sort(x, numeric = TRUE)`.
2. **Cardinal directions** — geography, not the alphabet. On a y axis north sits
   above south (`c("North", "Central", "South")`). On an x axis west sits left
   of east (`c("West", "Central", "East")`). Compound directions follow the same
   logic: north-east above south-east on y, north-west left of north-east on x.
3. **No natural order** — sort by the value being plotted, descending, so the
   figure ranks as well as reports: `forcats::fct_reorder(category, value)`.

Once a category order is set, keep it identical across every figure in the
document. A reader who learns the row order once should not have to relearn it.

## Nothing may be clipped

Judge text clearance in the **final assembled figure and every export device**,
not just an individual panel. Use the actual panel width after headings, axis
titles, category labels and neighbours consume space. Reserve the entire string,
including a trailing `%`, sign, unit or superscript. A fixed scale limit still
clips labels despite plot margins: extend the display range or place labels
inside with a measured contrast-safe background. Keep bar baselines at zero.
Do not enlarge a mandated single-column width; use layout or headroom first.

Every label, tick label, title and annotation must be fully visible in the
exported figure. A clipped label is worse than a missing one: the reader sees
"1. Centr" and cannot tell whether the text or the data is wrong. This applies
to the *rendered* figure, so it can only be settled by looking at it.

When something is about to run off the edge, fix it in this order:

1. **Widen the figure slightly if its destination allows it.** Otherwise use the next steps —
   an extra 0.2–0.4in of width costs the reader nothing and changes no
   proportions. Prefer a small change; if a figure needs 2 more inches, the
   problem is the content, not the canvas.
2. **Add headroom on the value axis.** For labels drawn beside bars or points,
   the expansion has to cover the longest label. `label_headroom()` computes it
   rather than leaving you to guess:

   ```r
   pad <- label_headroom(bars$label, size_pt = 10, panel_width_in = 3.0)
   scale_x_continuous(limits = c(0, NA), expand = expansion(mult = c(0, pad)))
   ```

3. **Break the text across lines.** Good for long titles, captions and category
   names; `stringr::str_wrap(x, width = 24)` or `\n` in the string. Prefer this
   over shrinking for anything the reader must read.
4. **Reduce the font size**, last, and never below the 7pt floor. A figure whose
   labels only fit at 6pt is a figure with too many labels — drop some instead.

The commonest specific case is a value label on the outermost bar or point,
where the default expansion leaves no room. The second commonest is a long
category name on a y axis in a narrow panel; widen, wrap, or abbreviate with the
full name in the caption.

### Labels must clear all marks

Coefficient value labels belong **above their own points**, centred on the
estimate's x position. They must not touch the point, interval or label in the
row above. Do not move them to a separate value column as a default workaround.
Increase figure height and spacing between dodged estimates until there is room
for the lower point's radius, its label and a clear gap below the upper point
and interval. Then choose a modest upward offset (for example `vjust = -0.8`),
and add top-row headroom. An offset alone cannot fix inadequate row spacing.
Keep labels attached to the same dodged row as the point. For scatterplots,
repel labels against **all**
points, including unlabelled ones (give those rows an empty label); keep the
points fixed and use leader lines when moving text. Check the rendered glyph
bounds, including point radius and caps, rather than testing only data coordinates.

### Leader lines

**Label indicator/leader lines must differ in colour from the marks they point
to.** Set segment colour explicitly outside inherited data mappings. Against
grey peer series use black (`#000000`) leaders, not another grey; against black
marks choose a contrasting accent absent from those marks. Against coloured
points an ink/black leader works. Verify visible separation at printed size;
a nearly identical hex value does not count. Keep leaders thin and subordinate,
with a clear endpoint, so they do not read as continued data lines. This applies
to label connectors, not confidence intervals or genuine data trajectories.

## Consistency across figures

Reuse one set of named colours, shapes, treatment/control order, interval width
and cap size, typography, precision and panel-heading style for like figures in
the same project unless the user requests a difference. Share limits when the
measure and comparison require them. Size changes may adjust spacing, but should
not silently change the visual meaning. Apply a correction to every like figure.

## Numbers and rounding

Precision is a claim about what the data supports, so it is worth getting right:

| Magnitude | Decimal places | Example |
|---|---|---|
| below 1 (and above −1) | 3 | `0.184`, `−0.041` |
| 1 up to 100 | 2 | `42.68` |
| 100 up to 1000 | 1 | `567.9` |
| 1000 and above | 0 | `1,234` |

Thousands always take a comma separator: `1,000`, not `1000`. `label_figure()`
applies both rules.

Two qualifications, both of which `label_figure()` handles:

- Apply the rule **once per set of labels**, using the largest magnitude in the
  set, not per individual number. A bar chart labelled `1,284 / 962.8 / 1,571`
  looks like a bug; `1,284 / 963 / 1,571` reads as one measurement. Pass
  `per_value = TRUE` only when a number stands alone.
- **Whole numbers take no decimals**, whatever their magnitude. A count of 800
  units is exactly 800, so "800.0" invents a tenth of a unit; an axis break at
  20 is a round number, so "20.00" is noise. This is why the table above is
  about the precision the data *supports* rather than a formatting ritual.

```r
geom_text(aes(label = label_figure(value)), hjust = -0.2, size = pt(10))
scale_x_continuous(breaks = breaks_with_zero(), labels = label_axis)
scale_y_continuous(breaks = breaks_with_zero(),
                   labels = function(x) label_axis(x, label_percent(accuracy = 1)))
```

When a set spans more than about three orders of magnitude, one shared precision
flattens the small values (`c(0.5, 42, 5000)` becomes `0, 42, 5,000`). That is a
signal to split the figure, use a log scale, or change units — not to mix
precisions.

### Distinct values and ranking

**Never let rounding collapse two values the figure is ranking.** In a sorted
bar chart, labelling 37.3% and 36.7% both as "37%" tells the reader the order is
arbitrary when it is not. Add decimal places — to every label in the set, not
just the tied pair — until the values are distinct:

```r
digits_distinct <- function(x, start = 0, max_digits = 4) {
  d <- start
  while (d < max_digits && anyDuplicated(round(x, d))) d <- d + 1
  d
}
d <- digits_distinct(100 * df$rate)          # percent scale
label_percent(accuracy = 10^(-d))(df$rate)
```

If separating them needs more precision than the data supports, that is the
finding: say in the caption that the two are not distinguishable, and consider
whether the ranking should be presented as a ranking at all.

## Language and labels

### Title and no title versions

Use `figure_version(destination, version)` to select the default and
`figure_labels(title, subtitle, caption, destination, version)` to apply overall
labels. This helper does not remove annotations or patchwork annotations.

Name the variants **title** and **no title**, including in delivery descriptions
and filenames (`_title` and `_no_title`). Choose the version by destination;
create both only when requested. Explicit user instructions override these
defaults.

- **No title** — the default for papers, journal articles, presentations and
  slide decks. Render no overall title, subtitle, caption, source note or
  footnote inside the figure. For a standalone ggplot, remove them with
  `labs(title = NULL, subtitle = NULL, caption = NULL)`; also remove any notes
  added as annotations or separate text grobs. Supply the title and explanatory
  copy separately for the manuscript caption, slide text or speaker notes.
  Keep axis labels, units, legends and data labels needed to read the plot.
- **Title** — the default for every other destination, including reports,
  posters, blog posts and standalone figures, and when the destination is
  unspecified. Include a title that states the finding, with subtitles and
  footnotes inside the figure when useful.
- Write the necessary explanatory and source text for either version; its
  placement depends on the selected version.

### Panel headings

Panel headings are not the overall figure title: **every composed panel needs a
short descriptive heading**, including in no title versions. Facet strips and
panel headings identify the data; they are retained unless the user asks to
remove them. Remove subtitles and footnotes from every panel in a no title
composition, as well as the composition's overall title, subtitle and caption.
Centre each heading across its complete plot region, including axis labels
(`plot.title.position = "plot"`, `plot.title = element_text(hjust = 0.5)`).
Headings in the same row share a baseline; stacked headings share a centre line.
Reserve the same heading height when one wraps, so data panels stay aligned.
Facet strips serve as headings for small multiples. Letters such as A/B alone
are insufficient. See `multi-panel.md` for placement.

### Axis labels and units

In both title versions, omit categorical-axis titles while retaining category
names: use `labs(y = NULL)` for horizontal bars, coefficient and dot plots;
`labs(x = NULL)` for categorical box/violin plots; and `labs(x = NULL, y = NULL)`
for heatmaps with two categorical axes. Do not remove the tick labels. Retain
numeric-axis titles and units, e.g. `Revenue (USD)` or `Adoption rate (%)`,
and meaningful time-axis titles on continuous/date axes. Explicit user requests
can restore a categorical-axis title. A shared numeric-axis title is sufficient
when it unambiguously applies to every aligned panel. Never guess an absent
unit; record it in the caption. Maps without coordinate axes are exempt.

### Footnotes and source notes

For notes rendered inside a figure, use superscript lowercase letters at the
relevant label or heading and matching letters before the footnote text. Use
plotmath, e.g. `expression("Adoption rate"^a)` and
`expression(""^a * " Note text.")` for the corresponding caption. Superscript
Unicode glyphs may be absent from an outlined PDF font even when they render in
PNG; prefer plotmath and verify both devices. Keep letters in reading order and note
text at least 7 pt. Do not use ordinary baseline letters, asterisks or numerals
as the default note markers. External manuscript captions follow journal style.

### Write labels as prose

Axis titles, legend keys and facet strips are read as sentences, so write them
that way: `Sepal.Length` becomes `Sepal length (cm)`; `hh_inc_pc` becomes
`Household income per capita (USD)`. Sentence case, units in parentheses, no
underscores or dots surviving from the data frame.

**In title versions, use active, concrete titles that state the finding**, not ones that name the
variables. The axes already say what is plotted; the title should say what to
take away.

- Yes: `Uptake tripled after the subsidy`
- No: `Uptake by year`
- No: `An analysis of the relationship between uptake and time`

**Omit needless words.** Space is at a premium in a figure, so cut anything not
doing work. `Mean household expenditure (USD)` beats `Average of total household
expenditure measured in US dollars`. Drop "number of", "total", "analysis of"
and stray articles wherever the meaning survives.

**Match the vocabulary to the audience.** For a general audience, replace
research vocabulary with direct language — "households that received the
transfer" rather than "treatment arm", "share" rather than "proportion",
"difference" rather than "differential". If a technical term genuinely has to
stay, define it in the caption in one clause. When you do not know the audience,
ask; if you cannot ask, assume a research audience and say so.

## Render and inspect

Code that runs is not a figure that works. Before delivering:

1. Run the script and write a preview: `preview_figure(p, "preview.png")`.
2. **Read `preview.png` as an image** and actually look at it.
3. Check what only the eye can catch, using the topic checklist below:
4. Fix, re-render, look again.

**Scale the loop to the stakes.** A figure for submission is worth iterating
until two consecutive passes find nothing. An exploratory plot for the user to
glance at needs one render and one look. Stop when a pass stops finding things,
rather than iterating for its own sake.

If R is unavailable, say so plainly rather than claiming the figure is verified,
and list what you could not check.

```bash
Rscript figure_script.R
```

### Labels and number formatting

- **anything clipped** — a value label on the outermost bar, a long category
  name, a title or caption running past the edge. Widen slightly, add
  headroom, wrap, or shrink, in that order
- value labels colliding with any bars, points, intervals or other labels,
  including a neighbouring group's mark; check T caps as well
- inconsistent decimal places within one set of labels
- two bars in a ranked chart labelled with the same rounded number

### Titles and panel headings

- incomplete panel headings or missing axis names/units on untitled charts
- unequal multipanel geometry from independent banking; misaligned/off-centre headings

### Axes and ticks

- missing/duplicated origin zeros or missing dashed zero lines for signed data
- ticks at irregular intervals, which read as if the spacing means something
- zero tick strokes making axes cross at a nonnegative origin
- axis lines ending at or before their last tick, without a visible tail
- a categorical axis in the wrong order, or reading bottom-up on y

### Legends

- legend outside the top position, or wrapping before a measured width overflow
- redundant legend titles on titled plots/panels
- two legends where there should be one, because the colour and shape scales
  did not merge

### Plot sizes and aspect ratios

- unbanked ordered data, or banking based on artificial point connections
- anything illegible when you imagine it at the final width

### Colours, contrast and layer order

- leaders matching the colour of their target marks
- a category whose colour vanishes (yellow on white, muted grey on white)
- a reference line or ribbon painted *over* the data — layers are drawn in
  the order they are added, so structure goes first and data last
- in-panel text too pale to read: white labels on light fills, or a
  series-coloured label in orange, yellow or sky blue

## Export

Default **800 dpi** for final raster output. Development previews remain 150 dpi
and do not replace inspection of the final export. Other resolutions
on request; vector formats have no dpi at all.

```r
save_figure(p, "fig1.png",  width = 7, height = 4.5)              # 800 dpi
save_figure(p, "fig1.pdf",  width = 7, height = 4.5)              # vector, print
save_figure(p, "fig1.tiff", width = 7, height = 4.5, dpi = 800)   # journal upload
save_figure(p, "fig1.png",  width = 10, height = 5.6, dpi = 300)  # slides
```

Prefer PDF or SVG when the destination accepts vector (LaTeX, print,
Illustrator); PNG for Word, slides and the web; TIFF only when a journal demands
it. Always white background, never transparent, unless asked — transparent PNGs
turn into black boxes in half of all slide themes.

## Known traps

When a request would produce a misleading or unreadable figure, name the problem
in one sentence, offer the alternative, and build what the user decides.

| Request | Why it misleads | Offer instead |
|---|---|---|
| Two y-axes | See below — the alignment is arbitrary | Two panels, a normalisation, or a connected scatterplot |
| Seven or more series | See below — the reader cannot match swatch to series | Combine categories, drop small ones, or use small multiples |
| Pie / donut, more than 3 slices | Angle and area are judged far less accurately than length | Ordered horizontal bars; a single stacked bar if parts-of-whole is the point |
| Bar chart not starting at zero | Bar length *is* the quantity, so a cut baseline exaggerates differences | Dot plot or line, where position rather than length carries the value |
| Rainbow / jet for continuous data | Non-monotonic lightness invents boundaries that are not in the data | A Tol sequential scheme, or a binned scale |
| Stacked bars to compare middle segments | Only the bottom segment shares a baseline; the rest float | Faceted or dodged bars, or plot the share of interest directly |
| 3D anything, or shadows | Perspective distorts the encoding and occludes data | The 2D version |
| Colour as the only encoding | Fails in greyscale and for roughly 4% of readers | Add `linetype`/`shape`, or label directly |
| Dense scatter at `alpha = 1` | Overplotting hides the mass of the distribution | `alpha = 0.3`, `geom_hex`, or 2D density |
| Choropleth of a count | Polygon area does the talking, so the map shows where the big regions are | Map a rate or share; proportional symbols for counts |

### Dual axes

Charts with two parallel axes — one series tagged to the left axis, another to
the right — should be avoided. Where the two series appear to cross, and how
dramatically they diverge, is set entirely by the scaling you happened to
choose, so the same data can be made to tell opposite stories. They are also
simply hard to read: every value first requires working out which axis it
belongs to.

Better options, roughly in order of how often they are the right answer:

1. **Two panels**, stacked vertically sharing an x-axis, or side by side.
   `multi-panel.md` covers the mechanics.
2. **Normalise** — show percent change from a common baseline, or index both
   series to 100 at the first period, and plot them on one axis.
3. **A connected scatterplot**, plotting one series against the other with time
   as the path, when the relationship between them is the actual question.

Two genuine exceptions:

- **A single measure in two units** — Fahrenheit and Celsius, inches and
  centimetres. The second axis is a relabelling of the first rather than a
  second series, so nothing is arbitrary: `sec_axis(~ . * 9/5 + 32)`.
- **A Pareto chart** — individual values as bars with a cumulative percentage
  line, where the convention is well established and the line is derived from
  the bars rather than being independent data.

### Too many categories

Stacked bars, pie charts, line charts and anything else with seven or more
series will look cluttered and be hard to read, because matching a swatch to a
series starts failing around seven. `pal_okabe_ito()` errors above 8 for the
same reason. When the data has more categories than that, suggest one of:

- **Combine** the small categories into a single "Other", and say in the caption
  what went into it.
- **Drop** the ones that are not part of the argument, and say how many were
  omitted.
- **Highlight one** against grey comparators. When the user names a focal
  series and asks for peer context, prefer a shared trend panel per metric to
  one facet per product. Draw peers first, focus last; use direct labels and a
  named product palette with only the focus in an accent colour. See the
  focal-series and ranked-bars sections in `core-plots.md`.
- **Small multiples** — one panel per category, which scales to dozens.

## Reviewing an existing figure

When given ggplot code or a rendered figure to critique or fix:

1. **Look at it first.** Render the code, or read the image, before reading the
   code closely — the visible failure is usually not the interesting line.
2. **Diagnose in severity order**: things that mislead the reader, then things
   that are illegible, then things that are merely inconsistent.
3. **Deliver what was asked.** A review request gets a prioritised list, each
   item naming the problem and the concrete fix. A "make this better" request
   gets the refactored script, rendered and inspected, with a short note on what
   changed and why. When unsure which, give the refactor and summarise it.
4. **Preserve intent.** Keep the author's chart type, variable choices and
   emphasis unless one of them is in the traps table. Restyling is not a licence
   to re-answer their research question.

**Checklist**

- *Misleading*: truncated bar baseline; dual axes; non-monotonic continuous
  palette; unequal bin widths; area encoding a linear quantity; a count mapped
  to polygon area; missing uncertainty where an estimate is claimed; more
  decimal places than the data supports
- *Illegible*: text below 7pt at final size; `theme_grey()` default; clipped or
  overlapping labels; more than about seven colours; marks below 3:1 contrast;
  legend larger than the panel; an internal grid competing with the data
- *Inaccessible*: colour-only encoding; a palette that collapses under
  deuteranopia; text below 4.5:1 contrast; a legend required to identify a
  series that could be labelled directly
- *Unpolished*: programmatic variable names; missing units; alphabetical
  category order; a y axis reading bottom-up; missing axis lines or ticks;
  irregular tick intervals; clipped labels; thousands without separators;
  inconsistent precision within one set of labels; a title naming variables
  rather than the finding; a no title version carrying an overall title,
  subtitle or footnote contrary to the user's requested version or destination

## Dependencies

`ggplot2` and `scales` are required; the style preamble needs nothing else.
`systemfonts` and `ragg` improve font rendering, `ggrepel` handles label
collisions, `patchwork` composes panels, `sf` draws maps, `colorspace` simulates
colour-vision deficiency. Check rather than assume. Follow the user's existing authorization for package installation:

```r
for (p in c("ggrepel", "patchwork", "sf", "ragg", "systemfonts", "colorspace")) {
  if (!requireNamespace(p, quietly = TRUE)) message("Not installed: ", p)
}
```

If a helper package is missing, fall back rather than stall: `geom_text` with
manual nudging instead of `ggrepel`, a faceted plot instead of `patchwork`, and
say what you substituted.

**Check versions when a composition fails.** In the historical combination of
patchwork 1.3.0 with ggplot2 4.0.0, the documented `&` idiom errors and
`plot_annotation(theme = )` is silently ignored (`multi-panel.md` has
the portable workaround). So when a correct-looking idiom fails, check versions
before rewriting the plot:

```r
sapply(c("ggplot2", "patchwork", "scales", "sf"),
       function(p) as.character(packageVersion(p)))
```

Report the incompatibility and the workaround you used rather than leaving a
mysterious detour in the code.
