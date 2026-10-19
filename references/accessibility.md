# Accessibility and colour checking

A figure that only works for readers with typical colour vision, on a colour
printer, at full size, fails a meaningful share of its audience. Roughly 8% of
men and 0.5% of women of northern European descent have some form of red-green
colour vision deficiency, journals still print in greyscale, and figures get
photocopied, projected and shrunk.

Three requirements, in order of how often they are violated:

1. **Never encode with colour alone.**
2. **Keep marks and text above the WCAG contrast thresholds.**
3. **Label directly where you can, so the legend is a convenience not a key.**

## 1. Redundant encoding

Every category distinction carried by colour should be carried by a second
channel too. The figure then survives greyscale, colour vision deficiency, and a
projector with the contrast turned down.

| Geometry | Second channel |
|---|---|
| Lines | `linetype` — solid for the series of interest, dashed/dotted for others |
| Points | `shape` — `c(16, 17, 15, 18)` (filled circle, triangle, square, diamond) |
| Bars, tiles, areas | Direct labels, facets, or ordering; fill patterns are a last resort |
| Two-group anything | One colour against grey, plus direct labels, shape or line type |

```r
ggplot(df, aes(x, y, color = group, linetype = group, shape = group)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3) +
  scale_color_manual(values = pal_okabe_ito(3)) +
  scale_linetype_manual(values = c("solid", "dashed", "dotted")) +
  scale_shape_manual(values = c(16, 17, 15))
```

Mapping the same variable to all three aesthetics merges them into a single
legend automatically, which is what you want — three legends for one variable is
worse than none. If you get two legends instead of one, the usual cause is a
scale carrying keys the others do not have; see the coefficient-plot notes in
`core-plots.md`.

### Greyscale checks

**Greyscale test.** The fastest honest check is to desaturate the palette and
look. If two series become the same grey, the figure is colour-dependent:

```r
if (requireNamespace("colorspace", quietly = TRUE)) {
  colorspace::desaturate(pal_okabe_ito(4))
}
#> "#6D6D6D" "#828282" "#8B8B8B" "#939393"
#>  blue      vermillion green     purple
```

Okabe-Ito does not guarantee distinguishability at every size or in greyscale.
Green and purple can become similar greys; inspect the computed values and the
rendered figure. Keep labels, shapes or line types that identify each series
when colour differences are lost.

## 2. WCAG contrast thresholds

Use the WCAG 2.2 [text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
and [non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)
criteria as design checks. WCAG addresses web content; these checks are useful
for printed figures too, but do not certify a figure or document as accessible.
Text in graphics includes data labels, axes and annotations. Required graphical
information needs contrast against adjacent colours, not only the page background.

| | Normal text | Large text | Non-text (marks, borders) |
|---|---|---|---|
| **Level AA** | 4.5:1 | 3:1 | 3:1 |
| **Level AAA** | 7:1 | 4.5:1 | — |

"Large text" means **14pt or larger and bold** (typically 18.66px), or **18pt or
larger** (typically 24px) at any weight. Almost all text in a figure — axis
labels at 8–11pt, value labels at 9–10pt — is therefore *normal* text and needs
**4.5:1**. Only a poster headline or a large slide title qualifies as large.

Decorative grid lines can recede. If a grid line is needed to understand a
value or distinction, make it visible or provide labels that convey that
information. `theme_figure()` omits internal grids by default. Follow
[W3C use-of-colour guidance](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)
and keep a visible cue in addition to hue, including for colour-versus-grey comparisons.

### Measuring contrast

Compute rather than guess. These three functions are already in the style
helpers in [`scripts/style.R`](../scripts/style.R):

Read or source `scripts/style.R` before these checks. For scaled fills, use
`after_scale(contrast_text(fill))` so the label sees the same colour that
ggplot actually renders; do not approximate it with a separate RGB ramp.


Measured on white with the helper functions:

| Colour | Hex | Ratio on white | Safe as |
|---|---|---|---|
| black | `#000000` | 21.00 | anything |
| ink | `#222222` | 15.91 | all text (AAA) |
| charcoal | `#5C5858` | 7.02 | text (AAA), reference lines |
| blue | `#0072B2` | 5.19 | text (AA), lines, points, fills |
| boundary | `#6F6F6F` | 5.02 | text (AA), map borders |
| vermillion | `#D55E00` | 3.87 | lines, points, fills; text only at 18pt+ |
| green | `#009E73` | 3.42 | lines, points, fills; not normal text |
| muted_line | `#8F8F8F` | 3.23 | borders on pale fills |
| purple | `#CC79A7` | 3.06 | lines and fills; not normal text |
| sky blue | `#56B4E9` | 2.31 | fills only |
| orange | `#E69F00` | 2.25 | fills only |
| muted | `#C9C9C9` | 1.66 | comparator fills, with a border |
| yellow | `#F0E442` | 1.32 | large fills with a border; never text or thin marks |
| grid | `#EBEBEB` | 1.19 | grid lines only — meant to recede |

Only `blue` and the neutrals clear 4.5:1, so **blue and the neutrals are the
only palette colours safe for normal-size coloured text**. Note also the
direction of the in-fill result: `contrast_text()` returns dark `ink` for every
Okabe-Ito fill except `blue` and `black`. White in-bar labels are the wrong
default.

`okabe_draw_order` leads with blue and vermillion, which clear 3:1 on white.
Ordering alone cannot ensure contrast: later colours still need checks for
their actual use, and even vermillion needs a darker colour for normal text.

Practical consequences:

### Text and label colours

- Direct labels tinted with the series colour need `blue`, `black` or
  `ink`. Anything paler must be darkened (`colorspace::darken(col, 0.3)` takes
  orange to 4.58:1) or set to `ink`.

### Intervals, fills and borders

- Thin T-capped error bars need at least 3:1 against their background. Use
  full-opacity dark or series-coloured strokes without lightening; use black
  over coloured bars. The reference linewidth is 0.7. Check contrast against
  both the bar fill and the surrounding background.
- Yellow and sky blue fills need a border (`figure_neutrals[["muted_line"]]`, or
  a darkened version of the fill) or they float against white.
- Grey comparator bars (`muted`, `#C9C9C9`) sit at 1.66:1 — intentional, since
  they should recede — but they need the `muted_line` border to stay legible.

## 3. Direct labelling over legends

A legend asks the reader to hold a colour in memory, move their eyes, and match
it. Every legend you remove is one less place the figure can fail. Prefer, in
order:

1. **Value labels on the marks** — bar, dot and coefficient charts almost never
   need a numeric axis *and* labels; pick one.
2. **End-of-line labels** — see the line template in `core-plots.md`.
3. **Facet strips** — the strip already names the series, so the legend is
   redundant. Drop it with `theme_figure(legend = "none")`.
4. **Text annotation in the subtitle**, for title versions only — but colour
   names in text assume the reader can see colour, so keep it alongside a second
   channel. In no title versions, use direct labels or a legend for essential
   decoding information and supply explanatory text separately.
5. **A legend**, when the categories are many or the panel is crowded. Use one
   horizontal row at the top; wrap to the fewest rows only when full labels and
   keys exceed the available width. Keep keys ordered to match the data
   (`guides(fill = guide_legend(nrow = 1, reverse = TRUE))` for stacked bars). A
   horizontal colourbar wants its title above it
   (`legend.title.position = "top"`), or the title collides with the first break
   label.

## Continuous data: use the Tol schemes

Okabe-Ito is qualitative. Interpolating it into a gradient produces a ramp whose
lightness wanders up and down, which invents visual boundaries the data does not
have — the same defect that makes rainbow and jet unusable. For any ordered
variable use the Paul Tol schemes in `tol_schemes`:

| Scheme | Kind | n | Use for |
|---|---|---|---|
| `YlOrBr` | sequential | 9 | one-directional magnitude; the default |
| `iridescent` | sequential | 23 | fine gradations, smooth ramps |
| `incandescent` | sequential | 11 | heat-like, high-contrast sequential |
| `sunset` | diverging | 11 | deviations around a real midpoint |
| `nightfall` | diverging | 17 | diverging with more steps |
| `BuRd` | diverging | 9 | blue-red, the conventional choice |
| `PRGn` | diverging | 9 | when blue-red carries unwanted meaning |

### Lightness and greyscale

Verified with `relative_luminance()`: the three sequential schemes are monotonic
in lightness, which preserves ordering in greyscale; check visible separation at final size; the four diverging schemes
are deliberately not, being light in the middle and dark at both ends. That
means a **diverging scheme still fails in greyscale** — two opposite values map
to a similar grey — so keep the zero line, labels or annotation that tell the
reader which side is which.

### Missing-value colours

Each scheme has its own out-of-range colour in `tol_bad`, chosen so missing data
cannot be mistaken for a low value. Always set it:

```r
scale_fill_stepsn(colours = tol_schemes$YlOrBr, na.value = tol_bad[["YlOrBr"]],
                  limits = c(0, 1), breaks = seq(0, 1, 0.25),
                  labels = label_figure(seq(0, 1, 0.25)))
```

`khroma` provides the same schemes as scale functions if it is installed
(`khroma::scale_fill_iridescent()`), but the inline vectors above need no
dependency.

## Simulating colour vision deficiency

Worth doing whenever a figure encodes more than two categories by colour, or
uses a palette you did not choose yourself.

```r
if (requireNamespace("colorspace", quietly = TRUE)) {
  pal <- pal_okabe_ito(5)
  data.frame(
    normal   = pal,
    deuteran = colorspace::deutan(pal),   # ~5% of men: red-green
    protan   = colorspace::protan(pal),   # ~1% of men: red-green
    tritan   = colorspace::tritan(pal)    # rare: blue-yellow
  )
}
```

Even Okabe-Ito has a soft spot worth knowing: under deuteranopia, green
(`#009E73` → `#8A8676`) and purple (`#CC79A7` → `#9498A5`) converge on similar
desaturated tones. If a figure uses exactly those two, swap purple for
vermillion or add the second channel.

Two ways to use this. Quick check: print the table and look for two rows whose
simulated values are close. Thorough check: render the figure, then rebuild it
with the simulated palette substituted and compare the two images —
distinguishability depends on mark size and adjacency, not only on the colours.

```r
p_sim <- p + scale_color_manual(values = colorspace::deutan(pal_okabe_ito(3)))
preview_figure(p_sim, "preview_deutan.png")
```

## Checking a palette you were handed

When the user supplies a journal, organisational or brand palette, use it — but
run these checks and report what you find in one or two sentences without
refusing:

1. **Enough colours?** Compare the palette length to the number of categories.
   Recycling colours is a correctness bug, not a style issue. Beyond about seven
   categories no palette rescues the figure — collapse, facet, or highlight one
   against grey instead.
2. **Distinguishable under deuteranopia?** Simulate and look for collisions.
   Red-green pairs are the usual failure.
3. **Above the right threshold for how it is used?** `contrast_ratio()` each
   colour; flag anything below 4.5:1 carrying normal-size text, or below 3:1
   carrying lines, points or borders.
4. **Monotonic in lightness, if continuous?** A qualitative palette must never
   be interpolated into a gradient. Use a Tol sequential scheme for continuous
   data even when the categorical palette is fixed by a brand.

A good report sounds like: "Using your palette as specified. Two notes: the red
and green (#C0392B / #27AE60) are hard to separate under deuteranopia, so I have
added `linetype` as a second channel; and the light gold at 1.8:1 on white is
used only as a large fill, with a border."

## What this skill does not cover

Alt text and long descriptions for figures are a real accessibility need but
belong to the document rather than the plotting code. If you are producing a
figure for a report, offer a one-sentence description of what it shows — it costs
nothing and is what a screen reader will read.
