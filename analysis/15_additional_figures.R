suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

source("R/project.R")
source("R/plot_theme.R")
assert_project_root()
ensure_directories()

contrast_levels <- rev(c(
  "Grounding vs Thematic",
  "Grounding vs Control",
  "Thematic vs Control"
))

primary <- read_csv(
  "output/tables/planned_contrasts_probability.csv",
  show_col_types = FALSE
) %>%
  transmute(
    contrast,
    method = "Primary GLMM 95% CI",
    estimate = difference_in_probability_change,
    interval_low = conf_low,
    interval_high = conf_high
  )

leave_item <- read_csv(
  "output/tables/leave_one_item_out_summary.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  transmute(
    contrast,
    method = "Leave-one-item estimate range",
    estimate = (minimum_estimate + maximum_estimate) / 2,
    interval_low = minimum_estimate,
    interval_high = maximum_estimate
  )

leave_participant <- read_csv(
  "output/tables/participant_influence_summary.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  transmute(
    contrast,
    method = "Leave-one-participant estimate range",
    estimate = full_estimate,
    interval_low = minimum_leave_one_out_estimate,
    interval_high = maximum_leave_one_out_estimate
  )

crossed_bootstrap <- read_csv(
  "output/tables/crossed_bootstrap_summary.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  transmute(
    contrast,
    method = "Crossed bootstrap 95% interval",
    estimate = median_estimate,
    interval_low = conf_low_percentile,
    interval_high = conf_high_percentile
  )

bayesian <- read_csv(
  "output/tables/bayesian_planned_contrasts.csv",
  show_col_types = FALSE
) %>%
  transmute(
    contrast,
    method = "Bayesian 95% credible interval",
    estimate = posterior_mean,
    interval_low = conf_low,
    interval_high = conf_high
  )

sensitivity_data <- bind_rows(
  primary,
  leave_item,
  leave_participant,
  crossed_bootstrap,
  bayesian
) %>%
  mutate(
    contrast = factor(contrast, levels = contrast_levels),
    method = factor(method, levels = unique(method))
  )

sensitivity_plot <- ggplot(
  sensitivity_data,
  aes(x = estimate, y = method, xmin = interval_low, xmax = interval_high)
) +
  geom_vline(xintercept = 0, color = "#6B7280", linewidth = 0.5) +
  geom_errorbarh(height = 0.16, linewidth = 0.7, color = "#374151") +
  geom_point(size = 2.4, color = "#D55E00") +
  facet_wrap(~ contrast, ncol = 1) +
  scale_x_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Sensitivity of condition differences in change",
    subtitle = "Positive estimates favor the condition named first",
    x = "Difference in pre-to-post probability change",
    y = NULL,
    caption = "Deletion rows show estimate ranges, not confidence intervals. Other rows show 95% intervals."
  ) +
  theme_publication()

transition_data <- read_csv(
  "output/tables/response_transition_summary.csv",
  col_types = cols(
    condition = readr::col_factor(levels = condition_levels),
    .default = readr::col_guess()
  ),
  show_col_types = FALSE
) %>%
  mutate(
    transition = factor(
      transition,
      levels = c(
        "Correct to correct",
        "Incorrect to correct",
        "Correct to incorrect",
        "Incorrect to incorrect"
      )
    )
  )

transition_colors <- c(
  "Correct to correct" = "#2A9D8F",
  "Incorrect to correct" = "#72B7A7",
  "Correct to incorrect" = "#E9A37A",
  "Incorrect to incorrect" = "#5C677D"
)

transition_plot <- ggplot(
  transition_data,
  aes(x = condition, y = proportion, fill = transition)
) +
  geom_col(width = 0.72, color = "white", linewidth = 0.25) +
  scale_fill_manual(values = transition_colors) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Target-item response transitions",
    subtitle = "Paired pretest and post-test responses across 10 common targets",
    x = NULL,
    y = "Proportion of responses",
    caption = "Because question formats changed, these are response transitions, not pure knowledge-state transitions."
  ) +
  theme_publication()

reliability_data <- read_csv(
  "output/tables/reliability_kr20.csv",
  show_col_types = FALSE
) %>%
  mutate(
    group = factor(
      condition,
      levels = c("All conditions", condition_levels)
    ),
    time = factor(time, levels = time_levels)
  )

reliability_plot <- ggplot(
  reliability_data,
  aes(
    x = kr20,
    y = group,
    xmin = bootstrap_conf_low,
    xmax = bootstrap_conf_high,
    color = time
  )
) +
  geom_vline(xintercept = 0.70, color = "#9CA3AF", linetype = "dashed") +
  geom_errorbarh(
    height = 0.16,
    linewidth = 0.7,
    position = position_dodge(width = 0.45)
  ) +
  geom_point(size = 2.5, position = position_dodge(width = 0.45)) +
  scale_color_manual(values = c("Pretest" = "#5C677D", "Post-test" = "#D55E00")) +
  labs(
    title = "Internal consistency of the 10 target items",
    subtitle = "KR-20 estimates with participant-bootstrap 95% intervals",
    x = "KR-20",
    y = NULL,
    caption = "Within-condition estimates use 30 participants and are consequently imprecise."
  ) +
  theme_publication()

save_figure(sensitivity_plot, "06_sensitivity_contrasts", 8.0, 8.2)
save_figure(transition_plot, "07_response_transitions", 7.2, 5.2)
save_figure(reliability_plot, "08_reliability", 7.4, 4.8)

message("Saved three additional publication figures in PDF and PNG formats.")
