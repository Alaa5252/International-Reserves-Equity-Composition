# Data

This folder contains the source data used by `master.do` and the derived analysis dataset created during replication.

## Folder Structure

- `input/` — source data files required to construct the analysis dataset.
- `derived/` — contains `analysis_data.dta`, which is generated automatically by `master.do`.

The `derived/` folder does not need to contain any files before replication.

## Input Data

The source files in `input/` are combined by `master.do` to construct the final country-year analysis dataset.

The analysis draws on publicly available data from the following sources:

- External Wealth of Nations Database
- World Development Indicators
- Worldwide Governance Indicators
- CBOE via FRED
- Federal Reserve Economic Data (FRED)
- Ilzetzki, Reinhart, and Rogoff exchange-rate-regime classifications

The main input files include variables for:

- foreign portfolio equity liabilities;
- foreign direct investment liabilities;
- the FPI share in total foreign equity investment;
- international reserves;
- total external liabilities;
- GDP and GDP per capita;
- GDP-per-capita growth;
- trade openness;
- natural-resource rents;
- institutional-quality indicators;
- exchange-rate regimes;
- VIX measures;
- the U.S. three-month Treasury-bill rate; and
- the advanced-economy / EMDE classification.

See `../variable_dictionary.xlsx` for the mapping between variable descriptions, Stata variable names, and notation used in the paper.

## Derived Dataset

Running:

    do master.do

from the repository root creates:

    data/derived/analysis_data.dta

This dataset contains the merged source data together with the transformations and lags required for the empirical analysis.

Users should not need to edit or manually construct the derived dataset.
