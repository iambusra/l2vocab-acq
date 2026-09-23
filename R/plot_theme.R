condition_colors <- c(
  "Control" = "#5C677D",
  "Thematic" = "#2A9D8F",
  "Grounding" = "#D55E00"
)

theme_publication <- function(base_size = 11, base_family = "sans") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.15)),
      plot.subtitle = ggplot2::element_text(color = "#4B5563"),
      plot.caption = ggplot2::element_text(color = "#6B7280", hjust = 0),
      axis.title = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank()
    )
}

save_figure <- function(plot, filename, width, height) {
  ggplot2::ggsave(
    filename = file.path("figures", paste0(filename, ".pdf")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    device = grDevices::pdf
  )
  ggplot2::ggsave(
    filename = file.path("figures", paste0(filename, ".png")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 320,
    bg = "white"
  )
}
