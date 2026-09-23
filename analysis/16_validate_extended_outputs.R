suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
assert_project_root()

required_outputs <- c(
  "output/tables/leave_one_item_out_contrasts.csv",
  "output/tables/leave_one_item_out_omnibus.csv",
  "output/tables/leave_one_item_out_summary.csv",
  "output/tables/participant_influence_contrasts.csv",
  "output/tables/participant_influence_summary.csv",
  "output/tables/crossed_bootstrap_draws.csv",
  "output/tables/crossed_bootstrap_summary.csv",
  "output/tables/response_transition_summary.csv",
  "output/tables/response_transition_model_fixed_effects.csv",
  "output/tables/response_transition_random_effects.csv",
  "output/tables/response_transition_predictions.csv",
  "output/tables/response_transition_contrasts.csv",
  "output/tables/bayesian_predicted_probabilities.csv",
  "output/tables/bayesian_planned_contrasts.csv",
  "output/tables/reliability_kr20.csv",
  "output/tables/prepost_score_correlations.csv",
  "output/diagnostics/bayesian_parameter_diagnostics.csv",
  "output/diagnostics/bayesian_sampler_diagnostics.csv",
  "output/models/bayesian_random_slopes_glmm_summary.txt",
  "output/models/response_transition_glmm_summary.txt",
  sprintf("figures/%02d_%s.pdf", 6:8, c(
    "sensitivity_contrasts",
    "response_transitions",
    "reliability"
  )),
  sprintf("figures/%02d_%s.png", 6:8, c(
    "sensitivity_contrasts",
    "response_transitions",
    "reliability"
  ))
)
stopifnot(all(file.exists(required_outputs)))
stopifnot(all(file.info(required_outputs)$size > 0))

leave_item <- read_csv("output/tables/leave_one_item_out_summary.csv", show_col_types = FALSE)
stopifnot(all(leave_item$fits == 10L))
stopifnot(all(leave_item$estimates_favor_first == 10L))

influence <- read_csv("output/tables/participant_influence_contrasts.csv", show_col_types = FALSE)
stopifnot(!"participant_id" %in% names(influence))
stopifnot(n_distinct(influence$excluded_case_index) == 90L)
stopifnot(all(influence$fit_succeeded))

bootstrap <- read_csv("output/tables/crossed_bootstrap_summary.csv", show_col_types = FALSE)
stopifnot(all(bootstrap$successful_repetitions >= 0.95 * bootstrap$requested_repetitions))

transitions <- read_csv("output/tables/response_transition_summary.csv", show_col_types = FALSE)
stopifnot(sum(transitions$trials) == 900L)
stopifnot(all(abs(transitions %>% group_by(condition) %>% summarise(x = sum(proportion)) %>% pull(x) - 1) < 1e-10))

bayesian_contrasts <- read_csv(
  "output/tables/bayesian_planned_contrasts.csv",
  show_col_types = FALSE
)
stopifnot(all(bayesian_contrasts$posterior_mean > 0))

sampler <- read_csv(
  "output/diagnostics/bayesian_sampler_diagnostics.csv",
  show_col_types = FALSE
)
sampler_value <- setNames(sampler$value, sampler$metric)
stopifnot(sampler_value[["Maximum R-hat"]] < 1.05)
stopifnot(sampler_value[["Divergent transitions"]] == 0)

reliability <- read_csv("output/tables/reliability_kr20.csv", show_col_types = FALSE)
stopifnot(nrow(reliability) == 8L)
stopifnot(all(is.finite(reliability$kr20)))

message("Extended validation passed: sensitivity analyses, privacy checks, diagnostics, tables, and figures.")
