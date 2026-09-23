suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
})

source("R/project.R")
source("R/model_helpers.R")
assert_project_root()
ensure_directories()

target_responses <- read_csv(
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
  filter(item_set == "target") %>%
  droplevels()

stopifnot(nrow(target_responses) == 1800L)
stopifnot(n_distinct(target_responses$participant_id) == 90L)
stopifnot(n_distinct(target_responses$item_id) == 10L)

random_candidates <- c(
  "(1 + time | participant_id) + (1 + time | item_id)",
  "(1 + time || participant_id) + (1 + time || item_id)",
  "(1 + time || participant_id) + (1 | item_id)",
  "(1 | participant_id) + (1 + time || item_id)",
  "(1 | participant_id) + (1 | item_id)"
)

fit_result <- fit_glmm_sequence(
  data = target_responses,
  fixed_formula = "correct ~ time * condition",
  candidate_random = random_candidates,
  label = "Primary target-item GLMM"
)
primary_model <- fit_result$model

reduced_model <- update(primary_model, . ~ . - time:condition)
omnibus_lrt <- anova(reduced_model, primary_model, test = "Chisq") %>%
  as.data.frame() %>%
  rownames_to_column("model") %>%
  as_tibble()

selected_formula <- paste(deparse(stats::formula(primary_model)), collapse = " ")
model_metadata <- tibble(
  outcome = "Target-item accuracy",
  family = "Binomial logit",
  observations = stats::nobs(primary_model),
  participants = n_distinct(target_responses$participant_id),
  items = n_distinct(target_responses$item_id),
  selected_formula = selected_formula,
  selected_candidate = fit_result$selected_index,
  singular = isSingular(primary_model, tol = 1e-4),
  log_likelihood = as.numeric(logLik(primary_model)),
  AIC = AIC(primary_model),
  BIC = BIC(primary_model)
)

saveRDS(primary_model, "output/models/primary_glmm.rds")
write_csv(fit_result$selection_log, "output/diagnostics/primary_random_effects_selection.csv")
write_csv(model_metadata, "output/tables/primary_model_metadata.csv")
write_csv(tidy_fixed_effects(primary_model), "output/tables/primary_fixed_effects.csv")
write_csv(tidy_random_effects(primary_model), "output/tables/primary_random_effects.csv")
write_csv(omnibus_lrt, "output/tables/primary_interaction_lrt.csv")

model_summary <- capture.output(summary(primary_model))
writeLines(str_trim(model_summary, side = "right"), "output/models/primary_glmm_summary.txt")

message("Selected primary model candidate ", fit_result$selected_index, ".")
