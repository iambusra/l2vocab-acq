.PHONY: all setup data analysis additional

PYTHON ?= .venv/bin/python
PYTHON_ENV := .venv/pyvenv.cfg
RSCRIPT ?= Rscript

all: setup data analysis additional

$(PYTHON_ENV): requirements.txt
	python3 -m venv .venv
	.venv/bin/python -m pip install --disable-pip-version-check -r requirements.txt

setup: $(PYTHON_ENV)
	$(RSCRIPT) -e 'renv::restore(prompt = FALSE)'

data: $(PYTHON_ENV)
	$(PYTHON) scripts/extract_numbers.py
	$(RSCRIPT) analysis/01_prepare_data.R

analysis:
	$(RSCRIPT) analysis/02_descriptives.R
	$(RSCRIPT) analysis/03_primary_glmm.R
	$(RSCRIPT) analysis/04_planned_contrasts.R
	$(RSCRIPT) analysis/05_secondary_items.R
	$(RSCRIPT) analysis/06_figures.R
	$(RSCRIPT) analysis/07_diagnostics.R
	$(RSCRIPT) analysis/08_validate_outputs.R

additional:
	$(RSCRIPT) analysis/09_leave_one_item_out.R
	$(RSCRIPT) analysis/10_participant_influence.R
	$(RSCRIPT) analysis/11_crossed_bootstrap.R
	$(RSCRIPT) analysis/12_response_transitions.R
	$(RSCRIPT) analysis/13_bayesian_sensitivity.R
	$(RSCRIPT) analysis/14_reliability.R
	$(RSCRIPT) analysis/15_additional_figures.R
	$(RSCRIPT) analysis/16_validate_extended_outputs.R
