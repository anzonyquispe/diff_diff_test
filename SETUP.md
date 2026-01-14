# Complete Setup Guide: DiD Package Comparison

This document provides step-by-step instructions to set up dedicated environments and run all difference-in-differences packages for staggered treatment analysis.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Design Decisions](#2-design-decisions)
3. [Prerequisites](#3-prerequisites)
4. [Environment Setup](#4-environment-setup)
5. [Running the Analysis](#5-running-the-analysis)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Project Overview

### Objective

Benchmark and compare DiD estimators designed for:
- **Staggered treatment adoption** (units treated at different times)
- **Heterogeneous treatment effects** (effects vary by cohort and time)

### Methods Tested

| Method | Authors | Paper |
|--------|---------|-------|
| Group-time ATT | Callaway & Sant'Anna (2021) | Difference-in-differences with multiple time periods |
| Robust DiD | de Chaisemartin & D'Haultfoeuille (2020) | Two-way fixed effects with heterogeneous effects |
| Interaction-weighted | Sun & Abraham (2021) | Estimating dynamic treatment effects in event studies |
| Imputation | Borusyak, Jaravel & Spiess (2024) | Revisiting event study designs |

### Package Availability

| Method | R | Python | Stata |
|--------|---|--------|-------|
| Callaway & Sant'Anna | `did` | `csdid`, `diff_diff` | `csdid` |
| de Chaisemartin | `DIDmultiplegtDYN` | `did_multiplegt_dyn` | `did_multiplegt_dyn` |
| Sun & Abraham | `fixest::sunab` | `pyfixest` | `eventstudyinteract` |
| Borusyak et al. | `didimputation` | **NOT AVAILABLE** | `did_imputation` |

---

## 2. Design Decisions

### 2.1 Simulation Design

We follow the Callaway & Sant'Anna (2021) simulation framework:

```
Data Generating Process:
Y_it = α_i + λ_t + τ_gt × D_it + ε_it

Where:
- α_i: Unit fixed effect ~ N(0, 1)
- λ_t: Time fixed effect (linear trend from -0.2 to 0.2)
- D_it: Treatment indicator
- τ_gt: Heterogeneous treatment effect
- ε_it: Idiosyncratic error ~ N(0, 1)
```

### 2.2 Heterogeneous Treatment Effects

Treatment effects vary by:

1. **Cohort** (when first treated):
   - 2012 cohort: +0.5 bonus effect
   - 2014 cohort: +0.3 bonus effect
   - 2016 cohort: +0.1 bonus effect
   - 2018 cohort: +0.0 bonus effect

2. **Time since treatment** (dynamic effects):
   - Effect grows by 0.1 per period post-treatment

```
τ_gt = 1.0 + δ_g + 0.1 × (t - g)

Example for 2012 cohort in 2015:
τ = 1.0 + 0.5 + 0.1 × (2015 - 2012) = 1.0 + 0.5 + 0.3 = 1.8
```

### 2.3 Sample Size

- **1,000,000 units** (to stress-test computational performance)
- **10 time periods** (2010-2019)
- **10,000,000 total observations**

### 2.4 Treatment Assignment

| Cohort | Probability | N Units |
|--------|-------------|---------|
| Never treated | 30% | ~300,000 |
| 2012 | 20% | ~200,000 |
| 2014 | 20% | ~200,000 |
| 2016 | 20% | ~200,000 |
| 2018 | 10% | ~100,000 |

### 2.5 Why These Packages?

| Package | Reason for Inclusion |
|---------|---------------------|
| `did` (R) | Original implementation by Callaway & Sant'Anna |
| `csdid` (Python) | Most complete Python port of the R package |
| `diff_diff` (Python) | Fast alternative implementation |
| `DIDmultiplegtDYN` (R) | de Chaisemartin's official R package |
| `did_multiplegt_dyn` (Python) | Python port of de Chaisemartin's method |
| `fixest::sunab` (R) | Sun & Abraham via the fast fixest package |
| `pyfixest` (Python) | Python port of fixest |
| `didimputation` (R) | Borusyak et al. imputation approach |

---

## 3. Prerequisites

### 3.1 System Requirements

- **macOS**, Linux, or Windows (WSL recommended for Windows)
- **8GB+ RAM** (16GB recommended for 1M observations)
- **10GB free disk space**

### 3.2 Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| R | >= 4.2.0 | R package analysis |
| Python | >= 3.9 | Python package analysis |
| Quarto | >= 1.4 | Render the book |
| Git | any | Version control |

---

## 4. Environment Setup

### 4.1 Install Quarto

```bash
# macOS (using Homebrew)
brew install quarto

# Linux (Debian/Ubuntu)
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.555/quarto-1.4.555-linux-amd64.deb
sudo dpkg -i quarto-1.4.555-linux-amd64.deb

# Verify installation
quarto --version
```

### 4.2 Clone the Repository

```bash
cd ~/Documents/GitHub  # or your preferred location
git clone https://github.com/YOUR_USERNAME/diff_diff_test.git
cd diff_diff_test
```

### 4.3 Python Environment Setup

#### Option A: Using Conda (Recommended)

```bash
# Create a new conda environment
conda create -n did_comparison python=3.11 -y

# Activate the environment
conda activate did_comparison

# Install packages
pip install numpy pandas matplotlib seaborn

# DiD packages
pip install csdid
pip install diff-diff
pip install did-multiplegt-dyn
pip install pyfixest
pip install linearmodels

# Jupyter support for Quarto
pip install jupyter ipykernel
python -m ipykernel install --user --name did_comparison --display-name "DiD Comparison"

# Verify installations
python -c "import csdid; print('csdid:', csdid.__version__ if hasattr(csdid, '__version__') else 'OK')"
python -c "from did_multiplegt_dyn import did_multiplegt_dyn; print('did_multiplegt_dyn: OK')"
python -c "import pyfixest; print('pyfixest:', pyfixest.__version__)"
```

#### Option B: Using venv

```bash
# Create virtual environment
python3 -m venv .venv

# Activate (macOS/Linux)
source .venv/bin/activate

# Activate (Windows)
# .venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip

# Install packages
pip install numpy pandas matplotlib seaborn jupyter ipykernel
pip install csdid diff-diff did-multiplegt-dyn pyfixest linearmodels

# Register kernel for Quarto
python -m ipykernel install --user --name did_comparison --display-name "DiD Comparison"
```

### 4.4 R Environment Setup

#### Option A: Using renv (Recommended)

```bash
# Open R in the project directory
cd /path/to/diff_diff_test
R
```

Then in R:

```r
# Initialize renv
install.packages("renv")
renv::init()

# Install required packages
install.packages(c(
  # Core DiD packages
  "did",
  "fixest",
  "DIDmultiplegtDYN",
  "didimputation",

  # Dependencies
  "dplyr",
  "ggplot2",
  "knitr",
  "rmarkdown",

  # For doubly-robust estimation
  "DRDID"
))

# Snapshot the environment
renv::snapshot()

# Verify installations
library(did)
library(fixest)
library(DIDmultiplegtDYN)
library(didimputation)
cat("All R packages installed successfully!\n")
```

#### Option B: Global Installation

```r
# In R console
install.packages(c(
  "did",
  "fixest",
  "DIDmultiplegtDYN",
  "didimputation",
  "dplyr",
  "ggplot2",
  "knitr",
  "rmarkdown",
  "DRDID"
))
```

### 4.5 Verify Complete Setup

```bash
# Check Quarto
quarto check

# Check Python environment
conda activate did_comparison  # or source .venv/bin/activate
python -c "
import csdid
from did_multiplegt_dyn import did_multiplegt_dyn
import pyfixest
import linearmodels
print('All Python packages OK')
"

# Check R environment
Rscript -e "
library(did)
library(fixest)
library(DIDmultiplegtDYN)
library(didimputation)
cat('All R packages OK\n')
"
```

---

## 5. Running the Analysis

### 5.1 Render the Complete Book

```bash
# Activate Python environment first
conda activate did_comparison  # or source .venv/bin/activate

# Navigate to project directory
cd /path/to/diff_diff_test

# Render the entire book
quarto render

# The output will be in _book/index.html
open _book/index.html  # macOS
# xdg-open _book/index.html  # Linux
```

### 5.2 Render Individual Chapters

```bash
# Just the data generation
quarto render data_generation.qmd

# Just the R analysis
quarto render r_analysis.qmd

# Just the Python analysis
quarto render python_analysis.qmd

# Just the comparison
quarto render comparison.qmd
```

### 5.3 Run Interactively in RStudio/VS Code

#### RStudio
1. Open `diff_diff_test.Rproj` (or create one)
2. Open any `.qmd` file
3. Click "Render" button

#### VS Code
1. Install Quarto extension
2. Open any `.qmd` file
3. Press `Cmd+Shift+K` (macOS) or `Ctrl+Shift+K`

### 5.4 Run R Code Separately

```bash
# Generate data
Rscript -e "
source('data_generation.qmd')  # Won't work directly
# Instead, extract R code:
"

# Or run R interactively
R
```

```r
# In R console
setwd("/path/to/diff_diff_test")

# Run data generation
source(knitr::purl("data_generation.qmd", output = tempfile()))

# Run R analysis
source(knitr::purl("r_analysis.qmd", output = tempfile()))
```

### 5.5 Run Python Code Separately

```bash
conda activate did_comparison

# Start Python
python
```

```python
# In Python
import pandas as pd
import numpy as np
from csdid.att_gt import ATTgt

# Load data (after R generates it)
df = pd.read_csv("sim_data.csv")

# Run csdid
att_gt = ATTgt(
    yname='y',
    gname='first_treat',
    idname='id',
    tname='year',
    data=df,
    control_group='nevertreated'
)
results = att_gt.fit(est_method='dr')
print(results.aggte(typec='dynamic'))
```

---

## 6. Troubleshooting

### 6.1 Common Issues

#### "Package not found" errors

```bash
# Python
pip install --upgrade csdid diff-diff did-multiplegt-dyn pyfixest linearmodels

# R
install.packages("PACKAGE_NAME", dependencies = TRUE)
```

#### Memory errors with 1M observations

Reduce sample size in `data_generation.qmd`:

```r
n_units <- 100000  # Instead of 1000000
```

#### Quarto render fails

```bash
# Check Quarto installation
quarto check

# Update Quarto
brew upgrade quarto  # macOS
```

#### R packages fail to load

```r
# Check for conflicts
conflicts()

# Reinstall problematic package
remove.packages("PACKAGE_NAME")
install.packages("PACKAGE_NAME")
```

### 6.2 Package-Specific Issues

#### `didimputation` installation fails

```r
# Install from GitHub if CRAN version has issues
install.packages("devtools")
devtools::install_github("kylebutts/didimputation")
```

#### `DIDmultiplegtDYN` is slow

The de Chaisemartin estimator is computationally intensive. Use a subsample:

```r
# In r_analysis.qmd, use 10% sample
sample_ids <- sample(unique(panel$id), size = 100000)
panel_sample <- panel[panel$id %in% sample_ids, ]
```

#### `pyfixest` sunab not working

```python
# Check pyfixest version
import pyfixest
print(pyfixest.__version__)

# Update to latest
pip install --upgrade pyfixest
```

#### `fixest::sunab` aggregate extraction error

The `aggregate()` function in fixest returns coefficients directly. Use:

```r
# Instead of coef(aggregate(out_sa, agg = "ATT"))
# Use:
agg_sa <- summary(out_sa, agg = "ATT")
sa_coefs <- coef(agg_sa)
```

#### `reticulate` not found error

Quarto needs the R package `reticulate` to run Python code:

```r
install.packages("reticulate")
```

Also create `.Rprofile` to point to your conda environment:

```r
# .Rprofile content:
Sys.setenv(RETICULATE_PYTHON = "/opt/anaconda3/envs/did_comparison/bin/python")
```

### 6.3 Getting Help

- **did package**: https://bcallaway11.github.io/did/
- **fixest**: https://lrberge.github.io/fixest/
- **DIDmultiplegtDYN**: https://github.com/chaisemartinPackages/did_multiplegt_dyn
- **didimputation**: https://github.com/kylebutts/didimputation
- **csdid (Python)**: https://github.com/d2cml-ai/csdid
- **pyfixest**: https://github.com/py-econometrics/pyfixest

---

## Appendix: Full Command Sequence

Here's the complete sequence of commands to run from scratch:

```bash
# 1. Navigate to project
cd ~/Documents/GitHub/diff_diff_test

# 2. Create and activate Python environment
conda create -n did_comparison python=3.11 -y
conda activate did_comparison

# 3. Install Python packages
pip install numpy pandas matplotlib seaborn jupyter ipykernel
pip install csdid diff-diff did-multiplegt-dyn pyfixest linearmodels
python -m ipykernel install --user --name did_comparison

# 4. Install R packages (run in R console)
Rscript -e "install.packages(c('did', 'fixest', 'DIDmultiplegtDYN', 'didimputation', 'dplyr', 'ggplot2', 'knitr', 'rmarkdown', 'DRDID'), repos='https://cran.rstudio.com/')"

# 5. Verify setup
quarto check
python -c "import csdid; print('Python OK')"
Rscript -e "library(did); cat('R OK\n')"

# 6. Render the book
quarto render

# 7. Open results
open _book/index.html
```

---

## Version Information

This guide was created for:
- R 4.5.2
- Python 3.11+
- Quarto 1.4+
- macOS / Linux

Last updated: January 2025
