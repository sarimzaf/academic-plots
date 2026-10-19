# Live release checks: no frozen preambles or saved plot objects.
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Run tests/run-tests.R with Rscript")
root <- dirname(dirname(normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)))
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else file.path(tempdir(), "academic-plots-tests")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)

for (package in c("ggplot2", "scales")) {
  if (!requireNamespace(package, quietly = TRUE)) stop("Install required package: ", package)
}
stopifnot(packageVersion("ggplot2") >= "4.0.0", packageVersion("scales") >= "1.4.0")
# Grid measurements must not open an implicit Rplots.pdf in the working directory.
grDevices::pdf(file = NULL)
measurement_device <- grDevices::dev.cur()
source(file.path(root, "scripts/style.R"), encoding = "UTF-8")
stopifnot(identical(formals(figure_font)$prefer, "Libre Franklin"))
if (requireNamespace("systemfonts", quietly = TRUE) &&
    "Libre Franklin" %in% systemfonts::system_fonts()$family) {
  stopifnot(identical(figure_family, "Libre Franklin"),
            identical(theme_figure()$text$family, "Libre Franklin"))
}
if (identical(Sys.getenv("ACADEMIC_PLOTS_REQUIRE_FONT"), "true")) {
  stopifnot(identical(figure_family, "Libre Franklin"))
  cat("PASS: installed Libre Franklin is selected by default.\n")
}
figure_family <- "sans"  # Exercise portable device defaults; fonts are optional.
# Font fallback remains portable, but must be disclosed rather than silent.
font_warning <- NULL
fallback_font <- withCallingHandlers(
  figure_font(prefer="academic-plots-test-missing-font", fallback=character()),
  warning=function(w) { font_warning <<- conditionMessage(w); invokeRestart("muffleWarning") })
stopifnot(identical(fallback_font,"sans"), grepl("not discovered",font_warning))


blocks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- which(grepl("^\\s*```r\\s*$", lines))
  lapply(starts, function(start) {
    ends <- which(grepl("^\\s*```\\s*$", lines[(start + 1):length(lines)]))
    if (!length(ends)) stop("Unclosed R fence in ", path)
    lines[(start + 1):(start + ends[1] - 1)]
  })
}
paths <- c(file.path(root, "SKILL.md"),
           list.files(file.path(root, "references"), "[.]md$", full.names = TRUE))
count <- 0L
for (path in paths) for (block in blocks(path)) {
  parse(text = block)
  count <- count + 1L
}
cat("PASS:", count, "current fenced R blocks parse.\n")

core_path <- file.path(root, "references/core-plots.md")
core_lines <- readLines(core_path, warn = FALSE, encoding = "UTF-8")
section_code <- function(heading) {
  start <- match(heading, core_lines)
  if (is.na(start)) stop("Missing template: ", heading)
  first <- start + which(core_lines[(start + 1):length(core_lines)] == "```r")[1]
  last <- first + which(core_lines[(first + 1):length(core_lines)] == "```")[1]
  core_lines[(first + 1):(last - 1)]
}
evaluate_template <- function(code, env = .GlobalEnv) {
  for (expr in parse(text = code)) {
    if (is.call(expr) && identical(expr[[1]], as.name("save_figure"))) next
    eval(expr, envir = env)
  }
}

# The actual template must use the actual mapped fill, not an independent ramp.
heatmap_code <- section_code("## Heatmap / square tiles")
contrast_results <- list()
for (ceiling in c(.25, .5, 1)) {
  for (with_na in c(FALSE, TRUE)) {
    sample_values <- c(0, ceiling / 5, ceiling / 2, ceiling)
    if (with_na) sample_values <- c(sample_values, NA_real_)
    code <- gsub("runif(nrow(grid_df), 0.05, 0.95)",
                 "rep(sample_values, length.out = nrow(grid_df))", heatmap_code, fixed = TRUE)
    evaluate_template(code)
    built <- ggplot_build(p_tile)
    stopifnot(identical(built$data[[1]]$fill, built$data[[2]]$fill))
    ratios <- contrast_ratio(built$data[[2]]$colour, built$data[[1]]$fill)
    stopifnot(all(is.finite(ratios)), all(ratios >= 4.5))
    contrast_results[[length(contrast_results) + 1L]] <- data.frame(
      ceiling, with_na, minimum_contrast = min(ratios))
    if (!with_na && ceiling == .25) {
      heatmap <- p_tile
      preview_figure(p_tile, file.path(out, "heatmap-low-range.png"), 6, 5)
    }
  }
}
write.csv(do.call(rbind, contrast_results), file.path(out, "heatmap-contrast.csv"), row.names = FALSE)
cat("PASS: current heatmap template clears 4.5:1 at all three ceilings, including NA fills.\n")

# Check both selection and actual plot labels/grobs, including explicit overrides.
for (destination in c("paper", "journal single column", "manuscript", "presentation", "slides", "slide deck")) {
  stopifnot(figure_version(destination) == "no title",
            figure_version(destination, "title") == "title")
}
for (destination in c("report", "poster", "blog post", "standalone")) {
  stopifnot(figure_version(destination) == "title",
            figure_version(destination, "no title") == "no title")
}
stopifnot(figure_version() == "title", figure_version(version = "no title") == "no title")
stopifnot(inherits(try(figure_version(version = "paper"), silent = TRUE), "try-error"))
titled <- heatmap + figure_labels("Adoption by month and region", "Synthetic example",
                                  "Source: generated data", destination = "report") +
  theme(legend.title = element_blank())
untitled <- titled + figure_labels("Unused", "Unused", "Unused", destination = "presentation") +
  theme(legend.title = element_text(size = rel(.9)))
stopifnot(identical(titled$labels$title, "Adoption by month and region"))
for (key in c("title", "subtitle", "caption")) stopifnot(is.null(untitled$labels[[key]]))
stopifnot(identical(untitled$labels$x, titled$labels$x), identical(untitled$labels$y, titled$labels$y))
gt <- ggplotGrob(untitled)
for (key in c("title", "subtitle", "caption")) {
  slot <- which(gt$layout$name == key)
  stopifnot(length(slot) == 1L, inherits(gt$grobs[[slot]], "zeroGrob"))
}
requested_title <- heatmap + figure_labels("Requested title", destination = "paper", version = "title")
requested_plain <- titled + figure_labels("Unused", destination = "report", version = "no title")
requested_note <- untitled + labs(caption = "Explicitly requested note")
stopifnot(identical(requested_title$labels$title, "Requested title"),
          is.null(requested_plain$labels$title),
          identical(requested_note$labels$caption, "Explicitly requested note"))
facet <- ggplot(iris, aes(Sepal.Length, Petal.Length)) + geom_point() +
  facet_wrap(~ Species) + figure_labels("Overall", destination = "paper")
facet_grob <- ggplotGrob(facet)
stopifnot(sum(grepl("^strip-", facet_grob$layout$name)) == 3L)
preview_figure(titled, file.path(out, "version-title.png"), 6, 5.8)
preview_figure(untitled, file.path(out, "version-no-title.png"), 6, 5)
save_figure(titled, file.path(out, "version-title.pdf"), 6, 5.8)
save_figure(untitled, file.path(out, "version-no-title.pdf"), 6, 5)
cat("PASS: destination defaults, user overrides, removed label grobs and retained facet strips.\n")

# Execute data-complete current core templates with the current helper definitions.
headings <- c("## Line / trend", "## Grouped horizontal bars with value labels",
              "## Coefficient plot, one estimate per outcome",
              "## Coefficient plot, several estimates per outcome",
              "## Ranked bars with one highlighted", "## Scatter with fitted line",
              "## Distributions: box / violin with points", "## Histogram and density",
              "## Cleveland dot plot", "## Stacked proportion bars", "## Faceted small multiples")
for (heading in headings) evaluate_template(section_code(heading))
for (name in c("p_line", "p_coef", "p_coef_multi", "p_rank", "p_scatter", "p_box", "p_hist", "p_dot", "p_stack", "p_facet")) {
  stopifnot(inherits(ggplot_build(get(name)), "ggplot_built"))
}
preview_figure(p_coef_multi, file.path(out, "coefficients.png"), 7, 5.4)
cat("PASS:", length(headings), "additional current chart templates execute.\n")
# Facet markers follow occupied grid area, including empty final cells.
for (groups in c(2L,3L,5L)) {
  facet_env <- new.env(parent=.GlobalEnv)
  facet_env$trend <- expand.grid(wave=1:5,group=letters[seq_len(groups)])
  facet_env$trend$value <- seq_len(nrow(facet_env$trend))
  evaluate_template(section_code("## Faceted small multiples"),facet_env)
  built <- ggplot_build(facet_env$p_facet)
  cells <- max(built$layout$layout$ROW) * max(built$layout$layout$COL)
  stopifnot(all(built$data[[2]]$size == 3/sqrt(cells)),
            all(built$data[[2]]$stroke == .5/sqrt(cells)))
}
cat("PASS: facet marker sizes follow the full panel grid, including empty cells.\n")

# Append to the live release checks, after the current core templates execute.
categorical_axes <- list(p_bar="y", p_coef="y", p_coef_multi="y", p_rank="y",
                         p_box="x", p_dot="y", p_stack="y", p_tile=c("x","y"))
for (name in names(categorical_axes)) {
  plot <- get(name)
  grob <- ggplotGrob(plot)
  for (axis in categorical_axes[[name]]) {
    slot <- if (axis == "x") "xlab-b" else "ylab-l"
    stopifnot(inherits(grob$grobs[[match(slot, grob$layout$name)]], "zeroGrob"))
    scale <- ggplot_build(plot)$layout[[paste0("panel_scales_",axis)]][[1]]
    stopifnot(length(scale$get_labels()) > 0L)
  }
}
stopifnot(nzchar(p_bar$labels$x), nzchar(p_box$labels$y), nzchar(p_scatter$labels$x),
          nzchar(p_scatter$labels$y))
# Explicit requests can restore a category-axis title.
override <- ggplotGrob(p_bar + labs(y="Activity"))
stopifnot(!inherits(override$grobs[[match("ylab-l",override$layout$name)]], "zeroGrob"))
for (plot in list(p_coef,p_coef_multi)) {
  interval <- ggplot_build(plot)$data[[2]]
  stopifnot(all(contrast_ratio(interval$colour,"#FFFFFF") >= 3),
            all(interval$linewidth >= .7), all(is.na(interval$alpha) | interval$alpha == 1))
}
stopifnot(all(contrast_ratio("#000000",c("#FFFFFF",group_colors)) >= 3))
cat("PASS: category titles absent, tick labels and numeric titles retained, explicit override works; intervals clear 3:1 contrast.\n")

if (requireNamespace("ggrepel", quietly = TRUE)) {
  for (signed in c(FALSE, TRUE)) {
    df <- data.frame(x = c(2, 5, 9), y = c(if (signed) -3 else 3, 5, 8), name = c("A", "B", "C"))
    evaluate_template(section_code("## Labelled scatter with ggrepel"))
    built <- ggplot_build(p_labelled)
    stopifnot(built$layout$panel_params[[1]]$x.range[1] == 0)
    if (signed) stopifnot(built$layout$panel_params[[1]]$y.range[1] <= -3)
    preview_figure(p_labelled, file.path(out, paste0("scatter-", signed, ".png")), 5, 4)
  }
  cat("PASS: optional ggrepel template for positive and signed data.\n")
} else cat("SKIP: optional ggrepel rendering (package not installed).\n")

if (requireNamespace("patchwork", quietly = TRUE)) {
  left <- heatmap + labs(title = "Adoption by region", subtitle = NULL, caption = NULL) +
    theme(legend.title = element_blank())
  right <- heatmap + labs(title = "Adoption by month", subtitle = NULL, caption = NULL) +
    theme(legend.title = element_blank())
  composed <- patchwork::wrap_plots(left, right) + patchwork::plot_annotation(tag_levels = "A")
  stopifnot(identical(left$labels$title, "Adoption by region"),
            identical(right$labels$title, "Adoption by month"))
  preview_figure(composed, file.path(out, "panels-no-title.png"), 10, 5)
  cat("PASS: no title composition retains descriptive panel headings.\n")
} else cat("SKIP: optional patchwork composition (package not installed).\n")

source(file.path(root,"tests/check-sizing.R"))
check_relative_sizing(out)

backgrounds <- grDevices::gray(seq(0, 1, length.out = 101))
stopifnot(all(contrast_ratio(contrast_text(backgrounds), backgrounds) >= 4.5),
          identical(zero_limits(c(-12, 50)), c(-12, 50)),
          identical(label_axis(c(0, .1), scales::label_percent()), c("0", "10%")),
          0 %in% breaks_with_zero()(c(-.17, .43)), formals(save_figure)$dpi == 800)
tiny <- ggplot(data.frame(x = 1, y = 1), aes(x, y)) + geom_point() + theme_void()
png_path <- file.path(out, "dpi-check.png")
save_figure(tiny, png_path, width = 1, height = 1)
con <- file(png_path, "rb")
signature <- readBin(con, "raw", 16)
dimensions <- readBin(con, "integer", 2, size = 4, endian = "big")
close(con)
stopifnot(identical(dimensions, c(800L, 800L)))
cat("PASS: numeric/contrast helpers and actual 800 dpi PNG dimensions.\n")
writeLines(capture.output(sessionInfo()), file.path(out, "session-info.txt"))
invisible(grDevices::dev.off(measurement_device))
cat("All release checks passed. Outputs:", out, "\n")
