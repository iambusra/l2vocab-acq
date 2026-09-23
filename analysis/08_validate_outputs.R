suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
assert_project_root()

expected_sha256 <- c(
  "data/raw/pretest/Pretest scoressssss.numbers" =
    "bb20ebf21f9e1b2205c806962b4f293a2d6a2066d1eca456faee286b65f45a17",
  "data/raw/posttest/post test scores .numbers" =
    "59f572e4054de63cbf2232b82fda19f2a11cc12049ec679f44422136d8bd7b46"
)

observed_sha256 <- vapply(
  names(expected_sha256),
  function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE),
  character(1)
)
stopifnot(identical(unname(observed_sha256), unname(expected_sha256)))

responses <- read_csv(
  "data/processed/responses_long.csv",
  col_types = cols(participant_id = col_character(), .default = col_guess()),
  show_col_types = FALSE
)
scores <- read_csv(
  "data/processed/participant_scores.csv",
  col_types = cols(participant_id = col_character(), .default = col_guess()),
  show_col_types = FALSE
)

stopifnot(nrow(responses) == 3600L)
stopifnot(n_distinct(responses$participant_id) == 90L)
stopifnot(all(str_detect(responses$participant_id, "^[CTG][0-9]{2}$")))
stopifnot(!anyNA(responses))
stopifnot(all(responses$correct %in% 0:1))
stopifnot(nrow(scores) == 180L)
stopifnot(all(scores$target_total == 10L, scores$secondary_total == 10L))

required_outputs <- c(
  sprintf("figures/%02d_%s.pdf", 1:5, c(
    "model_predicted_target_accuracy",
    "participant_trajectories",
    "gain_distributions",
    "item_level_change",
    "planned_contrasts"
  )),
  sprintf("figures/%02d_%s.png", 1:5, c(
    "model_predicted_target_accuracy",
    "participant_trajectories",
    "gain_distributions",
    "item_level_change",
    "planned_contrasts"
  )),
  "output/diagnostics/primary_model_diagnostics.pdf",
  "output/diagnostics/primary_model_diagnostics.png",
  "output/tables/primary_interaction_lrt.csv",
  "output/tables/planned_contrasts_log_odds.csv",
  "output/tables/planned_contrasts_probability.csv",
  "output/tables/ancova_planned_contrasts.csv",
  "output/tables/secondary_within_condition_time_effects.csv"
)
stopifnot(all(file.exists(required_outputs)))
stopifnot(all(file.info(required_outputs)$size > 0))

model_metadata <- read_csv(
  "output/tables/primary_model_metadata.csv",
  show_col_types = FALSE
)
stopifnot(model_metadata$observations == 1800L)
stopifnot(!model_metadata$singular)

message("Validation passed: raw checksums, data structure, models, tables, and figures.")
