planned_comparison_pairs <- list(
  "Grounding vs Thematic" = c("Grounding", "Thematic"),
  "Grounding vs Control" = c("Grounding", "Control"),
  "Thematic vs Control" = c("Thematic", "Control")
)

safe_detect_cores <- function(default = 1L) {
  detected <- parallel::detectCores(logical = FALSE)
  if (length(detected) != 1L || !is.finite(detected) || detected < 1L) {
    return(as.integer(default))
  }
  as.integer(detected)
}

read_target_responses <- function() {
  readr::read_csv(
    "data/processed/responses_long.csv",
    col_types = readr::cols(
      participant_id = readr::col_character(),
      condition = readr::col_factor(levels = condition_levels),
      time = readr::col_factor(levels = time_levels),
      item_number = readr::col_integer(),
      item_set = readr::col_character(),
      item_id = readr::col_character(),
      word = readr::col_character(),
      response = readr::col_character(),
      correct_answer = readr::col_character(),
      correct = readr::col_integer()
    ),
    show_col_types = FALSE
  ) %>%
    dplyr::filter(item_set == "target") %>%
    droplevels()
}

fit_random_intercept_glmm <- function(data) {
  lme4::glmer(
    correct ~ time * condition + (1 | participant_id) + (1 | item_id),
    data = data,
    family = stats::binomial(link = "logit"),
    control = lme4::glmerControl(
      optimizer = "bobyqa",
      optCtrl = list(maxfun = 200000),
      calc.derivs = TRUE
    )
  )
}

extract_planned_contrasts <- function(model) {
  emm <- emmeans::emmeans(model, ~ condition * time)
  weights <- contrast_weights(emm, planned_comparison_pairs)
  names(weights) <- names(planned_comparison_pairs)

  link_grid <- emmeans::contrast(emm, method = weights)
  link <- summary(link_grid, infer = c(TRUE, TRUE), adjust = "none") %>%
    as.data.frame() %>%
    tibble::as_tibble() %>%
    dplyr::transmute(
      contrast,
      scale = "log_odds",
      estimate,
      standard_error = SE,
      conf_low = asymp.LCL,
      conf_high = asymp.UCL,
      z_ratio = z.ratio,
      p_value = p.value
    )

  probability_grid <- emmeans::regrid(emm, transform = "response")
  probability <- emmeans::contrast(probability_grid, method = weights) %>%
    summary(infer = c(TRUE, TRUE), adjust = "none") %>%
    as.data.frame() %>%
    tibble::as_tibble() %>%
    dplyr::transmute(
      contrast,
      scale = "probability",
      estimate,
      standard_error = SE,
      conf_low = asymp.LCL,
      conf_high = asymp.UCL,
      z_ratio = z.ratio,
      p_value = p.value
    )

  dplyr::bind_rows(link, probability) %>%
    dplyr::group_by(scale) %>%
    dplyr::mutate(p_value_holm = stats::p.adjust(p_value, method = "holm")) %>%
    dplyr::ungroup()
}

extract_cell_predictions <- function(model) {
  prediction_grid <- tidyr::expand_grid(
    condition = factor(condition_levels, levels = condition_levels),
    time = factor(time_levels, levels = time_levels)
  )
  fixed_formula <- lme4::nobars(stats::formula(model))
  fixed_terms <- stats::delete.response(stats::terms(fixed_formula))
  design <- stats::model.matrix(fixed_terms, prediction_grid)
  eta <- as.numeric(design %*% lme4::fixef(model))

  prediction_grid %>%
    dplyr::mutate(log_odds = eta, probability = stats::plogis(eta))
}

cell_difference_in_differences <- function(cell_predictions, value_column) {
  wide <- cell_predictions %>%
    dplyr::mutate(cell = paste(condition, time, sep = "__")) %>%
    dplyr::select(cell, value = dplyr::all_of(value_column)) %>%
    tidyr::pivot_wider(names_from = cell, values_from = value)

  purrr::imap_dfr(planned_comparison_pairs, function(pair, contrast_name) {
    first_change <- wide[[paste(pair[[1]], "Post-test", sep = "__")]] -
      wide[[paste(pair[[1]], "Pretest", sep = "__")]]
    second_change <- wide[[paste(pair[[2]], "Post-test", sep = "__")]] -
      wide[[paste(pair[[2]], "Pretest", sep = "__")]]
    tibble::tibble(contrast = contrast_name, estimate = first_change - second_change)
  })
}
