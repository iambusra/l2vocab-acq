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

transition_data <- target_responses %>%
  select(participant_id, condition, item_id, word, time, correct) %>%
  pivot_wider(names_from = time, values_from = correct) %>%
  transmute(
    participant_id,
    condition,
    item_id,
    word,
    pre_correct_binary = Pretest,
    pre_correct = factor(
      Pretest,
      levels = c(0, 1),
      labels = c("Pretest incorrect", "Pretest correct")
    ),
    post_correct = `Post-test`,
    transition = factor(
      case_when(
        Pretest == 0 & `Post-test` == 0 ~ "Incorrect to incorrect",
        Pretest == 0 & `Post-test` == 1 ~ "Incorrect to correct",
        Pretest == 1 & `Post-test` == 0 ~ "Correct to incorrect",
        Pretest == 1 & `Post-test` == 1 ~ "Correct to correct"
      ),
      levels = c(
        "Incorrect to incorrect",
        "Incorrect to correct",
        "Correct to incorrect",
        "Correct to correct"
      )
    )
  )

stopifnot(nrow(transition_data) == 900L)

transition_summary <- transition_data %>%
  count(condition, transition, name = "trials") %>%
  group_by(condition) %>%
  mutate(
    total_trials = sum(trials),
    proportion = trials / total_trials
  ) %>%
  ungroup()

transition_model <- glmer(
  post_correct ~ pre_correct * condition +
    (1 | participant_id) + (1 | item_id),
  data = transition_data,
  family = binomial(link = "logit"),
  control = glmerControl(
    optimizer = "bobyqa",
    optCtrl = list(maxfun = 200000),
    calc.derivs = TRUE
  )
)

transition_emmeans <- emmeans(transition_model, ~ condition | pre_correct)
transition_predictions <- summary(
  transition_emmeans,
  type = "response",
  infer = c(TRUE, FALSE)
) %>%
  as.data.frame() %>%
  as_tibble() %>%
  transmute(
    pre_correct,
    condition,
    predicted_post_probability = prob,
    standard_error = SE,
    conf_low = asymp.LCL,
    conf_high = asymp.UCL
  )

comparison_weights <- list(
  "Grounding vs Thematic" = c(0, -1, 1),
  "Grounding vs Control" = c(-1, 0, 1),
  "Thematic vs Control" = c(-1, 1, 0)
)

link_contrasts <- contrast(
  transition_emmeans,
  method = comparison_weights,
  adjust = "none"
) %>%
  summary(infer = c(TRUE, TRUE), adjust = "none") %>%
  as.data.frame() %>%
  as_tibble() %>%
  transmute(
    pre_correct,
    contrast,
    scale = "log_odds",
    estimate,
    standard_error = SE,
    conf_low = asymp.LCL,
    conf_high = asymp.UCL,
    z_ratio = z.ratio,
    p_value = p.value
  )

probability_contrasts <- transition_emmeans %>%
  regrid(transform = "response") %>%
  contrast(method = comparison_weights, adjust = "none") %>%
  summary(infer = c(TRUE, TRUE), adjust = "none") %>%
  as.data.frame() %>%
  as_tibble() %>%
  transmute(
    pre_correct,
    contrast,
    scale = "probability",
    estimate,
    standard_error = SE,
    conf_low = asymp.LCL,
    conf_high = asymp.UCL,
    z_ratio = z.ratio,
    p_value = p.value
  )

transition_contrasts <- bind_rows(link_contrasts, probability_contrasts) %>%
  group_by(pre_correct, scale) %>%
  mutate(p_value_holm = p.adjust(p_value, method = "holm")) %>%
  ungroup()

transition_metadata <- tibble(
  observations = nobs(transition_model),
  participants = n_distinct(transition_data$participant_id),
  items = n_distinct(transition_data$item_id),
  selected_formula = paste(deparse(formula(transition_model)), collapse = " "),
  singular = isSingular(transition_model, tol = 1e-4),
  AIC = AIC(transition_model),
  BIC = BIC(transition_model)
)

saveRDS(transition_model, "output/models/response_transition_glmm.rds")
writeLines(
  str_trim(capture.output(summary(transition_model)), side = "right"),
  "output/models/response_transition_glmm_summary.txt"
)
write_csv(transition_summary, "output/tables/response_transition_summary.csv")
write_csv(tidy_fixed_effects(transition_model), "output/tables/response_transition_model_fixed_effects.csv")
write_csv(tidy_random_effects(transition_model), "output/tables/response_transition_random_effects.csv")
write_csv(transition_predictions, "output/tables/response_transition_predictions.csv")
write_csv(transition_contrasts, "output/tables/response_transition_contrasts.csv")
write_csv(transition_metadata, "output/diagnostics/response_transition_model_metadata.csv")

message("Completed descriptive and model-based response-transition analyses.")
