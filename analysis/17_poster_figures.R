suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(patchwork)
  library(brms)
})

source("R/project.R")
source("R/poster_theme.R")
assert_project_root()
ensure_directories()

percent_axis <- label_percent(accuracy = 1)
contrast_levels <- c(
  "Grounding vs Thematic",
  "Grounding vs Control",
  "Thematic vs Control"
)

predictions <- read_csv(
  "output/tables/primary_predicted_probabilities.csv",
  show_col_types = FALSE
) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = time_levels),
    time_number = as.numeric(time),
    condition_offset = recode(
      as.character(condition),
      Control = -0.07,
      Thematic = 0,
      Grounding = 0.07
    ),
    x = time_number + condition_offset
  )

participant_scores <- read_csv(
  "data/processed/participant_scores.csv",
  show_col_types = FALSE
) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = time_levels),
    time_number = as.numeric(time),
    condition_offset = recode(
      as.character(condition),
      Control = -0.07,
      Thematic = 0,
      Grounding = 0.07
    ),
    x = time_number + condition_offset
  )

primary_plot <- ggplot() +
  geom_point(
    data = participant_scores,
    aes(x = x, y = target_accuracy, color = condition),
    alpha = 0.13,
    size = 1.2,
    position = position_jitter(width = 0.025, height = 0, seed = 20260923),
    show.legend = FALSE
  ) +
  geom_line(
    data = predictions,
    aes(x = x, y = predicted_probability, color = condition, group = condition),
    linewidth = 1.45
  ) +
  geom_errorbar(
    data = predictions,
    aes(x = x, ymin = conf_low, ymax = conf_high, color = condition),
    width = 0.035,
    linewidth = 1.0
  ) +
  geom_point(
    data = predictions,
    aes(x = x, y = predicted_probability, color = condition),
    size = 4.2
  ) +
  scale_color_manual(values = poster_condition_colors) +
  scale_x_continuous(
    breaks = 1:2,
    labels = c("Pretest", "Post-test"),
    limits = c(0.78, 2.22)
  ) +
  scale_y_continuous(
    labels = percent_axis,
    breaks = seq(0, 1, 0.2),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0.025))
  ) +
  labs(
    title = "Grounding produced the largest gain",
    subtitle = "Model estimates and 95% CIs; faint points are participant scores",
    x = NULL,
    y = "Target-word accuracy",
    caption = "The overall time effect also contains the shared change in question format."
  ) +
  theme_poster()

planned_contrasts <- read_csv(
  "output/tables/planned_contrasts_probability.csv",
  show_col_types = FALSE
) %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))

contrast_plot <- ggplot(
  planned_contrasts,
  aes(
    x = difference_in_probability_change,
    y = contrast,
    xmin = conf_low,
    xmax = conf_high,
    color = contrast
  )
) +
  geom_vline(xintercept = 0, color = "#8996A3", linewidth = 0.7) +
  geom_errorbarh(height = 0.13, linewidth = 1.15) +
  geom_point(size = 4.2) +
  geom_text(
    aes(label = percent(difference_in_probability_change, accuracy = 0.1)),
    nudge_y = 0.23,
    fontface = "bold",
    show.legend = FALSE
  ) +
  scale_color_manual(values = poster_contrast_colors) +
  scale_x_continuous(labels = percent_axis, limits = c(-0.02, 0.46)) +
  labs(
    title = "Planned differences in learning gain",
    subtitle = "Difference in model-predicted pre-to-post change",
    x = "Difference in probability change",
    y = NULL,
    caption = "Positive values favor the condition named first. Intervals are 95% confidence intervals."
  ) +
  theme_poster() +
  theme(legend.position = "none")

participant_gains <- read_csv(
  "output/tables/participant_gains.csv",
  show_col_types = FALSE
) %>%
  mutate(condition = factor(condition, levels = condition_levels))
gain_summary <- read_csv(
  "output/tables/gain_summary.csv",
  show_col_types = FALSE
) %>%
  mutate(condition = factor(condition, levels = condition_levels))

gain_plot <- ggplot(
  participant_gains,
  aes(x = condition, y = gain_correct, fill = condition, color = condition)
) +
  geom_violin(width = 0.82, alpha = 0.18, linewidth = 0.9, trim = FALSE) +
  geom_boxplot(
    width = 0.19,
    outlier.shape = NA,
    alpha = 0.72,
    color = "white",
    linewidth = 0.7
  ) +
  geom_point(
    position = position_jitter(width = 0.09, height = 0, seed = 20260923),
    size = 2.0,
    alpha = 0.55
  ) +
  geom_text(
    data = gain_summary,
    aes(
      x = condition,
      y = mean_gain_correct + 1.35,
      label = paste0("Mean +", number(mean_gain_correct, accuracy = 0.1))
    ),
    color = "#263442",
    fontface = "bold",
    size = 4.4,
    inherit.aes = FALSE
  ) +
  geom_hline(yintercept = 0, color = "#8996A3", linetype = "dashed") +
  scale_fill_manual(values = poster_condition_colors) +
  scale_color_manual(values = poster_condition_colors) +
  scale_y_continuous(breaks = seq(-4, 8, 2)) +
  coord_cartesian(ylim = c(-4.5, 8.3)) +
  labs(
    title = "Participant gain distributions",
    subtitle = "Post-test minus pretest correct responses on 10 shared target words",
    x = NULL,
    y = "Change in correct responses"
  ) +
  theme_poster() +
  theme(legend.position = "none")

ancova_predictions <- read_csv(
  "output/tables/ancova_predicted_probabilities.csv",
  show_col_types = FALSE
) %>%
  mutate(condition = factor(condition, levels = condition_levels))

ancova_plot <- ggplot(
  ancova_predictions,
  aes(x = prob, y = fct_rev(condition), xmin = asymp.LCL, xmax = asymp.UCL, color = condition)
) +
  geom_errorbarh(height = 0.15, linewidth = 1.1) +
  geom_point(size = 4.2) +
  geom_text(
    aes(label = percent(prob, accuracy = 0.1)),
    nudge_y = 0.22,
    color = "#263442",
    fontface = "bold",
    show.legend = FALSE
  ) +
  scale_color_manual(values = poster_condition_colors) +
  scale_x_continuous(labels = percent_axis, limits = c(0.42, 0.92)) +
  labs(
    title = "Pretest-adjusted post-test accuracy",
    subtitle = "Participant-level binomial ANCOVA robustness analysis",
    x = "Adjusted probability correct",
    y = NULL,
    caption = "Predictions are evaluated at the mean pretest score."
  ) +
  theme_poster() +
  theme(legend.position = "none")

target_order <- read_csv("data/processed/item_key.csv", show_col_types = FALSE) %>%
  filter(item_set == "target") %>%
  arrange(item_number) %>%
  pull(word)
item_change <- read_csv("output/tables/target_item_change.csv", show_col_types = FALSE) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    word = factor(word, levels = rev(target_order))
  )

item_plot <- ggplot(item_change, aes(x = condition, y = word, fill = change_accuracy)) +
  geom_tile(color = "white", linewidth = 1.1) +
  geom_text(
    aes(label = percent(change_accuracy, accuracy = 1)),
    fontface = "bold",
    color = "#17212B",
    size = 4.1
  ) +
  scale_fill_gradient2(
    low = "#7A93B6",
    mid = "#F4F6F8",
    high = "#D95F02",
    midpoint = 0,
    labels = percent_axis
  ) +
  labs(
    title = "Learning gains across the 10 target words",
    subtitle = "Raw pre-to-post change in item accuracy",
    x = NULL,
    y = NULL,
    fill = "Change"
  ) +
  theme_poster() +
  theme(panel.grid = element_blank(), legend.position = "right")

loo <- read_csv(
  "output/tables/leave_one_item_out_contrasts.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  mutate(
    contrast = factor(contrast, levels = contrast_levels),
    excluded_word = factor(excluded_word, levels = rev(target_order)),
    result = if_else(p_value_holm < 0.05, "Holm p < .05", "Holm p >= .05")
  )
full_contrasts <- planned_contrasts %>%
  transmute(
    contrast = factor(as.character(contrast), levels = contrast_levels),
    full_estimate = difference_in_probability_change
  )

loo_plot <- ggplot(
  loo,
  aes(x = estimate, y = excluded_word, xmin = conf_low, xmax = conf_high, color = result)
) +
  geom_vline(
    data = full_contrasts,
    aes(xintercept = full_estimate),
    color = "#263442",
    linewidth = 0.8,
    linetype = "dashed"
  ) +
  geom_vline(xintercept = 0, color = "#A7B0B9", linewidth = 0.55) +
  geom_errorbarh(height = 0.12, linewidth = 0.65) +
  geom_point(size = 2.7) +
  facet_wrap(~ contrast, nrow = 1) +
  scale_color_manual(values = c("Holm p < .05" = "#0072B2", "Holm p >= .05" = "#CC3311")) +
  scale_x_continuous(labels = percent_axis, limits = c(-0.04, 0.48)) +
  labs(
    title = "Leave-one-target-out sensitivity",
    subtitle = "Each row refits the primary model after removing the named word",
    x = "Difference in probability change",
    y = "Omitted target word",
    caption = "Dashed lines show full-data estimates. Thematic vs Control is item-sensitive."
  ) +
  theme_poster(base_size = 14) +
  theme(legend.position = "bottom")

participant_influence <- read_csv(
  "output/tables/participant_influence_contrasts.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))

influence_plot <- ggplot(
  participant_influence,
  aes(x = change_from_full_estimate, y = contrast, fill = contrast, color = contrast)
) +
  geom_vline(xintercept = 0, color = "#8996A3", linewidth = 0.7) +
  geom_violin(orientation = "y", width = 0.78, alpha = 0.22, linewidth = 0.8) +
  geom_boxplot(
    orientation = "y",
    width = 0.19,
    outlier.shape = NA,
    alpha = 0.70,
    color = "white"
  ) +
  geom_point(
    size = 1.15,
    alpha = 0.25,
    position = position_jitter(height = 0.12, width = 0, seed = 20260923)
  ) +
  scale_fill_manual(values = poster_contrast_colors) +
  scale_color_manual(values = poster_contrast_colors) +
  scale_x_continuous(labels = label_percent(accuracy = 0.1), limits = c(-0.02, 0.02)) +
  labs(
    title = "No single participant drives the result",
    subtitle = "Movement in each contrast after deleting one participant and refitting the model",
    x = "Change from the full-data estimate",
    y = NULL,
    caption = "All 90 refits retained positive, Holm-significant contrasts."
  ) +
  theme_poster() +
  theme(legend.position = "none")

bootstrap_draws <- read_csv(
  "output/tables/crossed_bootstrap_draws.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability", fit_succeeded) %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))
bootstrap_summary <- read_csv(
  "output/tables/crossed_bootstrap_summary.csv",
  show_col_types = FALSE
) %>%
  filter(scale == "probability") %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))

bootstrap_plot <- ggplot(
  bootstrap_draws,
  aes(x = estimate, y = contrast, fill = contrast, color = contrast)
) +
  geom_vline(xintercept = 0, color = "#8996A3", linewidth = 0.7) +
  geom_violin(orientation = "y", width = 0.82, alpha = 0.23, linewidth = 0.8) +
  geom_errorbarh(
    data = bootstrap_summary,
    aes(y = contrast, xmin = conf_low_percentile, xmax = conf_high_percentile),
    height = 0.12,
    linewidth = 1.25,
    color = "#263442",
    inherit.aes = FALSE
  ) +
  geom_point(
    data = bootstrap_summary,
    aes(x = median_estimate, y = contrast),
    size = 4.0,
    color = "#263442",
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = poster_contrast_colors) +
  scale_color_manual(values = poster_contrast_colors) +
  scale_x_continuous(labels = percent_axis) +
  coord_cartesian(xlim = c(-0.12, 0.62)) +
  labs(
    title = "Crossed participant-item bootstrap",
    subtitle = "1,000 resamples of both participants and target words",
    x = "Difference in probability change",
    y = NULL,
    caption = "Black intervals are percentile 95% intervals; points are bootstrap medians."
  ) +
  theme_poster() +
  theme(legend.position = "none")

bayesian_model <- readRDS("output/models/bayesian_random_slopes_glmm.rds")
bayesian_grid <- tidyr::expand_grid(
  condition = factor(condition_levels, levels = condition_levels),
  time = factor(time_levels, levels = time_levels)
)
posterior_probabilities <- posterior_epred(
  bayesian_model,
  newdata = bayesian_grid,
  re_formula = NA
)
colnames(posterior_probabilities) <- paste(
  bayesian_grid$condition,
  bayesian_grid$time,
  sep = "__"
)
posterior_changes <- tibble(
  Control = posterior_probabilities[, "Control__Post-test"] - posterior_probabilities[, "Control__Pretest"],
  Thematic = posterior_probabilities[, "Thematic__Post-test"] - posterior_probabilities[, "Thematic__Pretest"],
  Grounding = posterior_probabilities[, "Grounding__Post-test"] - posterior_probabilities[, "Grounding__Pretest"]
)
bayesian_draws <- tibble(
  `Grounding vs Thematic` = posterior_changes$Grounding - posterior_changes$Thematic,
  `Grounding vs Control` = posterior_changes$Grounding - posterior_changes$Control,
  `Thematic vs Control` = posterior_changes$Thematic - posterior_changes$Control
) %>%
  pivot_longer(everything(), names_to = "contrast", values_to = "estimate") %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))
bayesian_summary <- read_csv(
  "output/tables/bayesian_planned_contrasts.csv",
  show_col_types = FALSE
) %>%
  mutate(contrast = factor(contrast, levels = rev(contrast_levels)))

bayesian_plot <- ggplot(
  bayesian_draws,
  aes(x = estimate, y = contrast, fill = contrast, color = contrast)
) +
  geom_vline(xintercept = 0, color = "#8996A3", linewidth = 0.7) +
  geom_violin(orientation = "y", width = 0.82, alpha = 0.23, linewidth = 0.8) +
  geom_errorbarh(
    data = bayesian_summary,
    aes(y = contrast, xmin = conf_low, xmax = conf_high),
    height = 0.12,
    linewidth = 1.25,
    color = "#263442",
    inherit.aes = FALSE
  ) +
  geom_point(
    data = bayesian_summary,
    aes(x = posterior_median, y = contrast),
    size = 4.0,
    color = "#263442",
    inherit.aes = FALSE
  ) +
  geom_text(
    data = bayesian_summary,
    aes(
      x = 0.47,
      y = contrast,
      label = paste0("P(>0) = ", number(posterior_probability_above_zero, accuracy = 0.001))
    ),
    color = "#263442",
    fontface = "bold",
    hjust = 1,
    size = 4.0,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = poster_contrast_colors) +
  scale_color_manual(values = poster_contrast_colors) +
  scale_x_continuous(labels = percent_axis) +
  coord_cartesian(xlim = c(-0.08, 0.50)) +
  labs(
    title = "Bayesian random-slopes sensitivity",
    subtitle = "Posterior differences in pre-to-post probability change",
    x = "Difference in probability change",
    y = NULL,
    caption = "Black intervals are 95% credible intervals. Four chains, 4,000 post-warmup draws, zero divergences."
  ) +
  theme_poster() +
  theme(legend.position = "none")

transition_predictions <- read_csv(
  "output/tables/response_transition_predictions.csv",
  show_col_types = FALSE
) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    pre_correct = factor(
      pre_correct,
      levels = c("Pretest incorrect", "Pretest correct"),
      labels = c("Initially incorrect", "Initially correct")
    )
  )

transition_plot <- ggplot(
  transition_predictions,
  aes(
    x = predicted_post_probability,
    y = fct_rev(condition),
    xmin = conf_low,
    xmax = conf_high,
    color = condition
  )
) +
  geom_errorbarh(height = 0.14, linewidth = 1.0) +
  geom_point(size = 4.0) +
  geom_text(
    aes(label = percent(predicted_post_probability, accuracy = 0.1)),
    nudge_y = 0.22,
    color = "#263442",
    fontface = "bold",
    show.legend = FALSE
  ) +
  facet_wrap(~ pre_correct, ncol = 2) +
  scale_color_manual(values = poster_condition_colors) +
  scale_x_continuous(labels = percent_axis, limits = c(0, 1)) +
  labs(
    title = "Post-test accuracy conditional on the pretest response",
    subtitle = "Conversion of initially incorrect responses differs sharply by condition",
    x = "Probability correct at post-test",
    y = NULL,
    caption = "Response transitions are not pure knowledge-state transitions because question format changed. The exploratory model was singular."
  ) +
  theme_poster(base_size = 14) +
  theme(legend.position = "none")

reliability <- read_csv(
  "output/tables/reliability_kr20.csv",
  show_col_types = FALSE
) %>%
  mutate(
    panel = if_else(scope == "overall", "All 90 participants", "Within condition, n = 30"),
    condition = factor(condition, levels = c("All conditions", condition_levels)),
    time = factor(time, levels = time_levels)
  )

reliability_plot <- ggplot(
  reliability,
  aes(
    x = kr20,
    y = fct_rev(condition),
    xmin = bootstrap_conf_low,
    xmax = bootstrap_conf_high,
    color = time
  )
) +
  geom_vline(xintercept = 0, color = "#8996A3", linewidth = 0.6) +
  geom_vline(xintercept = 0.70, color = "#8996A3", linewidth = 0.7, linetype = "dashed") +
  geom_errorbarh(
    height = 0.14,
    linewidth = 1.0,
    position = position_dodge(width = 0.42)
  ) +
  geom_point(size = 3.7, position = position_dodge(width = 0.42)) +
  facet_wrap(~ panel, scales = "free") +
  scale_color_manual(values = c("Pretest" = "#566573", "Post-test" = "#D95F02")) +
  labs(
    title = "The 10-item score has weak internal consistency",
    subtitle = "KR-20 estimates with participant-bootstrap 95% intervals",
    x = "KR-20",
    y = NULL,
    caption = "The dashed line marks .70. The negative Grounding post-test estimate accompanies a strong ceiling."
  ) +
  theme_poster(base_size = 14)

secondary <- read_csv(
  "output/tables/secondary_descriptives.csv",
  show_col_types = FALSE
) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = time_levels),
    conf_low = pmax(0, accuracy - 1.96 * standard_error),
    conf_high = pmin(1, accuracy + 1.96 * standard_error)
  )

secondary_plot <- ggplot(
  secondary,
  aes(x = time, y = accuracy, color = condition, group = condition)
) +
  geom_line(linewidth = 1.35) +
  geom_errorbar(aes(ymin = conf_low, ymax = conf_high), width = 0.08, linewidth = 0.9) +
  geom_point(size = 4.0) +
  scale_color_manual(values = poster_condition_colors) +
  scale_y_continuous(labels = percent_axis, limits = c(0.30, 0.88)) +
  labs(
    title = "Secondary items improved within every condition",
    subtitle = "Q11 to Q20 descriptive accuracy with approximate 95% intervals",
    x = NULL,
    y = "Accuracy",
    caption = "Item sets differ by condition, so these lines must not be interpreted as a between-condition treatment comparison."
  ) +
  theme_poster()

word_cards <- tibble(
  condition = factor(condition_levels, levels = condition_levels),
  center = c(2.1, 6.5, 10.9),
  header = c(
    "CONTROL",
    "THEMATIC",
    "GROUNDING"
  ),
  organization = c(
    "Presented independently",
    "Co-occur in shared contexts",
    "Explicit lexical-semantic links"
  ),
  symbol = c("|", "···", ""),
  filler_examples = c(
    "disappear\nrestless\nuneven\nunwrap",
    "prepare\npending\nurgent\nsubmit",
    "rethink\nunavoidable\ndefinite\npreserve"
  ),
  card_fill = c("#EEF1F4", "#E4F4F2", "#FCE9DD")
) %>%
  mutate(
    xmin = center - 1.95,
    xmax = center + 1.95,
    header_fill = unname(poster_condition_colors[as.character(condition)])
  )
target_examples <- "reconsider\navoidable\nuncertain\nmaintain"

word_design_plot <- ggplot() +
  geom_rect(
    data = word_cards,
    aes(xmin = xmin, xmax = xmax, ymin = 0.7, ymax = 7.0, fill = card_fill),
    color = "#D6DEE5",
    linewidth = 0.8,
    show.legend = FALSE
  ) +
  geom_rect(
    data = word_cards,
    aes(xmin = xmin, xmax = xmax, ymin = 6.2, ymax = 7.0, fill = header_fill),
    color = NA,
    show.legend = FALSE
  ) +
  geom_text(
    data = word_cards,
    aes(x = center, y = 6.62, label = header),
    color = "white",
    fontface = "bold",
    size = 5.4
  ) +
  geom_text(
    data = word_cards,
    aes(x = center, y = 5.72, label = organization),
    color = "#263442",
    fontface = "bold",
    size = 4.1
  ) +
  geom_text(
    data = word_cards,
    aes(x = center - 1.05, y = 5.05, label = "SHARED TARGETS"),
    color = "#5F6F7F",
    fontface = "bold",
    size = 3.5
  ) +
  geom_text(
    data = word_cards,
    aes(x = center + 1.05, y = 5.05, label = "FILLERS"),
    color = "#5F6F7F",
    fontface = "bold",
    size = 3.5
  ) +
  geom_text(
    data = word_cards,
    aes(x = center - 1.05, y = 3.45, label = target_examples),
    color = "#18212B",
    lineheight = 1.55,
    size = 4.6
  ) +
  geom_text(
    data = word_cards,
    aes(x = center, y = 3.45, label = symbol),
    color = "#617181",
    fontface = "bold",
    size = 7.0
  ) +
  geom_segment(
    data = word_cards %>% filter(condition == "Grounding"),
    aes(x = center - 0.22, xend = center + 0.22, y = 3.45, yend = 3.45),
    color = "#617181",
    linewidth = 1.1,
    arrow = grid::arrow(
      angle = 28,
      length = grid::unit(0.12, "inches"),
      ends = "both",
      type = "closed"
    )
  ) +
  geom_text(
    data = word_cards,
    aes(x = center + 1.05, y = 3.45, label = filler_examples),
    color = "#18212B",
    lineheight = 1.55,
    size = 4.6
  ) +
  scale_fill_identity() +
  coord_cartesian(xlim = c(0, 13), ylim = c(0.55, 7.1), clip = "off") +
  labs(
    title = "Same targets, different lexical neighborhoods",
    subtitle = "Illustrative target and filler words from the three instructional conditions",
    caption = "Examples use Q1 to Q4 targets and Q11 to Q14 fillers. Dots indicate contextual co-occurrence, not word-to-word pairing."
  ) +
  theme_void(base_size = 16, base_family = "Helvetica") +
  theme(
    plot.title = element_text(face = "bold", size = 22, color = "#18212B"),
    plot.subtitle = element_text(size = 16, color = "#455565", margin = margin(b = 12)),
    plot.caption = element_text(size = 11, color = "#5F6F7F", hjust = 0, margin = margin(t = 10)),
    plot.margin = margin(16, 18, 16, 18)
  )

performance_source <- read_csv(
  "output/tables/descriptive_condition_time.csv",
  show_col_types = FALSE
) %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = time_levels)
  )
word_set_performance <- bind_rows(
  performance_source %>%
    transmute(
      condition,
      time,
      word_set = "Shared targets, Q1 to Q10",
      accuracy = target_mean_accuracy,
      standard_error = target_se_accuracy
    ),
  performance_source %>%
    transmute(
      condition,
      time,
      word_set = "Condition-specific fillers, Q11 to Q20",
      accuracy = secondary_mean_accuracy,
      standard_error = secondary_se_accuracy
    )
) %>%
  mutate(
    word_set = factor(
      word_set,
      levels = c(
        "Shared targets, Q1 to Q10",
        "Condition-specific fillers, Q11 to Q20"
      )
    ),
    conf_low = pmax(0, accuracy - 1.96 * standard_error),
    conf_high = pmin(1, accuracy + 1.96 * standard_error),
    label_y = accuracy + recode(
      as.character(condition),
      Control = 0.045,
      Thematic = 0,
      Grounding = -0.045
    )
  )

target_filler_plot <- ggplot(
  word_set_performance,
  aes(x = time, y = accuracy, color = condition, group = condition)
) +
  geom_line(linewidth = 1.45) +
  geom_errorbar(
    aes(ymin = conf_low, ymax = conf_high),
    width = 0.07,
    linewidth = 0.9
  ) +
  geom_point(size = 4.2) +
  geom_text(
    aes(y = label_y, label = percent(accuracy, accuracy = 1)),
    nudge_x = 0.10,
    fontface = "bold",
    size = 4.0,
    show.legend = FALSE
  ) +
  facet_wrap(~ word_set, nrow = 1) +
  scale_color_manual(values = poster_condition_colors) +
  scale_y_continuous(
    labels = percent_axis,
    breaks = seq(0.3, 0.9, 0.1),
    limits = c(0.30, 0.92)
  ) +
  labs(
    title = "Target and filler performance over time",
    subtitle = "Shared targets separate strongly by condition; filler gains are descriptive within each condition",
    x = NULL,
    y = "Mean accuracy",
    caption = "Target items are identical across conditions. Filler items differ by condition, so the filler panel does not support a between-condition comparison."
  ) +
  theme_poster(base_size = 15)

save_poster_figure(primary_plot, "01_primary_learning_curve", 8.0, 5.8)
save_poster_figure(contrast_plot, "02_primary_contrasts", 8.0, 5.2)
save_poster_figure(gain_plot, "03_gain_distributions", 7.6, 5.7)
save_poster_figure(ancova_plot, "04_ancova_adjusted_posttest", 7.5, 5.0)
save_poster_figure(item_plot, "05_item_change_heatmap", 7.8, 6.8)
save_poster_figure(loo_plot, "06_leave_one_item_out", 13.5, 7.2)
save_poster_figure(influence_plot, "07_participant_influence", 8.4, 5.2)
save_poster_figure(bootstrap_plot, "08_crossed_bootstrap", 8.4, 5.2)
save_poster_figure(bayesian_plot, "09_bayesian_sensitivity", 8.4, 5.2)
save_poster_figure(transition_plot, "10_response_transitions", 10.5, 5.3)
save_poster_figure(reliability_plot, "11_reliability", 10.0, 5.5)
save_poster_figure(secondary_plot, "12_secondary_items", 7.8, 5.5)

summary_plate <- (
  primary_plot + contrast_plot + gain_plot +
    loo_plot + influence_plot + bootstrap_plot +
    bayesian_plot + transition_plot + reliability_plot
) +
  plot_layout(ncol = 3, guides = "keep") +
  plot_annotation(
    title = "How vocabulary organization changed target-word learning",
    subtitle = "Primary results and robustness analyses",
    tag_levels = "A",
    theme = theme_poster(base_size = 18) +
      theme(
        plot.title = element_text(size = 28, face = "bold"),
        plot.subtitle = element_text(size = 19)
      )
  ) &
  theme(
    plot.title = element_text(size = 16),
    plot.subtitle = element_text(size = 12),
    plot.caption = element_text(size = 9),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    strip.text = element_text(size = 11),
    legend.text = element_text(size = 10)
  )

save_poster_figure(summary_plate, "13_summary_plate", 24, 21, dpi = 300)
save_poster_figure(word_design_plot, "14_target_filler_examples", 13.5, 7.0)
save_poster_figure(target_filler_plot, "15_target_filler_performance", 12.0, 6.0)

target_filler_plate <- (word_design_plot / target_filler_plot) +
  plot_layout(heights = c(1.08, 1)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 18, color = "#18212B"))
save_poster_figure(target_filler_plate, "16_target_filler_plate", 13.5, 13.0, dpi = 400)

message("Saved 16 poster-ready figures as PDF, SVG, and high-resolution PNG files.")
