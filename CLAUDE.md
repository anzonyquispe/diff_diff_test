# CLAUDE.md - Project Documentation

## Project Overview
This repository contains comparative analysis and benchmarking of difference-in-differences (DID) estimation methods across different platforms (Stata, R, Python).

## Repository Structure
- `CX/` - Contains benchmark scripts, test files, and comparison outputs for `did_multiplegt_dyn` implementations

## Key Files
- `CX/test_did_multiplegt_dyn_comprehensive.do` - Stata implementation
- `CX/test_did_multiplegt_dyn_comprehensive.R` - R implementation
- `CX/test_did_multiplegt_dyn_comprehensive.py` - Python implementation
- `CX/comparison_did_multiplegt_dyn.ipynb` - Jupyter notebook for comparison analysis
- `CX/benchmark_wolfers_complete.R` - R benchmark comparing DID estimators
- `CX/benchmark_wolfers_python.ipynb` - Python benchmark (pyfixest, did-multiplegt-dyn, linearmodels)
- `CX/benchmark_wolfers_stata.do` - Stata benchmark (did_multiplegt_dyn, csdid, reghdfe)

## Output Files
- `coefficients_*.csv` - Coefficient estimates from each platform
- `runtime_*.csv` - Runtime benchmarks from each platform
- `*_comparison*.png` - Visualization comparing results across platforms

## Session Log

### Session: 2026-02-02
- Initial CLAUDE.md created to track project documentation and collaboration
- Created Python benchmark notebook: `CX/benchmark_wolfers_python.ipynb`
  - Replicates R benchmark `benchmark_wolfers_complete.R` using Python packages
  - **Updated with all requested estimators:**
    - `pyfixest.event_study()` - Sun-Abraham style event study
    - `did-multiplegt-dyn` (DidMultiplegtDyn) - De Chaisemartin & D'Haultfoeuille
    - `pyfixest.feols()` - Two-Way Fixed Effects
    - `linearmodels.PanelOLS` - Panel data fixed effects
  - Tests on 3 data scales: Original (1.7K), 100x (168K), 1000x (1.68M rows)

#### Benchmark Results (Time in seconds)

| Package | Original (1.7K) | 100x (168K) | 1000x (1.68M) |
|---------|-----------------|-------------|---------------|
| pyfixest-EventStudy | 3.64s | 0.43s | 2.97s |
| did-multiplegt-dyn | 0.49s | 1.15s | 7.59s |
| pyfixest-TWFE | 0.61s | 0.14s | 0.61s |
| linearmodels-PanelOLS | 0.02s | 0.62s | 5.49s |

#### Key Findings
- **pyfixest-TWFE** is the fastest for large datasets (~0.6s for 1.68M rows)
- **did-multiplegt-dyn** (Python Polars version) scales reasonably (~7.6s for 1.68M rows)
- TWFE coefficient for `udl`: **-0.055** (not significant, p=0.346)
- Note: did-multiplegt-dyn requires **Polars DataFrames**, not pandas

- Created Stata benchmark: `CX/benchmark_wolfers_stata.do`
  - Replicates Python/R benchmark using Stata packages
  - **Estimators included:**
    - `did_multiplegt_dyn` - De Chaisemartin & D'Haultfoeuille (2024)
    - `csdid` - Callaway & Sant'Anna (2021)
    - `eventstudyinteract` - Sun & Abraham (2021)
    - `reghdfe` - Standard Two-Way Fixed Effects
  - Tests on 3 data scales: Original (1.7K), 100x (168K), 1000x (1.68M rows)
  - Output: `benchmark_results_stata.csv`

### Session: 2026-02-03
- **Updated Stata benchmark** (`benchmark_wolfers_stata.do`) to include:
  - `did_imputation` - Borusyak, Jaravel & Spiess (2024)
  - Now includes 5 estimators matching the R benchmark

- **Updated Python notebook** (`benchmark_wolfers_python.ipynb`):
  - Added note that `did_imputation` (Borusyak, Jaravel & Spiess 2024) is NOT available in Python
  - Added new "Large Dataset Comparison" section at the end of the notebook
  - Section includes:
    - Cross-platform availability table (Python vs R vs Stata)
    - Code to load and combine results from all platforms
    - Visualization comparing runtimes across platforms by dataset size
    - Key observations on scaling behavior and platform differences

#### Package Availability Summary

| Estimator | Python | R | Stata |
|-----------|--------|---|-------|
| De Chaisemartin & D'Haultfoeuille (did_multiplegt_dyn) | ✓ | ✓ | ✓ |
| Callaway & Sant'Anna (csdid/did) | ✓ | ✓ | ✓** |
| Borusyak, Jaravel & Spiess (did_imputation) | ✗ | ✓ | ✓ |
| Sun & Abraham (eventstudyinteract/sunab) | ✓* | ✓ | ✓ |
| Two-Way Fixed Effects (reghdfe/feols) | ✓ | ✓ | ✓ |

*via pyfixest event_study()
**csdid in Stata uses bootstrap for inference (affects runtime)

### Session: 2026-02-06
- **Updated all benchmark files** per Clément's email about textbook dofile changes
- **Key specification changes:**
  - `did_multiplegt_dyn`: Now uses `effects(13) placebo(13)` (was 16/9)
  - `did_imputation`: Now uses `horizons(0/12) pre(13)` (was horizons(0/15) pre(9))
  - All estimators now show **13 effects and 13 placebos** per textbook recommendation

- **Files updated:**
  1. `CX/benchmark_wolfers_stata.do` - Updated did_multiplegt_dyn and did_imputation specs
  2. `CX/benchmark_wolfers_complete.R` - Updated DIDmultiplegtDYN specs
  3. `CX/benchmark_wolfers_python.ipynb` - Updated DidMultiplegtDyn specs

- **Important note for runtime comparison:**
  - `csdid` in Stata uses **bootstrap** for inference by default
  - This makes csdid slower than analytical SE estimators
  - Documented in all benchmark files

- **Fixed synthetic data creation:**
  - Each replication now gets unique state IDs: `state + (replication-1) * max_state`
  - Example: Original states 1-51, replication 2 gets states 52-102, replication 3 gets 103-153, etc.
  - Ensures proper panel structure (unique state-year combinations)
  - Fixed in all three files (Stata, R, Python)

#### The 4 Key Commands to Benchmark (from solution.do lines 45, 82, 119, 134)

| Estimator | Stata Command |
|-----------|---------------|
| Sun & Abraham | `eventstudyinteract div_rate rel_time* [aweight=stpop], absorb(i.state i.year) cohort(cohort) control_cohort(controlgroup) vce(cluster state)` |
| Callaway & Sant'Anna | `csdid div_rate [weight=stpop], ivar(state) time(year) gvar(cohort) notyet agg(event)` |
| de Chaisemartin & D'Haultfoeuille | `did_multiplegt_dyn div_rate state year udl, effects(13) placebo(13) weight(stpop)` |
| Borusyak et al. | `did_imputation div_rate state year cohort [aweight=stpop], horizons(0/12) autosample minn(0) pre(13)` |

---

## Notes
- Current branch: `main_test`
- Main branch for PRs: `main`
