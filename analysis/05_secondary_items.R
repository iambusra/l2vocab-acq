suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(emmeans)
})

source("R/project.R")
source("R/model_helpers.R")
assert_project_root()
ensure_directories()

secondary <- read_csv(
  "data/processed/responses_long.csv",
  col_types = cols(
    participant_id = col_character(),
    condition = col_factor(levels = condition_levels),
    time = col_factor(levels = time_levels),
    item_number = col_integer(),
    item_set = col_character(),
    item_id = col_character(),
    word = col_character(),
    response = col_character(),
    correct_answer = col_character(),
    correct = col_integer()
  ),
  show_col_types = FALSE
) %>%
  filter(item_set == "secondary") %>%
  droplevels()

random_candidates <- c(
  "(1 + time | participant_id) + (1 + time | item_id)",
  "(1 + time || participant_id) + (1 + time || item_id)",
  "(1 + time || participant_id) + (1 | item_id)",
  "(1 | participant_id) + (1 + time || item_id)",
  "(1 | participant_id) + (1 | item_id)"
)

condition_results <- map(condition_levels, function(condition_name) {
  condition_data <- secondary %>%
    filter(condition == condition_name) %>%
    droplevels()

  fit_result <- fit_glmm_sequence(
    data = condition_data,
    fixed_formula = "correct ~ time",
    candidate_random = random_candidates,
    label = paste(condition_name, "secondary-item GLMM")
  )
  model <- fit_result$model
  saveRDS(
    model,
    file.path("output", "models", paste0("secondary_", str_to_lower(condition_name), ".rds"))
  )

  time_effect <- emmeans(model, ~ time) %>%
    contrast(method = list("Post-test vs Pretest" = c(-1, 1))) %>%
    summary(infer = c(TRUE, TRUE), type = "response") %>%
    as.data.frame() %>%
    as_tibble() %>%
    mutate(condition = condition_name, .before = 1)

  list(
    selection = fit_result$selection_log,
    fixed = tidy_fixed_effects(model) %>% mutate(condition = condition_name, .before = 1),
    time_effect = time_effect
  )
})

secondary_descriptives <- secondary %>%
  group_by(condition, time) %>%
  summarise(
    participants = n_distinct(participant_id),
    trials = n(),
    accuracy = mean(correct),
    correct = sum(correct),
    standard_error = sqrt(accuracy * (1 - accuracy) / trials),
    .groups = "drop"
  )

secondary_time_effects <- map_dfr(condition_results, "time_effect") %>%
  mutate(p_value_holm = p.adjust(p.value, method = "holm"))

write_csv(map_dfr(condition_results, "selection"), "output/diagnostics/secondary_random_effects_selection.csv")
write_csv(map_dfr(condition_results, "fixed"), "output/tables/secondary_fixed_effects.csv")
write_csv(secondary_time_effects, "output/tables/secondary_within_condition_time_effects.csv")
write_csv(secondary_descriptives, "output/tables/secondary_descriptives.csv")

message("Completed within-condition Q11-Q20 analyses without between-condition contrasts.")
