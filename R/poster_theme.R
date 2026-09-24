poster_condition_colors <- c(
  "Control" = "#566573",
  "Thematic" = "#008C8C",
  "Grounding" = "#D95F02"
)

poster_contrast_colors <- c(
  "Grounding vs Thematic" = "#D95F02",
  "Grounding vs Control" = "#0072B2",
  "Thematic vs Control" = "#009E73"
)

theme_poster <- function(base_size = 16, base_family = "Helvetica") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(1.18),
        color = "#18212B",
        margin = ggplot2::margin(b = 7)
      ),
      plot.subtitle = ggplot2::element_text(
        color = "#455565",
        size = ggplot2::rel(0.92),
        margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        color = "#5F6F7F",
        size = ggplot2::rel(0.72),
        hjust = 0,
        margin = ggplot2::margin(t = 9)
      ),
      axis.title = ggplot2::element_text(face = "bold", color = "#263442"),
      axis.text = ggplot2::element_text(color = "#344454"),
      axis.ticks = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(color = "#E8EDF1", linewidth = 0.35),
      panel.grid.major.y = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", color = "#263442"),
      strip.background = ggplot2::element_rect(fill = "#F2F5F7", color = NA),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.82)),
      plot.margin = ggplot2::margin(14, 18, 14, 14)
    )
}

save_poster_figure <- function(plot, filename, width, height, dpi = 600) {
  directory <- "figures/poster"
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  ggplot2::ggsave(
    filename = file.path(directory, paste0(filename, ".pdf")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    device = grDevices::pdf,
    bg = "white"
  )
  ggplot2::ggsave(
    filename = file.path(directory, paste0(filename, ".svg")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    device = svglite::svglite,
    bg = "white"
  )
  ggplot2::ggsave(
    filename = file.path(directory, paste0(filename, ".png")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white"
  )
}
