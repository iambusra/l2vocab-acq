suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(patchwork)
})

source("R/project.R")
source("R/plot_theme.R")
assert_project_root()
ensure_directories()

model <- readRDS("output/models/primary_glmm.rds")
model_data <- model.frame(model)

diagnostic_rows <- tibble(
  fitted_probability = fitted(model),
  pearson_residual = residuals(model, type = "pearson"),
  response_residual = residuals(model, type = "response"),
  condition = model_data$condition,
  time = model_data$time,
  observed = model.response(model_data)
)

pearson_chisq <- sum(diagnostic_rows$pearson_residual^2)
residual_df <- df.residual(model)
model_matrix <- model.matrix(model)

diagnostic_summary <- tibble(
  metric = c(
    "Pearson chi-square",
    "Residual degrees of freedom",
    "Pearson dispersion ratio",
    "Approximate overdispersion p-value",
    "Fixed-effect design matrix condition number",
    "Minimum fitted probability",
    "Maximum fitted probability",
    "Maximum absolute Pearson residual",
    "Singular fit"
  ),
  value = c(
    as.character(pearson_chisq),
    as.character(residual_df),
    as.character(pearson_chisq / residual_df),
    as.character(pchisq(pearson_chisq, df = residual_df, lower.tail = FALSE)),
    as.character(kappa(model_matrix)),
    as.character(min(diagnostic_rows$fitted_probability)),
    as.character(max(diagnostic_rows$fitted_probability)),
    as.character(max(abs(diagnostic_rows$pearson_residual))),
    as.character(isSingular(model, tol = 1e-4))
  )
)

calibration_by_bin <- diagnostic_rows %>%
  mutate(fitted_decile = ntile(fitted_probability, 10)) %>%
  group_by(fitted_decile) %>%
  summarise(
    trials = n(),
    mean_fitted = mean(fitted_probability),
    observed_accuracy = mean(observed),
    mean_pearson_residual = mean(pearson_residual),
    residual_standard_error = sd(pearson_residual) / sqrt(n()),
    .groups = "drop"
  )

calibration_by_cell <- diagnostic_rows %>%
  group_by(condition, time) %>%
  summarise(
    trials = n(),
    mean_fitted = mean(fitted_probability),
    observed_accuracy = mean(observed),
    mean_pearson_residual = mean(pearson_residual),
    .groups = "drop"
  )

random_effect_values <- ranef(model) %>%
  imap_dfr(function(effect_table, group_name) {
    as_tibble(effect_table) %>%
      pivot_longer(everything(), names_to = "term", values_to = "random_effect") %>%
      mutate(group = group_name, .before = 1)
  })

write_csv(diagnostic_summary, "output/diagnostics/primary_diagnostic_summary.csv")
write_csv(calibration_by_bin, "output/diagnostics/primary_calibration_by_decile.csv")
write_csv(calibration_by_cell, "output/diagnostics/primary_calibration_by_condition_time.csv")

residual_bin_plot <- ggplot(
  calibration_by_bin,
  aes(x = mean_fitted, y = mean_pearson_residual)
) +
  geom_hline(yintercept = 0, color = "#6B7280", linewidth = 0.5) +
  geom_errorbar(
    aes(
      ymin = mean_pearson_residual - 1.96 * residual_standard_error,
      ymax = mean_pearson_residual + 1.96 * residual_standard_error
    ),
    width = 0.015,
    color = "#374151"
  ) +
  geom_point(color = "#D55E00", size = 2.3) +
  labs(
    title = "Binned Pearson residuals",
    x = "Mean fitted probability",
    y = "Mean Pearson residual"
  ) +
  theme_publication()

calibration_plot <- ggplot(
  calibration_by_cell,
  aes(x = mean_fitted, y = observed_accuracy, color = condition)
) +
  geom_abline(intercept = 0, slope = 1, color = "#6B7280", linetype = "dashed") +
  geom_point(size = 2.8) +
  scale_color_manual(values = condition_colors) +
  facet_wrap(~ time) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    title = "Observed versus fitted accuracy",
    x = "Mean fitted probability",
    y = "Observed accuracy"
  ) +
  theme_publication()

residual_histogram <- ggplot(diagnostic_rows, aes(x = pearson_residual)) +
  geom_histogram(bins = 30, fill = "#5C677D", color = "white", linewidth = 0.25) +
  labs(
    title = "Pearson residual distribution",
    x = "Pearson residual",
    y = "Trial count"
  ) +
  theme_publication()

random_effect_qq <- ggplot(random_effect_values, aes(sample = random_effect)) +
  stat_qq(color = "#2A9D8F", alpha = 0.72) +
  stat_qq_line(color = "#374151") +
  facet_wrap(~ group, scales = "free") +
  labs(
    title = "Random-intercept Q-Q plots",
    x = "Theoretical quantile",
    y = "Observed quantile"
  ) +
  theme_publication()

diagnostic_panel <- (residual_bin_plot | calibration_plot) /
  (residual_histogram | random_effect_qq) +
  plot_annotation(title = "Primary model diagnostics")

ggsave(
  "output/diagnostics/primary_model_diagnostics.pdf",
  diagnostic_panel,
  width = 10,
  height = 8,
  device = grDevices::pdf
)
ggsave(
  "output/diagnostics/primary_model_diagnostics.png",
  diagnostic_panel,
  width = 10,
  height = 8,
  dpi = 240,
  bg = "white"
)

message("Saved aggregated primary-model diagnostics without participant identifiers.")
