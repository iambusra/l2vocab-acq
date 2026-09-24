scripts <- c(
  "analysis/01_prepare_data.R",
  "analysis/02_descriptives.R",
  "analysis/03_primary_glmm.R",
  "analysis/04_planned_contrasts.R",
  "analysis/05_secondary_items.R",
  "analysis/06_figures.R",
  "analysis/07_diagnostics.R",
  "analysis/08_validate_outputs.R",
  "analysis/09_leave_one_item_out.R",
  "analysis/10_participant_influence.R",
  "analysis/11_crossed_bootstrap.R",
  "analysis/12_response_transitions.R",
  "analysis/13_bayesian_sensitivity.R",
  "analysis/14_reliability.R",
  "analysis/15_additional_figures.R",
  "analysis/16_validate_extended_outputs.R",
  "analysis/17_poster_figures.R",
  "analysis/18_validate_poster_figures.R"
)

for (script in scripts) {
  message("\nRunning ", script)
  status <- system2("Rscript", script)
  if (!identical(status, 0L)) {
    stop("Pipeline failed in ", script, call. = FALSE)
  }
}

message("\nAnalysis pipeline completed successfully.")
