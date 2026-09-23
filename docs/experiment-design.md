# Experiment design

## Research question

Does the organization of vocabulary instruction change acquisition of the same English target words?

## Design

The experiment has one between-participant factor and one within-participant factor:

- Condition: Grounding, Thematic, or Control, with 30 participants per condition.
- Time: pretest and immediate post-test for the current dataset. One-week and one-month retention waves are planned but not present.

All groups are tested on the same 10 target words in Q1 to Q10: reconsider, avoidable, uncertain, maintain, settle, misleading, discourage, retain, overlook, and engage.

- Grounding instruction explicitly connects targets to lexical-semantic relations such as morphology, synonymy, antonymy, contrast, senses, or collocation.
- Thematic instruction presents targets and additional words in coherent university or workplace contexts without teaching a lexical-semantic relationship.
- Control instruction provides comparable exposure with unrelated additional words presented independently.

Q11 to Q20 contain different word sets for the three conditions. These items are analyzed separately because a between-condition comparison would confound condition with item set.

## Measurement caveat

The pretest and immediate post-test use different question formats. Therefore, the overall time effect combines learning with a test-format change. The primary estimand is the time by condition interaction because all conditions undergo the same format change. Interpretation still depends on the assumption that the format change does not affect conditions differently for reasons unrelated to instruction.

## Primary analysis

The primary outcome is trial-level correctness on Q1 to Q10. The planned binomial mixed-effects model is:

```text
correct ~ time * condition + (1 + time | participant_id) + (1 + time | item_id)
```

The maximal justified random-effects structure is attempted first. If it is singular or fails to converge, the pipeline follows a documented sequence that removes correlation parameters and then unsupported slopes. The first converged, non-singular model in that sequence is retained.

Planned contrasts compare pre-to-post change for:

1. Grounding versus Thematic
2. Grounding versus Control
3. Thematic versus Control

P-values are adjusted with Holm's method across the three planned contrasts.

## Robustness and secondary analyses

- Participant-level binomial ANCOVA: post-test target successes out of 10 modeled by condition and centered pretest accuracy.
- Descriptive participant gain distributions and trajectories.
- Item-level accuracy and change for the 10 common target words.
- Q11 to Q20 analyzed within condition and time. No causal between-condition claim is made because the item sets differ.

## Privacy

The repository contains coded participant IDs only. Analytic tables and figures do not print participant IDs, and no direct identifiers should be added.

