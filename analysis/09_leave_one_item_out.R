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
item_lookup <- target_responses %>%
  distinct(item_id, item_number, word) %>%
  arrange(item_number)

fit_without_item <- function(item_to_remove) {
  analysis_data <- target_responses %>%
    filter(item_id != item_to_remove) %>%
    droplevels()

  model <- fit_random_intercept_glmm(analysis_data)
  reduced <- update(model, . ~ . - time:condition)
  lrt <- anova(reduced, model, test = "Chisq") %>%
    as.data.frame() %>%
    slice_tail(n = 1)

  list(
    contrasts = extract_planned_contrasts(model) %>%
      mutate(
        excluded_item_id = item_to_remove,
        singular = isSingular(model, tol = 1e-4),
        .before = 1
      ),
    omnibus = tibble(
      excluded_item_id = item_to_remove,
      observations = nobs(model),
      singular = isSingular(model, tol = 1e-4),
      chi_square = lrt$Chisq,
      degrees_freedom = lrt$`Chi Df`,
      p_value = lrt$`Pr(>Chisq)`
    )
  )
}

results <- map(item_lookup$item_id, fit_without_item)

loo_contrasts <- map_dfr(results, "contrasts") %>%
  left_join(item_lookup, by = c("excluded_item_id" = "item_id")) %>%
  relocate(excluded_item_number = item_number, excluded_word = word, .after = excluded_item_id)

loo_omnibus <- map_dfr(results, "omnibus") %>%
  left_join(item_lookup, by = c("excluded_item_id" = "item_id")) %>%
  relocate(excluded_item_number = item_number, excluded_word = word, .after = excluded_item_id)

loo_summary <- loo_contrasts %>%
  group_by(scale, contrast) %>%
  summarise(
    fits = n(),
    minimum_estimate = min(estimate),
    maximum_estimate = max(estimate),
    minimum_conf_low = min(conf_low),
    maximum_conf_high = max(conf_high),
    maximum_holm_p = max(p_value_holm),
    estimates_favor_first = sum(estimate > 0),
    holm_significant = sum(p_value_holm < 0.05),
    singular_fits = sum(singular),
    .groups = "drop"
  )

write_csv(loo_contrasts, "output/tables/leave_one_item_out_contrasts.csv")
write_csv(loo_omnibus, "output/tables/leave_one_item_out_omnibus.csv")
write_csv(loo_summary, "output/tables/leave_one_item_out_summary.csv")

message("Completed 10 leave-one-target-out fits.")
