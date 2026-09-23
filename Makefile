.PHONY: all setup data analysis

PYTHON ?= .venv/bin/python
PYTHON_ENV := .venv/pyvenv.cfg
RSCRIPT ?= Rscript

all: setup data analysis

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
