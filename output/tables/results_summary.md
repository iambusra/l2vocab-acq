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
