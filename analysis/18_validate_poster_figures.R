suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
assert_project_root()

figure_names <- c(
  "01_primary_learning_curve",
  "02_primary_contrasts",
  "03_gain_distributions",
  "04_ancova_adjusted_posttest",
  "05_item_change_heatmap",
  "06_leave_one_item_out",
  "07_participant_influence",
  "08_crossed_bootstrap",
  "09_bayesian_sensitivity",
  "10_response_transitions",
  "11_reliability",
  "12_secondary_items",
  "13_summary_plate",
  "14_target_filler_examples",
  "15_target_filler_performance",
  "16_target_filler_plate"
)
required_files <- as.vector(outer(
  file.path("figures/poster", figure_names),
  c(".pdf", ".svg", ".png"),
  paste0
))

stopifnot(length(required_files) == 48L)
stopifnot(all(file.exists(required_files)))
stopifnot(all(file.info(required_files)$size > 1000))

png_files <- file.path("figures/poster", paste0(figure_names, ".png"))
png_signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
stopifnot(all(map_lgl(png_files, function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  identical(readBin(connection, what = "raw", n = 8), png_signature)
})))

svg_files <- file.path("figures/poster", paste0(figure_names, ".svg"))
stopifnot(all(map_lgl(svg_files, ~ any(str_detect(readLines(.x, n = 5), "<svg")))))

message("Poster figure validation passed: 16 figures in PDF, SVG, and high-resolution PNG formats.")
