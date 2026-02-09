"""
File: test_did_multiplegt_dyn_python.py
Purpose: Test did_multiplegt_dyn using Python implementation
         with comprehensive runtime tracking for cross-platform comparison

OUTPUT: Runtime information saved to CSV for comparison with Stata/R

Requirements:
    pip install py-did-multiplegt-dyn pandas numpy scipy statsmodels
    # Or install from local:
    # pip install -e /Users/anzony.quisperojas/Documents/GitHub/did_multiplegt_dyn_py
"""

import sys
import os
import time
import pandas as pd
import numpy as np
from pathlib import Path

# Add the local package path
sys.path.insert(0, '/Users/anzony.quisperojas/Documents/GitHub/did_multiplegt_dyn_py')

# Import the main function
try:
    from did_multiplegt_main import did_multiplegt_main
    print("Loaded local did_multiplegt_main package")
except ImportError:
    try:
        from py_did_multiplegt_dyn import did_multiplegt_dyn as did_multiplegt_main
        print("Loaded py-did-multiplegt-dyn from PyPI")
    except ImportError:
        print("ERROR: Could not import did_multiplegt_dyn. Please install:")
        print("  pip install py-did-multiplegt-dyn")
        print("  or add local path to sys.path")
        sys.exit(1)

# Set paths
DATA_PATH = Path("/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data")
SAVE_PATH = Path("/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX")

# Runtime results storage
runtime_results = []


def read_dta_file(filepath):
    """Read Stata .dta file into pandas DataFrame"""
    return pd.read_stata(filepath)


def run_timed_estimation(df, outcome, group, time_var, treatment, example, model, **kwargs):
    """Run estimation with timing and store results"""
    print(f"--- {model} ---")

    start_time = time.time()

    try:
        result = did_multiplegt_main(
            df=df,
            outcome=outcome,
            group=group,
            time=time_var,
            treatment=treatment,
            **kwargs
        )
        error = None
    except Exception as e:
        result = None
        error = str(e)

    exec_time = time.time() - start_time
    print(f"Runtime: {exec_time:.4f} seconds")

    if error:
        print(f"Error: {error}")

    # Store runtime
    runtime_results.append({
        'Example': example,
        'Model': model,
        'Runtime_sec': exec_time,
        'Platform': 'Python',
        'Error': error
    })

    return result, exec_time, error


print("=" * 80)
print("did_multiplegt_dyn Python Package Tests with Runtime Tracking")
print("=" * 80)
print()

################################################################################
#                    WAGEPAN DATASET TESTS (MAIN BENCHMARK)
################################################################################

print("\n" + "=" * 80)
print("WAGEPAN DATASET TESTS - MAIN BENCHMARK")
print("=" * 80 + "\n")

wagepan_file = DATA_PATH / "wagepan.dta"
if wagepan_file.exists():
    wagepan = read_dta_file(wagepan_file)
    print(f"Data loaded: {len(wagepan):,} observations\n")

    # Test configurations matching Stata/R
    test_configs = [
        {"name": "Baseline", "effects": 5, "placebo": 0, "extra": {}},
        {"name": "Placebos", "effects": 5, "placebo": 2, "extra": {}},
        {"name": "Normalized", "effects": 5, "placebo": 2, "extra": {"normalized": True}},
        {"name": "Controls", "effects": 5, "placebo": 2, "extra": {"controls": "hours"}},
        {"name": "Trends_Nonparam", "effects": 5, "placebo": 2, "extra": {"trends_nonparam": "black"}},
        {"name": "Trends_Lin", "effects": 5, "placebo": 2, "extra": {"trends_lin": True}},
        {"name": "Cluster", "effects": 5, "placebo": 2, "extra": {"cluster": "hisp"}},
        {"name": "Same_Switchers", "effects": 5, "placebo": 2, "extra": {"same_switchers": True}},
        {"name": "Switchers_In", "effects": 5, "placebo": 2, "extra": {"switchers": "in"}},
        {"name": "Switchers_Out", "effects": 5, "placebo": 2, "extra": {"switchers": "out"}},
    ]

    for config in test_configs:
        run_timed_estimation(
            df=wagepan,
            outcome="lwage",
            group="nr",
            time_var="year",
            treatment="union",
            example="Wagepan",
            model=config["name"],
            effects=config["effects"],
            placebo=config["placebo"],
            **config["extra"]
        )
        print()

else:
    print("Wagepan dataset not found. Skipping.")

################################################################################
#                    FAVARA-IMBS DATASET
################################################################################

print("\n" + "=" * 80)
print("FAVARA-IMBS DATASET")
print("=" * 80 + "\n")

favara_file = DATA_PATH / "favara_imbs.dta"
if favara_file.exists():
    favara = read_dta_file(favara_file)
    print(f"Data loaded: {len(favara):,} observations\n")

    run_timed_estimation(
        df=favara,
        outcome="log_hp_all_tiers",
        group="state_fips",
        time_var="year",
        treatment="dereg",
        example="Favara_Imbs",
        model="Baseline",
        effects=5,
        placebo=3,
        cluster="state_fips"
    )
    print()
else:
    print("Favara dataset not found. Skipping.")

################################################################################
#                    DERYUGINA (2017)
################################################################################

print("\n" + "=" * 80)
print("DERYUGINA (2017) - Hurricane Effects")
print("=" * 80 + "\n")

deryugina_file = DATA_PATH / "deryugina_2017.dta"
if deryugina_file.exists():
    deryugina = read_dta_file(deryugina_file)
    print(f"Data loaded: {len(deryugina):,} observations\n")

    run_timed_estimation(
        df=deryugina,
        outcome="log_curr_trans_ind_gov_pc",
        group="county_fips",
        time_var="year",
        treatment="hurricane",
        example="Deryugina",
        model="Baseline",
        effects=11,
        placebo=11,
        cluster="county_fips"
    )
    print()
else:
    print("Deryugina dataset not found. Skipping.")

################################################################################
#                    GENTZKOW (2011)
################################################################################

print("\n" + "=" * 80)
print("GENTZKOW (2011) - Newspaper Effects")
print("=" * 80 + "\n")

gentzkow_file = DATA_PATH / "gentzkow.dta"
if not gentzkow_file.exists():
    gentzkow_file = DATA_PATH / "gentzkowetal_didtextbook.dta"

if gentzkow_file.exists():
    gentzkow = read_dta_file(gentzkow_file)
    print(f"Data loaded: {len(gentzkow):,} observations\n")

    # Non-normalized
    run_timed_estimation(
        df=gentzkow,
        outcome="prestout",
        group="cnty90",
        time_var="year",
        treatment="numdailies",
        example="Gentzkow",
        model="Non_Normalized",
        effects=4,
        placebo=4,
        effects_equal="all"
    )
    print()

    # Normalized
    run_timed_estimation(
        df=gentzkow,
        outcome="prestout",
        group="cnty90",
        time_var="year",
        treatment="numdailies",
        example="Gentzkow",
        model="Normalized",
        effects=4,
        placebo=4,
        normalized=True,
        effects_equal="all"
    )
    print()
else:
    print("Gentzkow dataset not found. Skipping.")

################################################################################
#                    SAVE AND DISPLAY RESULTS
################################################################################

print("\n" + "=" * 80)
print("RUNTIME SUMMARY (PYTHON)")
print("=" * 80 + "\n")

# Convert to DataFrame
runtime_df = pd.DataFrame(runtime_results)
print(runtime_df.to_string(index=False))

# Calculate totals
total_time = runtime_df['Runtime_sec'].sum()
print(f"\nTotal runtime: {total_time:.2f} seconds")

# Save runtime results
runtime_df.to_csv(SAVE_PATH / "runtime_python.csv", index=False)
print(f"\nResults saved to: {SAVE_PATH / 'runtime_python.csv'}")

################################################################################
#                    CROSS-PLATFORM COMPARISON
################################################################################

print("\n" + "=" * 80)
print("CROSS-PLATFORM COMPARISON")
print("=" * 80 + "\n")

# Load other platform results if available
comparison_data = []

# Add Python results
for _, row in runtime_df.iterrows():
    comparison_data.append({
        'Example': row['Example'],
        'Model': row['Model'],
        'Platform': 'Python',
        'Runtime_sec': row['Runtime_sec']
    })

# Load Stata results
stata_file = SAVE_PATH / "runtime_stata.csv"
if stata_file.exists():
    stata_df = pd.read_csv(stata_file)
    for _, row in stata_df.iterrows():
        comparison_data.append({
            'Example': row['Example'],
            'Model': row['Model'],
            'Platform': 'Stata',
            'Runtime_sec': row['Runtime_sec']
        })

# Load R CRAN results
r_cran_file = SAVE_PATH / "runtime_R_cran.csv"
if r_cran_file.exists():
    r_cran_df = pd.read_csv(r_cran_file)
    for _, row in r_cran_df.iterrows():
        comparison_data.append({
            'Example': row['Example'],
            'Model': row['Model'],
            'Platform': 'R_CRAN',
            'Runtime_sec': row['Runtime_sec']
        })

# Load R Polars results
r_polars_file = SAVE_PATH / "runtime_R_polars.csv"
if r_polars_file.exists():
    r_polars_df = pd.read_csv(r_polars_file)
    for _, row in r_polars_df.iterrows():
        comparison_data.append({
            'Example': row['Example'],
            'Model': row['Model'],
            'Platform': 'R_Polars',
            'Runtime_sec': row['Runtime_sec']
        })

# Create comparison DataFrame
if len(comparison_data) > len(runtime_df):
    comparison_df = pd.DataFrame(comparison_data)

    # Pivot for comparison
    pivot_df = comparison_df.pivot_table(
        index=['Example', 'Model'],
        columns='Platform',
        values='Runtime_sec',
        aggfunc='first'
    ).reset_index()

    print("Runtime Comparison (seconds):")
    print(pivot_df.to_string(index=False))

    # Calculate speedups
    if 'R_Polars' in pivot_df.columns and 'R_CRAN' in pivot_df.columns:
        pivot_df['Polars_vs_CRAN_Speedup'] = pivot_df['R_CRAN'] / pivot_df['R_Polars']
        print(f"\nR Polars vs R CRAN average speedup: {pivot_df['Polars_vs_CRAN_Speedup'].mean():.2f}x")

    # Save comparison
    comparison_df.to_csv(SAVE_PATH / "runtime_all_platforms.csv", index=False)
    pivot_df.to_csv(SAVE_PATH / "runtime_comparison_pivot.csv", index=False)
    print(f"\nComparison saved to: {SAVE_PATH / 'runtime_all_platforms.csv'}")
    print(f"Pivot table saved to: {SAVE_PATH / 'runtime_comparison_pivot.csv'}")
else:
    print("No other platform results found for comparison.")
    print("Run the Stata and R scripts first.")

print("\n" + "=" * 80)
print("ESTIMATION COMPLETE - Python Package")
print("=" * 80)
