suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
assert_project_root()
ensure_directories()

responses <- read_csv(
  "data/processed/responses_long.csv",
  col_types = cols(
    participant_id = col_character(),
    condition = col_factor(levels = condition_levels),
    time = col_factor(levels = time_levels),
    item_number = col_integer(),
    item_set = col_factor(levels = c("target", "secondary")),
    item_id = col_character(),
    word = col_character(),
    response = col_character(),
    correct_answer = col_character(),
    correct = col_integer()
  ),
  show_col_types = FALSE
)

participant_scores <- read_csv(
  "data/processed/participant_scores.csv",
  col_types = cols(
    participant_id = col_character(),
    condition = col_factor(levels = condition_levels),
    time = col_factor(levels = time_levels),
    .default = col_double()
  ),
  show_col_types = FALSE
)

participant_gains <- participant_scores %>%
  select(participant_id, condition, time, target_accuracy, target_correct) %>%
  pivot_wider(
    names_from = time,
    values_from = c(target_accuracy, target_correct),
    names_sep = "_"
  ) %>%
  mutate(
    gain_accuracy = `target_accuracy_Post-test` - target_accuracy_Pretest,
    gain_correct = `target_correct_Post-test` - target_correct_Pretest
  )

gain_summary <- participant_gains %>%
  group_by(condition) %>%
  summarise(
    participants = n(),
    mean_gain_correct = mean(gain_correct),
    sd_gain_correct = sd(gain_correct),
    median_gain_correct = median(gain_correct),
    q1_gain_correct = quantile(gain_correct, 0.25),
    q3_gain_correct = quantile(gain_correct, 0.75),
    mean_gain_accuracy = mean(gain_accuracy),
    .groups = "drop"
  )

item_change <- responses %>%
  filter(item_set == "target") %>%
  group_by(condition, item_id, word, time) %>%
  summarise(n = n(), accuracy = mean(correct), .groups = "drop") %>%
  pivot_wider(names_from = time, values_from = c(n, accuracy), names_sep = "_") %>%
  mutate(change_accuracy = `accuracy_Post-test` - accuracy_Pretest)

write_csv(participant_gains, "output/tables/participant_gains.csv")
write_csv(gain_summary, "output/tables/gain_summary.csv")
write_csv(item_change, "output/tables/target_item_change.csv")

message("Created participant gain and target-item change summaries.")

