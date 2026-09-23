suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(emmeans)
})

source("R/project.R")
source("R/model_helpers.R")
source("R/additional_helpers.R")
assert_project_root()
ensure_directories()

target_responses <- read_target_responses()
participant_index <- target_responses %>%
  distinct(participant_id) %>%
  arrange(participant_id) %>%
  mutate(excluded_case_index = row_number())

fit_without_participant <- function(row_index) {
  excluded_id <- participant_index$participant_id[[row_index]]
  analysis_data <- target_responses %>%
    filter(participant_id != excluded_id) %>%
    droplevels()

  tryCatch({
    model <- suppressWarnings(fit_random_intercept_glmm(analysis_data))
    extract_planned_contrasts(model) %>%
      mutate(
        excluded_case_index = row_index,
        fit_succeeded = TRUE,
        singular = isSingular(model, tol = 1e-4),
        .before = 1
      )
  }, error = function(error) {
    tidyr::expand_grid(
      contrast = names(planned_comparison_pairs),
      scale = c("log_odds", "probability")
    ) %>%
      mutate(
        excluded_case_index = row_index,
        fit_succeeded = FALSE,
        singular = NA,
        estimate = NA_real_,
        standard_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        z_ratio = NA_real_,
        p_value = NA_real_,
        p_value_holm = NA_real_,
        .before = 1
      )
  })
}

requested_cores <- as.integer(Sys.getenv("L2V_INFLUENCE_CORES", "4"))
available_cores <- safe_detect_cores(default = requested_cores)
cores <- max(1L, min(requested_cores, available_cores, nrow(participant_index)))

influence_results <- parallel::mclapply(
  seq_len(nrow(participant_index)),
  fit_without_participant,
  mc.cores = cores,
  mc.preschedule = TRUE
) %>%
  bind_rows()

full_probability <- read_csv(
  "output/tables/planned_contrasts_probability.csv",
  show_col_types = FALSE
) %>%
  transmute(
    contrast,
    scale = "probability",
    full_estimate = difference_in_probability_change
  )
full_link <- read_csv(
  "output/tables/planned_contrasts_log_odds.csv",
  show_col_types = FALSE
) %>%
  transmute(contrast, scale = "log_odds", full_estimate = estimate_log_odds)

influence_results <- influence_results %>%
  left_join(bind_rows(full_link, full_probability), by = c("contrast", "scale")) %>%
  mutate(change_from_full_estimate = estimate - full_estimate) %>%
  arrange(excluded_case_index, scale, contrast)

influence_summary <- influence_results %>%
  group_by(scale, contrast) %>%
  summarise(
    attempted_fits = n(),
    successful_fits = sum(fit_succeeded),
    singular_fits = sum(singular, na.rm = TRUE),
    full_estimate = first(full_estimate),
    minimum_leave_one_out_estimate = min(estimate, na.rm = TRUE),
    maximum_leave_one_out_estimate = max(estimate, na.rm = TRUE),
    maximum_absolute_change = max(abs(change_from_full_estimate), na.rm = TRUE),
    maximum_holm_p = max(p_value_holm, na.rm = TRUE),
    estimates_favor_first = sum(estimate > 0, na.rm = TRUE),
    holm_significant = sum(p_value_holm < 0.05, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(influence_results, "output/tables/participant_influence_contrasts.csv")
write_csv(influence_summary, "output/tables/participant_influence_summary.csv")

message("Completed anonymized leave-one-participant-out influence analysis using ", cores, " cores.")
