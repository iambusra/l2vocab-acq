# L2 vocabulary acquisition experiment

This private repository contains the raw data, reproducible processing pipeline, statistical models, diagnostics, tables, and figures for the pretest and immediate post-test waves of the L2 vocabulary acquisition experiment.

## Design

Ninety participants were assigned to one of three instructional conditions, with 30 participants in each condition:

- Grounding: target words were taught through explicit lexical-semantic relationships.
- Thematic: target words and additional words appeared in coherent contexts without an explicit lexical-semantic relationship.
- Control: target words and unrelated additional words received comparable exposure.

Q1 to Q10 test the same 10 target words in every condition. Q11 to Q20 use different word sets by condition, so those items are kept in a separate secondary analysis.

The pretest and post-test use different question formats. The overall time effect therefore combines learning and test format. The primary estimand is the time by condition interaction, but it still assumes that the format change does not affect the conditions differently for unrelated reasons. See [docs/experiment-design.md](docs/experiment-design.md) for the full design and analysis decisions.

## Main results

Raw mean target scores out of 10 were:

| Condition | Pretest | Post-test | Gain |
|---|---:|---:|---:|
| Control | 4.20 | 5.30 | 1.10 |
| Thematic | 4.27 | 6.57 | 2.30 |
| Grounding | 4.30 | 8.30 | 4.00 |

The trial-level binomial mixed model found a time by condition interaction, likelihood-ratio chi-square(2) = 35.24, p = 2.23e-8. Random slopes were attempted first, but every slope specification was singular. The retained model used participant and target-item random intercepts:

```r
correct ~ time * condition + (1 | participant_id) + (1 | item_id)
```

Planned contrasts on model-predicted probability change were:

| Contrast | Difference in change | 95% CI | Holm p |
|---|---:|---:|---:|
| Grounding vs Thematic | 17.2 percentage points | 5.9 to 28.5 | .0057 |
| Grounding vs Control | 30.4 percentage points | 18.7 to 42.1 | 1.01e-6 |
| Thematic vs Control | 13.2 percentage points | 1.6 to 24.9 | .0259 |

The participant-level ANCOVA robustness analysis produced the same ordering. The adjusted post-test odds ratios were 2.61 for Grounding vs Thematic, 4.45 for Grounding vs Control, and 1.71 for Thematic vs Control.

Q11 to Q20 improved from pretest to post-test within all three conditions. Those results are descriptive and within-condition only. The pipeline does not make a causal between-condition comparison because the item sets differ.

## Reproduce the analysis

Requirements:

- R 4.4 or compatible
- Python 3.10 or newer
- GNU Make or compatible

From the repository root:

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
make all
```

`make all` creates a local Python environment, installs the pinned Numbers parser, extracts the Numbers tables, rebuilds the processed data, fits every model, and regenerates all tables and figures. R package versions are recorded in `renv.lock`. Python dependencies are pinned in `requirements.txt`.

## Repository layout

```text
data/raw/          Unchanged Apple Numbers source files and checksums
data/interim/      Canonical CSV exports from the Numbers packages
data/processed/    Scored response, participant, item, and key datasets
analysis/          Ordered R analysis scripts and the full pipeline runner
R/                 Shared project, modeling, and plotting functions
docs/              Experiment design and statistical decisions
figures/           Publication figures in PDF and PNG formats
output/models/     Plain-text model summaries
output/tables/     Tidy CSV results and descriptive tables
output/diagnostics Model selection records and diagnostic outputs
scripts/           Reproducible Numbers extraction script
```

## Privacy

The data use coded participant IDs only. No names, email addresses, recruitment records, consent records, or direct identifiers are present. Figures and model tables do not display participant codes. Do not add identifying records to this repository.

