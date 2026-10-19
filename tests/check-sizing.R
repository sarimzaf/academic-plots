# Called by run-tests.R after sourcing the live style helpers.
check_relative_sizing <- function(out) {
  stopifnot(figure_size_factor(7,5.5) == 1,
            figure_size_factor(14,11) == 2,
            figure_size_factor(3.5,2.75) == .5,
            figure_size_factor(7,22) == 2)
  for (dims in list(c(0,5),c(-7,5),c(Inf,5),c(7,NA)))
    stopifnot(inherits(try(figure_size_factor(dims[1],dims[2]),silent=TRUE),'try-error'))
  d <- data.frame(x=1:4,y=c(2,3,2.7,4),n=c(1,4,9,16))
  p <- ggplot(d,aes(x,y)) +
    geom_line(linewidth=.9,colour=okabe_ito[['blue']]) +
    geom_point(size=3,stroke=.6,shape=21,fill=okabe_ito[['blue']]) +
    geom_text(aes(label=y),nudge_y=.25,size=pt(11),family=figure_family) +
    labs(x='Wave',y='Outcome (units)',title='Proportional sizing',subtitle='The same plot at three export sizes') +
    theme_figure() + scale_y_continuous(limits=c(0,5))
  original <- ggplot_build(p)
  for (factor in c(.5,1,1.5,2)) {
    scaled <- scale_figure(p,7*factor,5.5*factor)
    built <- ggplot_build(scaled)
    stopifnot(isTRUE(all.equal(built$data[[1]]$linewidth, original$data[[1]]$linewidth*factor)),
              isTRUE(all.equal(built$data[[2]]$size,original$data[[2]]$size*factor)),
              isTRUE(all.equal(built$data[[2]]$stroke,original$data[[2]]$stroke*factor)),
              isTRUE(all.equal(built$data[[3]]$size,original$data[[3]]$size*factor)),
              identical(built$data[[2]]$x,original$data[[2]]$x),
              identical(built$data[[2]]$y,original$data[[2]]$y),
              abs(calc_element('axis.text.x',scaled$theme)$size - 14*.86*factor)<1e-8)
    if (factor %in% c(.5,1,1.5)) {
      save_figure(p,file.path(out,paste0('relative-size-',factor,'.pdf')),7*factor,5.5*factor)
      preview_figure(p,file.path(out,paste0('relative-size-',factor,'.png')),7*factor,5.5*factor)
    }
  }
  stopifnot(identical(ggplot_build(p)$data,original$data),p$theme$text$size == 14)
  mapped <- ggplot(d,aes(x,y,size=n))+geom_point()+theme_figure()+
    scale_size_area(max_size=6,guide=guide_legend(override.aes=list(stroke=.5)))
  a <- ggplot_build(mapped); b <- ggplot_build(scale_figure(mapped,14,11))
  stopifnot(isTRUE(all.equal(b$data[[1]]$size,a$data[[1]]$size*2)),
            isTRUE(all.equal(b$plot$guides$params[[1]]$key$size,a$plot$guides$params[[1]]$key$size*2)))
  auto <- ggplot(d,aes(x,y,size=n))+geom_point()+theme_figure()
  stopifnot(isTRUE(all.equal(ggplot_build(scale_figure(auto,14,11))$data[[1]]$size,
                            ggplot_build(auto)$data[[1]]$size*2)))
  identity <- auto + scale_size_identity()
  stopifnot(isTRUE(all.equal(ggplot_build(scale_figure(identity,14,11))$data[[1]]$size,
                            ggplot_build(identity)$data[[1]]$size*2)))
  jitter <- ggplot(d,aes(x,y))+geom_jitter(width=.1)+theme_figure()
  set.seed(42); a <- ggplot_build(jitter)
  set.seed(42); b <- ggplot_build(scale_figure(jitter,14,11))
  stopifnot(identical(a$data[[1]]$x,b$data[[1]]$x),identical(a$data[[1]]$y,b$data[[1]]$y))
  # Defaults, categorical bar widths, physical arrow lengths and line-relative units.
  defaults <- ggplot(d,aes(x,y))+geom_point()+geom_line()+theme_figure()
  a <- ggplot_build(defaults); b <- ggplot_build(scale_figure(defaults,14,11))
  stopifnot(isTRUE(all.equal(b$data[[1]]$size,a$data[[1]]$size*2)),
            isTRUE(all.equal(b$data[[2]]$linewidth,a$data[[2]]$linewidth*2)))
  bars <- ggplot(d,aes(factor(x),y))+geom_col(width=.6)+theme_figure()
  a <- ggplot_build(bars); b <- ggplot_build(scale_figure(bars,14,11))
  stopifnot(identical(a$data[[1]]$xmin,b$data[[1]]$xmin),identical(a$data[[1]]$xmax,b$data[[1]]$xmax))
  mixed <- grid::unit.c(unit(2,'mm'),unit(1,'lines'),unit(1,'null'))
  stopifnot(identical(as.numeric(.figure_scale_units(mixed,2)),c(4,1,1)))
  if (requireNamespace('patchwork',quietly=TRUE)) {
    pair <- patchwork::wrap_plots(p,p) + patchwork::plot_annotation(title='Composition',theme=theme_figure())
    before <- pair$patches$plots[[1]]$layers[[2]]$aes_params$size
    doubled <- scale_figure(pair,14,11)
    stopifnot(doubled$patches$plots[[1]]$layers[[2]]$aes_params$size == before*2,
              pair$patches$plots[[1]]$layers[[2]]$aes_params$size == before,
              doubled$patches$annotation$theme$text$size == 28)
    preview_figure(pair,file.path(out,'relative-composition.png'),10.5,8.25)
  }
  save_figure(p,file.path(out,'fixed-size-override.pdf'),3.5,2.75,reference=NULL)
  cat('PASS: proportional text, points, strokes, guides, defaults, mapped sizes, unchanged data widths and source plots, patchwork, and size overrides.\n')
}
