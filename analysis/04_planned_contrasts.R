suppressPackageStartupMessages({
  library(tidyverse)
  library(emmeans)
})

source("R/project.R")
source("R/model_helpers.R")
assert_project_root()
ensure_directories()

primary_model <- readRDS("output/models/primary_glmm.rds")
primary_emmeans <- emmeans(primary_model, ~ condition * time)

predicted_probabilities <- summary(
  primary_emmeans,
  type = "response",
  infer = c(TRUE, FALSE)
) %>%
  as.data.frame() %>%
  as_tibble() %>%
  transmute(
    condition,
    time,
    predicted_probability = prob,
    standard_error = SE,
    conf_low = asymp.LCL,
    conf_high = asymp.UCL
  )

comparison_pairs <- list(
  c("Grounding", "Thematic"),
  c("Grounding", "Control"),
  c("Thematic", "Control")
)
names(comparison_pairs) <- c(
  "Grounding vs Thematic",
  "Grounding vs Control",
  "Thematic vs Control"
)

weights <- contrast_weights(primary_emmeans, comparison_pairs)
names(weights) <- names(comparison_pairs)

planned_link_grid <- contrast(primary_emmeans, method = weights)
planned_link_p <- planned_link_grid %>%
  summary(infer = c(FALSE, TRUE), adjust = "holm") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(contrast, p_value_holm = p.value)

planned_link <- planned_link_grid %>%
  summary(infer = c(TRUE, TRUE), adjust = "none") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(-p.value) %>%
  left_join(planned_link_p, by = "contrast") %>%
  transmute(
    contrast,
    estimate_log_odds = estimate,
    standard_error = SE,
    degrees_freedom = df,
    conf_low_log_odds = asymp.LCL,
    conf_high_log_odds = asymp.UCL,
    z_ratio = z.ratio,
    p_value_holm,
    ratio_of_odds_ratios = exp(estimate_log_odds),
    conf_low_ratio_of_odds_ratios = exp(conf_low_log_odds),
    conf_high_ratio_of_odds_ratios = exp(conf_high_log_odds)
  )

probability_grid <- regrid(primary_emmeans, transform = "response")
planned_probability_grid <- contrast(probability_grid, method = weights)
planned_probability_p <- planned_probability_grid %>%
  summary(infer = c(FALSE, TRUE), adjust = "holm") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(contrast, p_value_holm = p.value)

planned_probability <- planned_probability_grid %>%
  summary(infer = c(TRUE, TRUE), adjust = "none") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(-p.value) %>%
  left_join(planned_probability_p, by = "contrast") %>%
  transmute(
    contrast,
    difference_in_probability_change = estimate,
    standard_error = SE,
    degrees_freedom = df,
    conf_low = asymp.LCL,
    conf_high = asymp.UCL,
    z_ratio = z.ratio,
    p_value_holm
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

ancova_data <- participant_scores %>%
  select(participant_id, condition, time, target_correct, target_total, target_accuracy) %>%
  pivot_wider(
    names_from = time,
    values_from = c(target_correct, target_total, target_accuracy),
    names_sep = "_"
  ) %>%
  mutate(
    pretest_accuracy_centered = target_accuracy_Pretest - mean(target_accuracy_Pretest),
    posttest_incorrect = `target_total_Post-test` - `target_correct_Post-test`
  )

ancova_model <- glm(
  cbind(`target_correct_Post-test`, posttest_incorrect) ~
    condition + pretest_accuracy_centered,
  data = ancova_data,
  family = binomial(link = "logit")
)

ancova_emmeans <- emmeans(ancova_model, ~ condition, type = "response")
ancova_predictions <- summary(ancova_emmeans, infer = c(TRUE, FALSE)) %>%
  as.data.frame() %>%
  as_tibble()
ancova_contrast_grid <- contrast(
  ancova_emmeans,
  method = list(
    "Grounding vs Thematic" = c(0, -1, 1),
    "Grounding vs Control" = c(-1, 0, 1),
    "Thematic vs Control" = c(-1, 1, 0)
  ),
  adjust = "none"
)
ancova_contrast_p <- ancova_contrast_grid %>%
  summary(infer = c(FALSE, TRUE), type = "response", adjust = "holm") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(contrast, p_value_holm = p.value)
ancova_contrasts <- ancova_contrast_grid %>%
  summary(infer = c(TRUE, TRUE), type = "response", adjust = "none") %>%
  as.data.frame() %>%
  as_tibble() %>%
  select(-p.value) %>%
  left_join(ancova_contrast_p, by = "contrast")

ancova_coefficients <- as.data.frame(summary(ancova_model)$coefficients) %>%
  rownames_to_column("term") %>%
  as_tibble() %>%
  transmute(
    term,
    estimate_log_odds = Estimate,
    standard_error = `Std. Error`,
    z_value = `z value`,
    p_value = `Pr(>|z|)`,
    odds_ratio = exp(estimate_log_odds),
    conf_low_odds_ratio = exp(estimate_log_odds - qnorm(0.975) * standard_error),
    conf_high_odds_ratio = exp(estimate_log_odds + qnorm(0.975) * standard_error)
  )

ancova_metadata <- tibble(
  observations = nobs(ancova_model),
  residual_deviance = deviance(ancova_model),
  residual_degrees_freedom = df.residual(ancova_model),
  dispersion_ratio = deviance(ancova_model) / df.residual(ancova_model),
  AIC = AIC(ancova_model)
)

saveRDS(ancova_model, "output/models/participant_ancova.rds")
write_csv(predicted_probabilities, "output/tables/primary_predicted_probabilities.csv")
write_csv(planned_link, "output/tables/planned_contrasts_log_odds.csv")
write_csv(planned_probability, "output/tables/planned_contrasts_probability.csv")
write_csv(ancova_predictions, "output/tables/ancova_predicted_probabilities.csv")
write_csv(ancova_contrasts, "output/tables/ancova_planned_contrasts.csv")
write_csv(ancova_coefficients, "output/tables/ancova_coefficients.csv")
write_csv(ancova_metadata, "output/diagnostics/ancova_model_diagnostics.csv")

capture.output(summary(ancova_model), file = "output/models/participant_ancova_summary.txt")

message("Created planned interaction contrasts and participant-level ANCOVA results.")
