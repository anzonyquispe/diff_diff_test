################################################################################
# File: test_did_multiplegt_dyn_comprehensive.py
# Purpose: Comprehensive test of did_multiplegt_dyn matching all Stata specs
# OUTPUT: runtime_Python.csv, coefficients_Python.csv
################################################################################

import sys
import time
import pandas as pd
import numpy as np
import polars as pl
import warnings

# Add path to did_multiplegt_dyn module
sys.path.insert(0, "/Users/anzony.quisperojas/Documents/GitHub/did_multiplegt_dyn_py/polars")
sys.path.insert(0, "/Users/anzony.quisperojas/Documents/GitHub/did_multiplegt_dyn_py")
from did_multiplegt_main_polars import did_multiplegt_main_pl as did_multiplegt_main

# Paths
DATA_PATH = "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
SAVE_PATH = "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

# Initialize results storage
runtime_results = []
coef_results = []


def run_test(df, outcome, group, time_col, treatment, example, model, **kwargs):
    """Run a single test and capture results."""
    print(f"--- {example} : {model} ---")
    start = time.time()

    # Convert to polars if needed
    if isinstance(df, pd.DataFrame):
        df_pl = pl.from_pandas(df)
    else:
        df_pl = df

    try:
        result = did_multiplegt_main(
            df=df_pl,
            outcome=outcome,
            group=group,
            time=time_col,
            treatment=treatment,
            **kwargs
        )
        success = True
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        result = None
        success = False

    elapsed = time.time() - start
    print(f"Runtime: {elapsed:.4f} seconds\n")

    # Store runtime
    runtime_results.append({
        "Example": example,
        "Model": model,
        "Runtime_sec": elapsed,
        "Platform": "Python"
    })

    # Helper function to extract numeric index from string like "Effect_1" or "Placebo_2"
    def extract_numeric_index(idx):
        if isinstance(idx, (int, float)):
            return int(idx)
        if isinstance(idx, str):
            # Try to extract number from strings like "Effect_1", "Placebo_2"
            import re
            match = re.search(r'(\d+)$', idx)
            if match:
                return int(match.group(1))
        return idx

    # Extract Effects if successful
    if success and result is not None:
        try:
            dyn_results = result.get("did_multiplegt_dyn", {})

            # Extract Effects
            effects_df = dyn_results.get("Effects")
            if effects_df is not None and len(effects_df) > 0:
                for idx, row in effects_df.iterrows():
                    if idx != "Average":  # Skip average row for now
                        coef_results.append({
                            "Example": example,
                            "Model": model,
                            "Type": "Effect",
                            "Index": extract_numeric_index(idx),
                            "Estimate": row.get("Estimate", row.get("estimate", np.nan)),
                            "SE": row.get("SE", row.get("se", np.nan))
                        })

                # Extract Average Effect
                if "Average" in effects_df.index:
                    avg_row = effects_df.loc["Average"]
                    coef_results.append({
                        "Example": example,
                        "Model": model,
                        "Type": "Avg_Effect",
                        "Index": 0,
                        "Estimate": avg_row.get("Estimate", avg_row.get("estimate", np.nan)),
                        "SE": avg_row.get("SE", avg_row.get("se", np.nan))
                    })

            # Extract Placebos
            placebos_df = dyn_results.get("Placebos")
            if placebos_df is not None and len(placebos_df) > 0:
                for idx, row in placebos_df.iterrows():
                    coef_results.append({
                        "Example": example,
                        "Model": model,
                        "Type": "Placebo",
                        "Index": extract_numeric_index(idx),
                        "Estimate": row.get("Estimate", row.get("estimate", np.nan)),
                        "SE": row.get("SE", row.get("se", np.nan))
                    })

            print("Effects extracted successfully")
        except Exception as e:
            print(f"Warning: Could not extract effects: {e}")

    return result


def main():
    print("=" * 80)
    print("did_multiplegt_dyn Comprehensive Python Tests")
    print(f"Python version: {sys.version}")
    print("=" * 80 + "\n")

    ############################################################################
    # WAGEPAN TESTS - Matching all Stata specifications
    ############################################################################
    print("\n" + "=" * 80)
    print("WAGEPAN DATASET")
    print("=" * 80 + "\n")

    wagepan = pd.read_stata(f"{DATA_PATH}/wagepan.dta")
    print(f"Data loaded: {len(wagepan)} observations\n")

    # Define common parameters for wagepan
    n_eff = 5
    n_pl = 2

    # 1. Baseline (no placebos)
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Baseline",
             effects=n_eff, placebo=0)

    # 2. Placebos
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Placebos",
             effects=n_eff, placebo=n_pl)

    # 3. Normalized
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Normalized",
             effects=n_eff, placebo=n_pl, normalized=True)

    # 4. Controls
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Controls",
             effects=n_eff, placebo=n_pl, controls=["hours"])

    # 5. Trends_Nonparam
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Nonparam",
             effects=n_eff, placebo=n_pl, trends_nonparam=["black"])

    # 6. Trends_Lin
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Lin",
             effects=n_eff, placebo=n_pl, trends_lin=True)

    # 7. Continuous
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Continuous",
             effects=n_eff, placebo=n_pl, continuous=1)

    # 8. Weight
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Weight",
             effects=n_eff, placebo=n_pl, weight="educ")

    # 9. Cluster
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Cluster",
             effects=n_eff, placebo=n_pl, cluster="hisp")

    # 10. Same_Switchers
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Same_Switchers",
             effects=n_eff, placebo=n_pl, same_switchers=True)

    # 11. Same_Switchers_Placebo
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Same_Switchers_Placebo",
             effects=n_eff, placebo=n_pl, same_switchers=True, same_switchers_pl=True)

    # 12. Switchers_In
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_In",
             effects=n_eff, placebo=n_pl, switchers="in")

    # 13. Switchers_Out
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_Out",
             effects=n_eff, placebo=n_pl, switchers="out")

    # 14. Only_Never_Switchers
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Only_Never_Switchers",
             effects=n_eff, placebo=n_pl, only_never_switchers=True)

    # 15. CI_Level_90
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "CI_Level_90",
             effects=n_eff, placebo=n_pl, ci_level=90)

    # 16. CI_Level_99
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "CI_Level_99",
             effects=n_eff, placebo=n_pl, ci_level=99)

    # 17. Less_Conservative_SE
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Less_Conservative_SE",
             effects=n_eff, placebo=n_pl, less_conservative_se=True)

    # 18. Bootstrap - NOT IMPLEMENTED IN PYTHON
    print("--- Wagepan : Bootstrap ---")
    print("SKIPPED: Bootstrap not implemented in Python package\n")
    runtime_results.append({
        "Example": "Wagepan",
        "Model": "Bootstrap",
        "Runtime_sec": np.nan,
        "Platform": "Python"
    })

    # 19. Dont_Drop_Larger_Lower
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Dont_Drop_Larger_Lower",
             effects=n_eff, placebo=n_pl, dont_drop_larger_lower=True)

    # 20. Effects_Equal
    run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Effects_Equal",
             effects=n_eff, placebo=n_pl, effects_equal=True)

    ############################################################################
    # FAVARA-IMBS TESTS
    ############################################################################
    print("\n" + "=" * 80)
    print("FAVARA-IMBS DATASET")
    print("=" * 80 + "\n")

    try:
        favara = pd.read_stata(f"{DATA_PATH}/favara_imbs.dta")
        print(f"Data loaded: {len(favara)} observations\n")
        run_test(favara, "Dl_hpi", "county", "year", "inter_bra", "Favara_Imbs", "Baseline",
                 effects=5, placebo=3, cluster="state_n")
    except Exception as e:
        print(f"Error loading Favara-Imbs dataset: {e}\n")

    ############################################################################
    # DERYUGINA TESTS
    ############################################################################
    print("\n" + "=" * 80)
    print("DERYUGINA (2017)")
    print("=" * 80 + "\n")

    try:
        deryugina = pd.read_stata(f"{DATA_PATH}/deryugina_2017.dta")
        print(f"Data loaded: {len(deryugina)} observations\n")
        run_test(deryugina, "log_curr_trans_ind_gov_pc", "county_fips", "year", "hurricane",
                 "Deryugina", "Baseline", effects=11, placebo=11, cluster="county_fips")
    except Exception as e:
        print(f"Dataset not found or error: {e}\n")

    ############################################################################
    # GENTZKOW TESTS
    ############################################################################
    print("\n" + "=" * 80)
    print("GENTZKOW (2011)")
    print("=" * 80 + "\n")

    try:
        gentzkow = pd.read_stata(f"{DATA_PATH}/gentzkow.dta")
        print(f"Data loaded: {len(gentzkow)} observations\n")
        run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Non_Normalized",
                 effects=4, placebo=4)
        run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Normalized",
                 effects=4, placebo=4, normalized=True)
    except Exception as e:
        print(f"Dataset not found or error: {e}\n")

    ############################################################################
    # SAVE RESULTS
    ############################################################################
    print("\n" + "=" * 80)
    print("RUNTIME SUMMARY (Python)")
    print("=" * 80 + "\n")

    runtime_df = pd.DataFrame(runtime_results)
    print(runtime_df)
    total_runtime = runtime_df["Runtime_sec"].sum(skipna=True)
    print(f"\nTotal runtime: {total_runtime:.2f} seconds")
    runtime_df.to_csv(f"{SAVE_PATH}/runtime_Python.csv", index=False)

    print("\nCOEFFICIENTS SUMMARY")
    coef_df = pd.DataFrame(coef_results)
    print(coef_df.head(40))
    coef_df.to_csv(f"{SAVE_PATH}/coefficients_Python.csv", index=False)

    print("\nResults saved to:")
    print(f"  - {SAVE_PATH}/runtime_Python.csv")
    print(f"  - {SAVE_PATH}/coefficients_Python.csv")

    print("\n" + "=" * 80)
    print("COMPLETE")
    print("=" * 80)


if __name__ == "__main__":
    main()
