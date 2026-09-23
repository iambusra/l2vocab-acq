fit_glmm_sequence <- function(data, fixed_formula, candidate_random, label) {
  fits <- vector("list", length(candidate_random))
  records <- vector("list", length(candidate_random))

  for (index in seq_along(candidate_random)) {
    formula_text <- paste(fixed_formula, candidate_random[[index]], sep = " + ")
    captured_warnings <- character()
    captured_error <- NA_character_

    fit <- tryCatch(
      withCallingHandlers(
        lme4::glmer(
          stats::as.formula(formula_text),
          data = data,
          family = stats::binomial(link = "logit"),
          control = lme4::glmerControl(
            optimizer = "bobyqa",
            optCtrl = list(maxfun = 200000),
            calc.derivs = TRUE
          )
        ),
        warning = function(warning) {
          captured_warnings <<- c(captured_warnings, conditionMessage(warning))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(error) {
        captured_error <<- conditionMessage(error)
        NULL
      }
    )

    convergence_messages <- if (is.null(fit)) {
      "model did not fit"
    } else {
      messages <- fit@optinfo$conv$lme4$messages
      if (is.null(messages)) "" else paste(messages, collapse = " | ")
    }
    singular <- if (is.null(fit)) NA else lme4::isSingular(fit, tol = 1e-4)
    convergence_ok <- !is.null(fit) && identical(convergence_messages, "")

    fits[[index]] <- fit
    records[[index]] <- tibble::tibble(
      model_label = label,
      candidate_order = index,
      formula = formula_text,
      fitted = !is.null(fit),
      convergence_ok = convergence_ok,
      singular = singular,
      warning_count = length(captured_warnings),
      warnings = paste(unique(captured_warnings), collapse = " | "),
      convergence_messages = convergence_messages,
      error = captured_error,
      AIC = if (is.null(fit)) NA_real_ else stats::AIC(fit),
      BIC = if (is.null(fit)) NA_real_ else stats::BIC(fit)
    )
  }

  selection_log <- dplyr::bind_rows(records)
  acceptable <- which(selection_log$convergence_ok & !selection_log$singular)
  if (length(acceptable) == 0L) {
    acceptable <- which(selection_log$convergence_ok)
  }
  if (length(acceptable) == 0L) {
    stop(label, ": no candidate model converged.", call. = FALSE)
  }

  selected_index <- acceptable[[1]]
  selection_log <- selection_log %>%
    dplyr::mutate(selected = candidate_order == selected_index)

  list(
    model = fits[[selected_index]],
    selection_log = selection_log,
    selected_index = selected_index
  )
}

tidy_fixed_effects <- function(model) {
  coefficients <- as.data.frame(summary(model)$coefficients)
  coefficients$term <- rownames(coefficients)
  rownames(coefficients) <- NULL

  coefficients %>%
    dplyr::transmute(
      term,
      estimate_log_odds = Estimate,
      standard_error = `Std. Error`,
      z_value = `z value`,
      p_value = `Pr(>|z|)`,
      conf_low_log_odds = estimate_log_odds - stats::qnorm(0.975) * standard_error,
      conf_high_log_odds = estimate_log_odds + stats::qnorm(0.975) * standard_error,
      odds_ratio = exp(estimate_log_odds),
      conf_low_odds_ratio = exp(conf_low_log_odds),
      conf_high_odds_ratio = exp(conf_high_log_odds)
    )
}

tidy_random_effects <- function(model) {
  as.data.frame(lme4::VarCorr(model)) %>%
    tibble::as_tibble() %>%
    dplyr::select(group = grp, term_1 = var1, term_2 = var2, variance = vcov, standard_deviation = sdcor)
}

contrast_weights <- function(emm_grid, comparisons) {
  grid <- emm_grid@grid
  purrr::map(comparisons, function(pair) {
    treatment <- pair[[1]]
    reference <- pair[[2]]
    as.numeric(grid$condition == treatment & grid$time == "Post-test") -
      as.numeric(grid$condition == treatment & grid$time == "Pretest") -
      as.numeric(grid$condition == reference & grid$time == "Post-test") +
      as.numeric(grid$condition == reference & grid$time == "Pretest")
  })
}

