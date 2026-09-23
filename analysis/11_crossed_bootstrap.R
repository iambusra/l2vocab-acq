suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
})

source("R/project.R")
source("R/model_helpers.R")
source("R/additional_helpers.R")
assert_project_root()
ensure_directories()

target_responses <- read_target_responses()
bootstrap_repetitions <- as.integer(Sys.getenv("L2V_BOOTSTRAP_REPS", "1000"))
requested_cores <- as.integer(Sys.getenv("L2V_BOOTSTRAP_CORES", "4"))
available_cores <- safe_detect_cores(default = requested_cores)
cores <- max(1L, min(requested_cores, available_cores, bootstrap_repetitions))
base_seed <- 20260923L

item_ids <- sort(unique(target_responses$item_id))

run_bootstrap <- function(repetition) {
  set.seed(base_seed + repetition)

  sampled_participants <- map_dfr(condition_levels, function(condition_name) {
    candidates <- target_responses %>%
      filter(condition == condition_name) %>%
      distinct(participant_id) %>%
      pull(participant_id)
    tibble(
      condition = condition_name,
      participant_id = sample(candidates, length(candidates), replace = TRUE),
      participant_draw = seq_along(candidates)
    )
  }) %>%
    mutate(
      condition = factor(condition, levels = condition_levels),
      bootstrap_participant_id = factor(paste(condition, participant_draw, sep = "_"))
    )

  sampled_items <- tibble(
    item_id = sample(item_ids, length(item_ids), replace = TRUE),
    item_draw = seq_along(item_ids),
    bootstrap_item_id = factor(paste0("item_draw_", item_draw))
  )

  bootstrap_data <- sampled_participants %>%
    inner_join(target_responses, by = c("participant_id", "condition")) %>%
    inner_join(sampled_items, by = "item_id") %>%
    mutate(
      time = factor(time, levels = time_levels),
      condition = factor(condition, levels = condition_levels)
    )

  tryCatch({
    model <- suppressWarnings(lme4::glmer(
      correct ~ time * condition +
        (1 | bootstrap_participant_id) + (1 | bootstrap_item_id),
      data = bootstrap_data,
      family = stats::binomial(link = "logit"),
      control = lme4::glmerControl(
        optimizer = "bobyqa",
        optCtrl = list(maxfun = 100000),
        calc.derivs = FALSE
      )
    ))
    cells <- extract_cell_predictions(model)

    bind_rows(
      cell_difference_in_differences(cells, "log_odds") %>%
        mutate(scale = "log_odds"),
      cell_difference_in_differences(cells, "probability") %>%
        mutate(scale = "probability")
    ) %>%
      mutate(
        repetition = repetition,
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
        repetition = repetition,
        fit_succeeded = FALSE,
        singular = NA,
        estimate = NA_real_,
        .before = 1
      )
  })
}

bootstrap_draws <- parallel::mclapply(
  seq_len(bootstrap_repetitions),
  run_bootstrap,
  mc.cores = cores,
  mc.preschedule = TRUE
) %>%
  bind_rows() %>%
  arrange(repetition, scale, contrast)

bootstrap_summary <- bootstrap_draws %>%
  group_by(scale, contrast) %>%
  summarise(
    requested_repetitions = bootstrap_repetitions,
    successful_repetitions = sum(fit_succeeded),
    failed_repetitions = sum(!fit_succeeded),
    singular_repetitions = sum(singular, na.rm = TRUE),
    mean_estimate = mean(estimate, na.rm = TRUE),
    median_estimate = median(estimate, na.rm = TRUE),
    conf_low_percentile = quantile(estimate, 0.025, na.rm = TRUE),
    conf_high_percentile = quantile(estimate, 0.975, na.rm = TRUE),
    proportion_above_zero = mean(estimate > 0, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(bootstrap_draws, "output/tables/crossed_bootstrap_draws.csv")
write_csv(bootstrap_summary, "output/tables/crossed_bootstrap_summary.csv")

message(
  "Completed ", bootstrap_repetitions,
  " crossed participant-item bootstrap repetitions using ", cores, " cores."
)
