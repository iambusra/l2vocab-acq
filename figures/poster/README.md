# Poster-ready figures

Every figure is supplied in three formats:

- PDF for direct placement in most poster software.
- SVG for editable vector graphics.
- PNG for previewing and software that cannot import vectors. Individual PNGs are 600 dpi; the 24 by 21 inch summary plate is 300 dpi.

## Recommended poster set

The strongest compact poster story uses:

1. `01_primary_learning_curve` for the main condition by time result.
2. `02_primary_contrasts` for effect sizes and uncertainty.
3. `06_leave_one_item_out` or `08_crossed_bootstrap` for robustness.
4. `10_response_transitions` for an intuitive explanation of the change.
5. `11_reliability` for the measurement limitation.

`13_summary_plate` combines nine key panels into one coordinated 3 by 3 figure. It can be used intact or as a layout guide.

## Complete figure list

| File stem | Analysis shown |
|---|---|
| `01_primary_learning_curve` | Model-predicted target accuracy and participant scores |
| `02_primary_contrasts` | Planned differences in probability change |
| `03_gain_distributions` | Participant-level gain distributions |
| `04_ancova_adjusted_posttest` | Pretest-adjusted post-test probabilities |
| `05_item_change_heatmap` | Raw change for every target word and condition |
| `06_leave_one_item_out` | Sensitivity to removing each target word |
| `07_participant_influence` | Sensitivity to removing each participant |
| `08_crossed_bootstrap` | Crossed participant-item bootstrap distributions |
| `09_bayesian_sensitivity` | Bayesian random-slopes posterior contrasts |
| `10_response_transitions` | Post-test correctness conditional on pretest response |
| `11_reliability` | KR-20 estimates and bootstrap intervals |
| `12_secondary_items` | Descriptive Q11 to Q20 changes |
| `13_summary_plate` | Nine-panel primary and robustness summary |
| `14_target_filler_examples` | Example shared targets and condition-specific filler words |
| `15_target_filler_performance` | Target and filler accuracy over time |
| `16_target_filler_plate` | Combined target-filler design and performance plate |

## Interpretation constraints

The pretest and post-test used different question formats. Keep the format-change caption with the primary result. Q11 to Q20 used different item sets by condition, so the secondary-item figure supports within-condition description only. The transition model was singular, so its panel is exploratory. The reliability plot should remain in the poster or limitations section because the internal-consistency results are weak.
