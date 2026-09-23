# Results summary

## Primary target items

The six raw condition-time means show closely matched pretest scores and clear separation at post-test:

| Condition | Pretest mean /10 | Post-test mean /10 | Raw gain |
|---|---:|---:|---:|
| Control | 4.20 | 5.30 | 1.10 |
| Thematic | 4.27 | 6.57 | 2.30 |
| Grounding | 4.30 | 8.30 | 4.00 |

The selected binomial mixed model was:

```text
correct ~ time * condition + (1 | participant_id) + (1 | item_id)
```

The time by condition interaction improved fit over the no-interaction model, likelihood-ratio chi-square(2) = 35.24, p = 2.23e-8.

### Planned contrasts

| Contrast | Difference in predicted probability change | 95% CI | Ratio of odds ratios | 95% CI | Holm p |
|---|---:|---:|---:|---:|---:|
| Grounding vs Thematic | 0.172 | 0.059 to 0.285 | 2.69 | 1.59 to 4.55 | .000475 |
| Grounding vs Control | 0.304 | 0.187 to 0.421 | 4.69 | 2.79 to 7.91 | 1.93e-8 |
| Thematic vs Control | 0.132 | 0.016 to 0.249 | 1.75 | 1.07 to 2.85 | .0247 |

Confidence intervals are ordinary two-sided 95% intervals. P-values are adjusted across the three planned contrasts with Holm's method.

### Robustness analysis

The participant-level binomial ANCOVA modeled post-test target successes out of 10 by condition and centered pretest accuracy. Adjusted post-test odds ratios were:

| Contrast | Odds ratio | 95% CI | Holm p |
|---|---:|---:|---:|
| Grounding vs Thematic | 2.61 | 1.76 to 3.85 | 3.03e-6 |
| Grounding vs Control | 4.45 | 3.03 to 6.54 | 8.66e-14 |
| Thematic vs Control | 1.71 | 1.22 to 2.39 | .00189 |

### Diagnostics

- All random-slope candidates were singular. The random-intercept model converged and was not singular.
- Pearson dispersion ratio: 0.934.
- Approximate overdispersion test p: .977.
- Fixed-effect design matrix condition number: 9.45.
- Observed and fitted condition-time means agreed closely.

## Additional sensitivity analyses

### Leave-one-target-out

All 10 deletion fits retained positive estimates for all three planned contrasts. Grounding versus Thematic ranged from 0.149 to 0.184 in probability change, and Grounding versus Control ranged from 0.281 to 0.326. Both remained Holm-significant in every fit.

Thematic versus Control ranged from 0.113 to 0.146. It was not Holm-significant when `retain` was omitted, p = .0520, or when `overlook` was omitted, p = .0707. It was significant in the other eight fits. The correct interpretation is that the Thematic advantage over Control is positive but item-sensitive.

### Leave-one-participant-out

All 90 refits succeeded and were non-singular. Every estimate remained positive. Maximum absolute movement from the full-data probability contrast was 0.0138 for Grounding versus Thematic, 0.0153 for Grounding versus Control, and 0.0152 for Thematic versus Control. All 270 contrast tests remained Holm-significant at .05.

### Crossed participant-item bootstrap

The 1,000-repetition bootstrap resampled participants within condition and resampled target items. Two fits were singular but all 1,000 converged.

| Contrast | Median difference in change | Percentile 95% interval | Proportion above zero |
|---|---:|---:|---:|
| Grounding vs Thematic | 0.166 | 0.031 to 0.313 | .989 |
| Grounding vs Control | 0.312 | 0.157 to 0.466 | 1.000 |
| Thematic vs Control | 0.144 | 0.003 to 0.278 | .977 |

### Bayesian random-slopes sensitivity

The Bayesian binomial model included time slopes for participants and target items. It used four chains, 2,000 iterations per chain, and weakly regularizing priors.

| Contrast | Posterior mean difference in change | 95% credible interval | Posterior probability above zero |
|---|---:|---:|---:|
| Grounding vs Thematic | 0.167 | 0.055 to 0.286 | .9978 |
| Grounding vs Control | 0.292 | 0.174 to 0.409 | 1.0000 |
| Thematic vs Control | 0.125 | 0.010 to 0.241 | .9820 |

The posterior probability of the strict ordering Grounding greater than Thematic greater than Control in change was .9798. There were no divergent transitions or maximum-treedepth hits. Maximum R-hat was 1.003 and minimum bulk effective sample size was 1,342.

## Response transitions

Among responses that were incorrect at pretest, the post-test correct proportions were:

| Condition | Incorrect to correct | Model-estimated post-test probability |
|---|---:|---:|
| Control | 40/174, 23.0% | .230 |
| Thematic | 78/172, 45.3% | .453 |
| Grounding | 124/171, 72.5% | .725 |

Among responses that were correct at pretest, post-test correctness was 94.4% in Control, 93.0% in Thematic, and 96.9% in Grounding. The condition differences in this pretest-correct subset were not significant.

Both random-intercept variances in the exploratory transition model were estimated at zero, so that model is singular. The paired transition counts are more defensible than the model-based standard errors. In addition, these are response transitions rather than clean knowledge-state transitions because the test format changed.

## Reliability and score stability

Overall KR-20 was .390 at pretest, 95% bootstrap interval .173 to .543, and .463 at post-test, interval .265 to .588. These values are low for a conventional unidimensional scale.

Within-condition KR-20 estimates were unstable with only 30 participants. Grounding post-test KR-20 was negative, -.634, interval -1.865 to -.057, under a strong ceiling. A negative coefficient means that the observed item covariance pattern does not support treating the 10 post-test items as a reliable additive scale in that cell.

Pretest and post-test score correlations were positive within each condition: Control r = .757, Thematic r = .627, and Grounding r = .443. They are descriptive associations, not test-retest reliability coefficients, because the question format changed.

## Secondary items, Q11 to Q20

Accuracy increased within each condition:

| Condition | Pretest | Post-test | Within-condition post vs pre odds ratio | 95% CI | Holm p |
|---|---:|---:|---:|---:|---:|
| Control | .590 | .753 | 2.29 | 1.59 to 3.30 | 9.89e-6 |
| Thematic | .510 | .687 | 2.28 | 1.61 to 3.25 | 8.77e-6 |
| Grounding | .457 | .667 | 2.60 | 1.83 to 3.68 | 2.76e-7 |

No between-condition inference is made for Q11 to Q20 because each condition received a different item set.

## Interpretation limit

The pretest and immediate post-test use different question formats. The condition by time interaction controls for a shared format change, but it does not eliminate the possibility that the format change interacts with condition for a reason unrelated to instruction.
