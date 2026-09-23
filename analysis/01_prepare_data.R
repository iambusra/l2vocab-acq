suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
assert_project_root()
ensure_directories()

read_responses <- function(wave, time_label) {
  read_csv(
    file.path("data", "interim", paste0(wave, "_responses.csv")),
    col_types = cols(.default = col_character()),
    show_col_types = FALSE
  ) %>%
    mutate(time = time_label)
}

pretest <- read_responses("pretest", "Pretest")
posttest <- read_responses("posttest", "Post-test")

expected_response_columns <- c(
  "participant_id", "condition",
  sprintf("q%02d_response", 1:20),
  "time"
)
stopifnot(identical(names(pretest), expected_response_columns))
stopifnot(identical(names(posttest), expected_response_columns))
stopifnot(nrow(pretest) == 90L, nrow(posttest) == 90L)
stopifnot(n_distinct(pretest$participant_id) == 90L)
stopifnot(n_distinct(posttest$participant_id) == 90L)

participant_check <- full_join(
  pretest %>% select(participant_id, pre_condition = condition),
  posttest %>% select(participant_id, post_condition = condition),
  by = "participant_id"
)
stopifnot(nrow(participant_check) == 90L)
stopifnot(!anyNA(participant_check))
stopifnot(all(participant_check$pre_condition == participant_check$post_condition))

pretest_keys <- read_csv(
  "data/interim/pretest_keys.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)
posttest_keys <- read_csv(
  "data/interim/posttest_keys.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)
stopifnot(isTRUE(all.equal(
  as.data.frame(pretest_keys),
  as.data.frame(posttest_keys),
  check.attributes = FALSE
)))
stopifnot(nrow(pretest_keys) == 10L)

item_key <- bind_rows(
  pretest_keys %>%
    transmute(
      item_number = row_number(),
      item_set = "target",
      condition = "All",
      item_id = sprintf("target_%02d", item_number),
      word = target_word,
      correct_answer = str_to_upper(target_key)
    ),
  pretest_keys %>%
    transmute(
      item_number = row_number() + 10L,
      item_set = "secondary",
      condition = "Grounding",
      item_id = sprintf("secondary_grounding_%02d", item_number),
      word = grounding_word,
      correct_answer = str_to_upper(grounding_key)
    ),
  pretest_keys %>%
    transmute(
      item_number = row_number() + 10L,
      item_set = "secondary",
      condition = "Thematic",
      item_id = sprintf("secondary_thematic_%02d", item_number),
      word = thematic_word,
      correct_answer = str_to_upper(thematic_key)
    ),
  pretest_keys %>%
    transmute(
      item_number = row_number() + 10L,
      item_set = "secondary",
      condition = "Control",
      item_id = sprintf("secondary_control_%02d", item_number),
      word = control_word,
      correct_answer = str_to_upper(control_key)
    )
) %>%
  arrange(item_set, condition, item_number)

responses_long <- bind_rows(pretest, posttest) %>%
  pivot_longer(
    cols = matches("^q\\d{2}_response$"),
    names_to = "question",
    values_to = "response"
  ) %>%
  mutate(
    item_number = as.integer(str_extract(question, "\\d+")),
    item_set = if_else(item_number <= 10L, "target", "secondary"),
    join_condition = if_else(item_set == "target", "All", condition),
    response = str_to_upper(str_trim(response))
  ) %>%
  left_join(
    item_key %>% rename(join_condition = condition),
    by = c("item_number", "item_set", "join_condition")
  ) %>%
  transmute(
    participant_id,
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = time_levels),
    item_number,
    item_set = factor(item_set, levels = c("target", "secondary")),
    item_id,
    word,
    response,
    correct_answer,
    correct = as.integer(response == correct_answer)
  ) %>%
  arrange(participant_id, time, item_number)

stopifnot(nrow(responses_long) == 3600L)
stopifnot(!anyNA(responses_long))
stopifnot(all(responses_long$response %in% LETTERS[1:4]))
stopifnot(all(responses_long$correct %in% 0:1))

participant_scores <- responses_long %>%
  group_by(participant_id, condition, time, item_set) %>%
  summarise(
    total = n(),
    accuracy = mean(correct),
    correct = sum(correct),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = item_set,
    values_from = c(correct, total, accuracy),
    names_glue = "{item_set}_{.value}"
  ) %>%
  arrange(participant_id, time)

item_summary <- responses_long %>%
  group_by(item_set, item_id, word, condition, time) %>%
  summarise(
    n = n(),
    accuracy = mean(correct),
    correct = sum(correct),
    standard_error = sqrt(accuracy * (1 - accuracy) / n),
    .groups = "drop"
  ) %>%
  mutate(item_number = as.integer(str_extract(item_id, "\\d+$"))) %>%
  arrange(item_set, item_number, condition, time) %>%
  select(-item_number)

condition_time_summary <- participant_scores %>%
  group_by(condition, time) %>%
  summarise(
    participants = n(),
    target_mean_correct = mean(target_correct),
    target_sd_correct = sd(target_correct),
    target_mean_accuracy = mean(target_accuracy),
    target_se_accuracy = sd(target_accuracy) / sqrt(n()),
    secondary_mean_correct = mean(secondary_correct),
    secondary_sd_correct = sd(secondary_correct),
    secondary_mean_accuracy = mean(secondary_accuracy),
    secondary_se_accuracy = sd(secondary_accuracy) / sqrt(n()),
    .groups = "drop"
  )

expected_target_means <- tribble(
  ~condition, ~time, ~expected,
  "Control", "Pretest", 4.20,
  "Control", "Post-test", 5.30,
  "Thematic", "Pretest", 4.27,
  "Thematic", "Post-test", 6.57,
  "Grounding", "Pretest", 4.30,
  "Grounding", "Post-test", 8.30
)
mean_check <- condition_time_summary %>%
  mutate(condition = as.character(condition), time = as.character(time)) %>%
  inner_join(expected_target_means, by = c("condition", "time"))
stopifnot(all(abs(mean_check$target_mean_correct - mean_check$expected) < 0.005))

write_csv(responses_long, "data/processed/responses_long.csv")
write_csv(participant_scores, "data/processed/participant_scores.csv")
write_csv(item_summary, "data/processed/item_summary.csv")
write_csv(item_key, "data/processed/item_key.csv")
write_csv(condition_time_summary, "output/tables/descriptive_condition_time.csv")

message(
  "Prepared ", nrow(responses_long), " scored responses from ",
  n_distinct(responses_long$participant_id), " coded participants."
)
