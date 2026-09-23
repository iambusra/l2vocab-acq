scripts <- c(
  "analysis/01_prepare_data.R",
  "analysis/02_descriptives.R",
  "analysis/03_primary_glmm.R",
  "analysis/04_planned_contrasts.R",
  "analysis/05_secondary_items.R",
  "analysis/06_figures.R",
  "analysis/07_diagnostics.R",
  "analysis/08_validate_outputs.R"
)

for (script in scripts) {
  message("\nRunning ", script)
  status <- system2("Rscript", script)
  if (!identical(status, 0L)) {
    stop("Pipeline failed in ", script, call. = FALSE)
  }
}

message("\nAnalysis pipeline completed successfully.")
