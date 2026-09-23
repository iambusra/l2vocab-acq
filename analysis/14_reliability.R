suppressPackageStartupMessages(library(tidyverse))

source("R/project.R")
source("R/additional_helpers.R")
assert_project_root()
ensure_directories()

target_responses <- read_target_responses()
bootstrap_repetitions <- as.integer(Sys.getenv("L2V_RELIABILITY_REPS", "2000"))
set.seed(20260923)

kr20 <- function(item_matrix) {
  item_matrix <- as.matrix(item_matrix)
  item_count <- ncol(item_matrix)
  total_variance <- stats::var(rowSums(item_matrix))
  if (!is.finite(total_variance) || total_variance == 0) {
    return(NA_real_)
  }
  item_count / (item_count - 1) *
    (1 - sum(apply(item_matrix, 2, stats::var)) / total_variance)
}

make_item_matrix <- function(data) {
  data %>%
    select(participant_id, item_id, correct) %>%
    pivot_wider(names_from = item_id, values_from = correct) %>%
    arrange(participant_id) %>%
    select(-participant_id) %>%
    as.matrix()
}

estimate_reliability <- function(data, scope, condition_name, time_name) {
  matrices <- data %>%
    filter(time == time_name) %>%
    split(.$condition) %>%
    map(make_item_matrix)

  if (scope == "condition") {
    matrices <- matrices[condition_name]
  }
  observed_matrix <- do.call(rbind, matrices)
  estimate <- kr20(observed_matrix)

  bootstrap_values <- replicate(bootstrap_repetitions, {
    sampled <- map(matrices, function(item_matrix) {
      item_matrix[
        sample(seq_len(nrow(item_matrix)), nrow(item_matrix), replace = TRUE),
        ,
        drop = FALSE
      ]
    })
    kr20(do.call(rbind, sampled))
  })

  tibble(
    scope,
    condition = if (scope == "overall") "All conditions" else condition_name,
    time = time_name,
    participants = nrow(observed_matrix),
    items = ncol(observed_matrix),
    kr20 = estimate,
    bootstrap_conf_low = quantile(bootstrap_values, 0.025, na.rm = TRUE),
    bootstrap_conf_high = quantile(bootstrap_values, 0.975, na.rm = TRUE),
    valid_bootstrap_repetitions = sum(is.finite(bootstrap_values)),
    requested_bootstrap_repetitions = bootstrap_repetitions
  )
}

reliability_plan <- bind_rows(
  tidyr::expand_grid(
    scope = "overall",
    condition = "All conditions",
    time = time_levels
  ),
  tidyr::expand_grid(
    scope = "condition",
    condition = condition_levels,
    time = time_levels
  )
)

reliability_results <- pmap_dfr(
  reliability_plan,
  function(scope, condition, time) {
    estimate_reliability(target_responses, scope, condition, time)
  }
)

participant_scores <- target_responses %>%
  group_by(participant_id, condition, time) %>%
  summarise(target_accuracy = mean(correct), .groups = "drop") %>%
  pivot_wider(names_from = time, values_from = target_accuracy)

correlation_groups <- c("All conditions", condition_levels)
score_correlations <- map_dfr(correlation_groups, function(group_name) {
  data <- if (group_name == "All conditions") {
    participant_scores
  } else {
    participant_scores %>% filter(condition == group_name)
  }
  pearson <- cor.test(data$Pretest, data$`Post-test`, method = "pearson")
  spearman <- suppressWarnings(cor.test(
    data$Pretest,
    data$`Post-test`,
    method = "spearman",
    exact = FALSE
  ))

  tibble(
    condition = group_name,
    participants = nrow(data),
    pearson_correlation = unname(pearson$estimate),
    pearson_conf_low = pearson$conf.int[[1]],
    pearson_conf_high = pearson$conf.int[[2]],
    pearson_p_value = pearson$p.value,
    spearman_correlation = unname(spearman$estimate),
    spearman_p_value = spearman$p.value
  )
})

write_csv(reliability_results, "output/tables/reliability_kr20.csv")
write_csv(score_correlations, "output/tables/prepost_score_correlations.csv")

message("Completed KR-20 reliability estimates and pre-post score correlations.")
