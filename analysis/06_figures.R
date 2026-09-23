suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

source("R/project.R")
source("R/plot_theme.R")
assert_project_root()
ensure_directories()

predictions <- read_csv(
  "output/tables/primary_predicted_probabilities.csv",
  col_types = cols(
    condition = readr::col_factor(levels = condition_levels),
    time = readr::col_factor(levels = time_levels),
    .default = readr::col_double()
  ),
  show_col_types = FALSE
)

participant_scores <- read_csv(
  "data/processed/participant_scores.csv",
  col_types = cols(
    participant_id = readr::col_character(),
    condition = readr::col_factor(levels = condition_levels),
    time = readr::col_factor(levels = time_levels),
    .default = readr::col_double()
  ),
  show_col_types = FALSE
)

participant_gains <- read_csv(
  "output/tables/participant_gains.csv",
  col_types = cols(
    participant_id = readr::col_character(),
    condition = readr::col_factor(levels = condition_levels),
    .default = readr::col_double()
  ),
  show_col_types = FALSE
)

item_change <- read_csv(
  "output/tables/target_item_change.csv",
  col_types = cols(
    condition = readr::col_factor(levels = condition_levels),
    .default = readr::col_guess()
  ),
  show_col_types = FALSE
)

planned_probability <- read_csv(
  "output/tables/planned_contrasts_probability.csv",
  show_col_types = FALSE
) %>%
  mutate(
    contrast = factor(
      contrast,
      levels = rev(c(
        "Grounding vs Thematic",
        "Grounding vs Control",
        "Thematic vs Control"
      ))
    )
  )

prediction_plot <- ggplot(
  predictions,
  aes(x = time, y = predicted_probability, color = condition, group = condition)
) +
  geom_line(linewidth = 0.9) +
  geom_errorbar(
    aes(ymin = conf_low, ymax = conf_high),
    width = 0.08,
    linewidth = 0.7
  ) +
  geom_point(size = 2.7) +
  scale_color_manual(values = condition_colors) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = label_percent(accuracy = 1),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Model-predicted target-word accuracy",
    subtitle = "Estimated probabilities and 95% confidence intervals",
    x = NULL,
    y = "Probability correct",
    caption = "Binomial mixed model with participant and target-item random intercepts."
  ) +
  theme_publication()

trajectory_plot <- ggplot(
  participant_scores,
  aes(x = time, y = target_accuracy, group = participant_id, color = condition)
) +
  geom_line(alpha = 0.20, linewidth = 0.45, show.legend = FALSE) +
  geom_point(alpha = 0.35, size = 1.0, show.legend = FALSE) +
  stat_summary(
    aes(group = condition),
    fun = mean,
    geom = "line",
    linewidth = 1.3,
    show.legend = FALSE
  ) +
  stat_summary(
    aes(group = condition),
    fun = mean,
    geom = "point",
    size = 2.8,
    shape = 21,
    fill = "white",
    stroke = 1,
    show.legend = FALSE
  ) +
  facet_wrap(~ condition, nrow = 1) +
  scale_color_manual(values = condition_colors) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = label_percent(accuracy = 1),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Participant target-word trajectories",
    subtitle = "Thin lines show coded participants; thick lines show group means",
    x = NULL,
    y = "Accuracy"
  ) +
  theme_publication() +
  theme(legend.position = "none")

gain_plot <- ggplot(
  participant_gains,
  aes(x = condition, y = gain_correct, fill = condition, color = condition)
) +
  geom_violin(width = 0.82, alpha = 0.22, linewidth = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.20, outlier.shape = NA, alpha = 0.72, color = "white") +
  geom_jitter(width = 0.10, height = 0, size = 1.3, alpha = 0.55) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#4B5563") +
  scale_fill_manual(values = condition_colors) +
  scale_color_manual(values = condition_colors) +
  scale_y_continuous(breaks = seq(-4, 8, 2)) +
  labs(
    title = "Distribution of participant gains",
    subtitle = "Post-test minus pretest correct responses on 10 common targets",
    x = NULL,
    y = "Gain in correct responses"
  ) +
  theme_publication() +
  theme(legend.position = "none")

target_order <- read_csv(
  "data/processed/item_key.csv",
  show_col_types = FALSE
) %>%
  filter(item_set == "target") %>%
  arrange(item_number) %>%
  pull(word)

item_change_plot <- item_change %>%
  mutate(word = factor(word, levels = rev(target_order))) %>%
  ggplot(aes(x = change_accuracy, y = word, color = condition)) +
  geom_vline(xintercept = 0, color = "#6B7280", linewidth = 0.5) +
  geom_point(
    position = position_dodge(width = 0.52),
    size = 2.3
  ) +
  scale_color_manual(values = condition_colors) +
  scale_x_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Pre-to-post change by target word",
    subtitle = "Raw change in accuracy for each common target",
    x = "Change in accuracy",
    y = NULL
  ) +
  theme_publication()

contrast_plot <- ggplot(
  planned_probability,
  aes(x = difference_in_probability_change, y = contrast)
) +
  geom_vline(xintercept = 0, color = "#6B7280", linewidth = 0.5) +
  geom_errorbarh(
    aes(xmin = conf_low, xmax = conf_high),
    height = 0.12,
    linewidth = 0.75,
    color = "#374151"
  ) +
  geom_point(size = 2.8, color = "#D55E00") +
  scale_x_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Planned contrasts in pre-to-post change",
    subtitle = "Difference in model-predicted probability change with 95% confidence intervals",
    x = "Difference in probability change",
    y = NULL,
    caption = "Positive estimates favor the condition named first. Holm-adjusted p-values are in the result table."
  ) +
  theme_publication()

save_figure(prediction_plot, "01_model_predicted_target_accuracy", 6.6, 4.6)
save_figure(trajectory_plot, "02_participant_trajectories", 8.4, 4.6)
save_figure(gain_plot, "03_gain_distributions", 6.6, 4.6)
save_figure(item_change_plot, "04_item_level_change", 7.2, 5.8)
save_figure(contrast_plot, "05_planned_contrasts", 7.0, 4.2)

message("Saved five publication figures in PDF and PNG formats.")
