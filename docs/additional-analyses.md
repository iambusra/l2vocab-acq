# Additional analyses

These analyses test how dependent the main result is on individual targets, individual participants, sampling uncertainty, modeling choices, and test-score consistency. They do not remove the design limitation created by changing question format between pretest and post-test.

## Status of each analysis

The original trial-level mixed model and its three planned contrasts remain the primary analysis. The analyses below are robustness, sensitivity, or exploratory analyses. They should not be presented as six additional independent confirmations of the same hypothesis.

## Leave-one-item-out analysis

The primary random-intercept binomial model is fitted 10 times, each time omitting one target word. The reported ranges show how much each planned difference in change moves when any single target is removed. The analysis also repeats the omnibus likelihood-ratio test in each deletion dataset.

## Leave-one-participant-out influence analysis

The same model is fitted 90 times, each time omitting one participant. Outputs use stable anonymous case indices rather than participant codes. The analysis reports the range of estimates, the maximum absolute movement from the full-data result, and the largest Holm-adjusted p-value.

## Crossed participant-item bootstrap

Participants are sampled with replacement within instructional condition, and target items are sampled with replacement across the 10 shared targets. Duplicate draws receive new bootstrap cluster identifiers. Each bootstrap sample is fitted with the selected random-intercept model. Percentile intervals therefore reflect sampling variation across both participants and the observed target-item set.

The default is 1,000 repetitions. Set `L2V_BOOTSTRAP_REPS` to change this for development or a larger final run.

Computational settings can be changed with the following environment variables:

- `L2V_INFLUENCE_CORES` controls parallel leave-one-participant fits.
- `L2V_BOOTSTRAP_REPS` and `L2V_BOOTSTRAP_CORES` control the crossed bootstrap.
- `L2V_BAYES_CHAINS`, `L2V_BAYES_ITER`, `L2V_BAYES_WARMUP`, and `L2V_BAYES_CORES` control Bayesian sampling.
- `L2V_BAYES_REFIT=true` forces a refit when a cached local model object exists.
- `L2V_RELIABILITY_REPS` controls the reliability bootstrap.

## Response transitions

Each participant-target pair is classified as incorrect to incorrect, incorrect to correct, correct to incorrect, or correct to correct. An exploratory mixed model predicts post-test correctness from pretest correctness, condition, and their interaction, with participant and item random intercepts.

Both random-intercept variance estimates reached zero in this dataset, so this exploratory model is singular and reduces numerically to an ordinary logistic model. Its model-based standard errors should not be treated as accounting successfully for residual clustering. The paired descriptive transition counts are the more defensible part of this analysis.

The incorrect-to-correct category is a response conversion, not a pure acquisition event. The correct-to-correct category is response persistence, not a pure retention event. The question format changed between waves, so response-state and knowledge-state interpretations are not equivalent.

## Bayesian hierarchical sensitivity

A Bayesian binomial mixed model fits the intended maximal random-effects structure:

```r
correct ~ time * condition +
  (1 + time | participant_id) +
  (1 + time | item_id)
```

Weakly regularizing priors are used for fixed effects, random-effect standard deviations, and correlation matrices. The model uses four chains with 2,000 iterations per chain by default. Posterior summaries report differences in probability change, 95% credible intervals, and posterior probabilities that each contrast is positive. Sampler convergence, effective sample sizes, divergences, and maximum-treedepth hits are saved separately.

This model is a sensitivity analysis because the frequentist random-slope versions were singular. Regularizing priors make the richer model estimable, but they do not create information that is absent from the data.

## Reliability and score stability

KR-20 is reported for the 10 shared dichotomous target items at each wave, overall and within condition. Confidence intervals resample participants. Overall bootstrap samples are stratified by condition so each sample preserves the original group composition. Within-condition estimates have only 30 participants and should be treated as imprecise.

Pretest-post-test Pearson and Spearman score correlations are also reported descriptively. Because the two waves use different question formats, these correlations are not a test-retest reliability coefficient and cannot establish measurement invariance.
