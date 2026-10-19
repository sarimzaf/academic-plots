# Run with Rscript examples/quickstart.R [output-directory].
# This demonstration explicitly exports both versions from generated data.
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Run this example with Rscript")
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
root <- dirname(dirname(script_path))
source(file.path(root, "scripts/style.R"), encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "output"
dir.create(out, recursive = TRUE, showWarnings = FALSE)

d <- expand.grid(month = c("January", "February", "March"),
                 region = c("North", "Central", "South"))
d$share <- c(.05, .10, .15, .10, .15, .20, .15, .20, .25)
d$month <- factor(d$month, c("January", "February", "March"))
d$region <- axis_order(d$region, c("North", "Central", "South"))
sc <- share_scale(d$share, percent = TRUE)
p <- ggplot(d, aes(month, region, fill = share)) +
  geom_tile(colour = "white", linewidth = .5) +
  geom_text(aes(label = scales::percent(share, accuracy = 1),
                colour = after_scale(contrast_text(fill))),
            size = pt(11), family = figure_family) +
  scale_fill_gradientn(colours = tol_schemes$YlOrBr, limits = sc$limits,
                       breaks = sc$breaks, labels = sc$labels,
                       na.value = tol_bad[["YlOrBr"]], name = "Adoption rate") +
  guides(fill = guide_colourbar(theme = theme(
    legend.key.width = unit(3, "in"), legend.key.height = unit(.12, "in")))) +
  coord_fixed() +
  labs(x = NULL, y = NULL) +
  theme_figure(ticks = "none", legend_title = TRUE) +
  theme(legend.title.position = "top")

title <- "Adoption increases across all three regions"
subtitle <- "Illustrative rates, January to March"
caption <- "Synthetic example data; not estimates of real populations."
for (version in c("title", "no title")) {
  figure <- p + figure_labels(title, subtitle, caption, version = version)
  if (version == "title") figure <- figure + theme(legend.title = element_blank())
  save_figure(figure, file.path(out, paste0("heatmap_", gsub(" ", "_", version), ".png")),
              width = 7, height = 5.8)
}
writeLines(c(title, subtitle, caption), file.path(out, "caption.txt"))
message("Wrote examples to ", normalizePath(out, winslash = "/"))
