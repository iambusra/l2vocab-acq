suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(posterior)
})

source("R/project.R")
source("R/model_helpers.R")
source("R/additional_helpers.R")
assert_project_root()
ensure_directories()

target_responses <- read_target_responses()
chains <- as.integer(Sys.getenv("L2V_BAYES_CHAINS", "4"))
iterations <- as.integer(Sys.getenv("L2V_BAYES_ITER", "2000"))
warmup <- as.integer(Sys.getenv("L2V_BAYES_WARMUP", as.character(iterations / 2)))
requested_cores <- as.integer(Sys.getenv("L2V_BAYES_CORES", as.character(chains)))
cores <- max(1L, min(requested_cores, safe_detect_cores(default = requested_cores), chains))
model_path <- "output/models/bayesian_random_slopes_glmm.rds"
refit <- identical(tolower(Sys.getenv("L2V_BAYES_REFIT", "false")), "true")

model_formula <- bf(
  correct ~ time * condition +
    (1 + time | participant_id) + (1 + time | item_id)
)
model_priors <- c(
  prior(normal(0, 1.5), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sd"),
  prior(lkj(2), class = "cor")
)

if (file.exists(model_path) && !refit) {
  bayesian_model <- readRDS(model_path)
  message("Reused cached Bayesian model. Set L2V_BAYES_REFIT=true to refit it.")
} else {
  options(mc.cores = cores)
  bayesian_model <- brm(
    formula = model_formula,
    data = target_responses,
    family = bernoulli(link = "logit"),
    prior = model_priors,
    backend = "rstan",
    chains = chains,
    cores = cores,
    iter = iterations,
    warmup = warmup,
    seed = 20260923,
    control = list(adapt_delta = 0.97, max_treedepth = 12),
    save_pars = save_pars(all = TRUE),
    refresh = 100
  )
  saveRDS(bayesian_model, model_path)
}

prediction_grid <- tidyr::expand_grid(
  condition = factor(condition_levels, levels = condition_levels),
  time = factor(time_levels, levels = time_levels)
)
posterior_probabilities <- posterior_epred(
  bayesian_model,
  newdata = prediction_grid,
  re_formula = NA
)
colnames(posterior_probabilities) <- paste(
  prediction_grid$condition,
  prediction_grid$time,
  sep = "__"
)

bayesian_predictions <- map_dfr(seq_len(ncol(posterior_probabilities)), function(column_index) {
  values <- posterior_probabilities[, column_index]
  tibble(
    condition = prediction_grid$condition[[column_index]],
    time = prediction_grid$time[[column_index]],
    posterior_mean = mean(values),
    posterior_median = median(values),
    conf_low = quantile(values, 0.025),
    conf_high = quantile(values, 0.975)
  )
})

posterior_changes <- tibble(
  Control = posterior_probabilities[, "Control__Post-test"] -
    posterior_probabilities[, "Control__Pretest"],
  Thematic = posterior_probabilities[, "Thematic__Post-test"] -
    posterior_probabilities[, "Thematic__Pretest"],
  Grounding = posterior_probabilities[, "Grounding__Post-test"] -
    posterior_probabilities[, "Grounding__Pretest"]
)

posterior_contrast_draws <- tibble(
  `Grounding vs Thematic` = posterior_changes$Grounding - posterior_changes$Thematic,
  `Grounding vs Control` = posterior_changes$Grounding - posterior_changes$Control,
  `Thematic vs Control` = posterior_changes$Thematic - posterior_changes$Control
) %>%
  pivot_longer(everything(), names_to = "contrast", values_to = "estimate")

strict_order_probability <- mean(
  posterior_changes$Grounding > posterior_changes$Thematic &
    posterior_changes$Thematic > posterior_changes$Control
)

bayesian_contrasts <- posterior_contrast_draws %>%
  group_by(contrast) %>%
  summarise(
    posterior_mean = mean(estimate),
    posterior_median = median(estimate),
    conf_low = quantile(estimate, 0.025),
    conf_high = quantile(estimate, 0.975),
    posterior_probability_above_zero = mean(estimate > 0),
    posterior_probability_above_0_10 = mean(estimate > 0.10),
    posterior_probability_grounding_gt_thematic_gt_control = strict_order_probability,
    posterior_draws = n(),
    .groups = "drop"
  )

parameter_diagnostics <- posterior::as_draws_df(bayesian_model) %>%
  posterior::summarise_draws(mean, sd, rhat, ess_bulk, ess_tail) %>%
  as_tibble() %>%
  filter(str_detect(variable, "^(b_|sd_|cor_)"))

sampler_parameters <- rstan::get_sampler_params(bayesian_model$fit, inc_warmup = FALSE)
divergences <- sum(vapply(
  sampler_parameters,
  function(chain) sum(chain[, "divergent__"]),
  numeric(1)
))
treedepth_hits <- sum(vapply(
  sampler_parameters,
  function(chain) sum(chain[, "treedepth__"] >= 12),
  numeric(1)
))

sampler_diagnostics <- tibble(
  metric = c(
    "Chains",
    "Iterations per chain",
    "Warmup iterations per chain",
    "Posterior draws",
    "Divergent transitions",
    "Maximum-treedepth hits",
    "Maximum R-hat",
    "Minimum bulk effective sample size",
    "Minimum tail effective sample size"
  ),
  value = c(
    chains,
    iterations,
    warmup,
    nrow(posterior_probabilities),
    divergences,
    treedepth_hits,
    max(parameter_diagnostics$rhat, na.rm = TRUE),
    min(parameter_diagnostics$ess_bulk, na.rm = TRUE),
    min(parameter_diagnostics$ess_tail, na.rm = TRUE)
  )
)

writeLines(
  str_trim(capture.output(summary(bayesian_model)), side = "right"),
  "output/models/bayesian_random_slopes_glmm_summary.txt"
)
write_csv(bayesian_predictions, "output/tables/bayesian_predicted_probabilities.csv")
write_csv(bayesian_contrasts, "output/tables/bayesian_planned_contrasts.csv")
write_csv(parameter_diagnostics, "output/diagnostics/bayesian_parameter_diagnostics.csv")
write_csv(sampler_diagnostics, "output/diagnostics/bayesian_sampler_diagnostics.csv")

message("Completed Bayesian random-slopes sensitivity analysis.")
