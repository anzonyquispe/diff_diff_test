################################################################################
# File: test_did_multiplegt_dyn_comprehensive.R
# Purpose: Comprehensive test of did_multiplegt_dyn matching all Stata specs
# OUTPUT: runtime_R.csv, coefficients_R.csv
################################################################################

library(DIDmultiplegtDYN)
library(haven)
library(dplyr)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
save_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

# Initialize results storage
runtime_results <- data.frame(
  Example = character(),
  Model = character(),
  Runtime_sec = numeric(),
  Platform = character(),
  stringsAsFactors = FALSE
)

coef_results <- data.frame(
  Example = character(),
  Model = character(),
  Type = character(),
  Index = integer(),
  Estimate = numeric(),
  SE = numeric(),
  stringsAsFactors = FALSE
)

# Helper function to run tests and extract results
run_test <- function(df, outcome, group, time, treatment, example, model, ...) {
  cat("---", example, ":", model, "---\n")
  start <- Sys.time()

  result <- tryCatch({
    did_multiplegt_dyn(df = df, outcome = outcome, group = group, time = time,
                       treatment = treatment, graph_off = TRUE, ...)
  }, error = function(e) {
    cat("Error:", e$message, "\n")
    NULL
  })

  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  cat("Runtime:", round(elapsed, 4), "seconds\n\n")

  # Store runtime
  runtime_results <<- rbind(runtime_results,
    data.frame(Example = example, Model = model, Runtime_sec = elapsed,
               Platform = "R", stringsAsFactors = FALSE))

  if (!is.null(result)) {
    print(summary(result))
  }

  # Extract Effects if successful
  if (!is.null(result) && "results" %in% names(result) && "Effects" %in% names(result$results)) {
    effects_mat <- result$results$Effects
    for (i in seq_len(nrow(effects_mat))) {
      coef_results <<- rbind(coef_results,
        data.frame(Example = example, Model = model, Type = "Effect", Index = i,
                   Estimate = effects_mat[i, "Estimate"], SE = effects_mat[i, "SE"],
                   stringsAsFactors = FALSE))
    }
  }

  # Extract Placebos if available
  if (!is.null(result) && "results" %in% names(result) && "Placebos" %in% names(result$results)) {
    placebos_mat <- result$results$Placebos
    for (i in seq_len(nrow(placebos_mat))) {
      coef_results <<- rbind(coef_results,
        data.frame(Example = example, Model = model, Type = "Placebo", Index = i,
                   Estimate = placebos_mat[i, "Estimate"], SE = placebos_mat[i, "SE"],
                   stringsAsFactors = FALSE))
    }
  }

  # Extract Average Effect if available
  if (!is.null(result) && "results" %in% names(result) && "Average_effect" %in% names(result$results)) {
    avg_eff <- result$results$Average_effect
    coef_results <<- rbind(coef_results,
      data.frame(Example = example, Model = model, Type = "Avg_Effect", Index = 0,
                 Estimate = avg_eff[1, "Estimate"], SE = avg_eff[1, "SE"],
                 stringsAsFactors = FALSE))
  }

  invisible(result)
}

cat(strrep("=", 80), "\n")
cat("did_multiplegt_dyn Comprehensive R Tests\n")
cat("DIDmultiplegtDYN version:", as.character(packageVersion("DIDmultiplegtDYN")), "\n")
cat("R version:", R.version$version.string, "\n")
cat(strrep("=", 80), "\n\n")

################################################################################
# WAGEPAN TESTS - Matching all Stata specifications
################################################################################
cat("\n", strrep("=", 80), "\n", "WAGEPAN DATASET\n", strrep("=", 80), "\n\n", sep = "")
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))
cat("Data loaded:", nrow(wagepan), "observations\n\n")

# Define common parameters for wagepan
n_eff <- 5
n_pl <- 2

# 1. Baseline (no placebos)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Baseline",
         effects = n_eff)

# 2. Placebos
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Placebos",
         effects = n_eff, placebo = n_pl)

# 3. Normalized
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Normalized",
         effects = n_eff, placebo = n_pl, normalized = TRUE)

# 4. Controls
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Controls",
         effects = n_eff, placebo = n_pl, controls = c("hours"))

# 5. Trends_Nonparam
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Nonparam",
         effects = n_eff, placebo = n_pl, trends_nonparam = "black")

# 6. Trends_Lin
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Lin",
         effects = n_eff, placebo = n_pl, trends_lin = TRUE)

# 7. Continuous
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Continuous",
         effects = n_eff, placebo = n_pl, continuous = 1)

# 8. Weight
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Weight",
         effects = n_eff, placebo = n_pl, weight = "educ")

# 9. Cluster
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Cluster",
         effects = n_eff, placebo = n_pl, cluster = "hisp")

# 10. Same_Switchers
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Same_Switchers",
         effects = n_eff, placebo = n_pl, same_switchers = TRUE)

# 11. Same_Switchers_Placebo
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Same_Switchers_Placebo",
         effects = n_eff, placebo = n_pl, same_switchers = TRUE, same_switchers_pl = TRUE)

# 12. Switchers_In
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_In",
         effects = n_eff, placebo = n_pl, switchers = "in")

# 13. Switchers_Out
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_Out",
         effects = n_eff, placebo = n_pl, switchers = "out")

# 14. Only_Never_Switchers
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Only_Never_Switchers",
         effects = n_eff, placebo = n_pl, only_never_switchers = TRUE)

# 15. CI_Level_90
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "CI_Level_90",
         effects = n_eff, placebo = n_pl, ci_level = 90)

# 16. CI_Level_99
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "CI_Level_99",
         effects = n_eff, placebo = n_pl, ci_level = 99)

# 17. Less_Conservative_SE
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Less_Conservative_SE",
         effects = n_eff, placebo = n_pl, less_conservative_se = TRUE)

# 18. Bootstrap (reps, seed)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Bootstrap",
         effects = n_eff, placebo = n_pl, bootstrap = 20)

# 19. Dont_Drop_Larger_Lower
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Dont_Drop_Larger_Lower",
         effects = n_eff, placebo = n_pl, dont_drop_larger_lower = TRUE)

# 20. Effects_Equal
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Effects_Equal",
         effects = n_eff, placebo = n_pl, effects_equal = TRUE)

################################################################################
# FAVARA-IMBS TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "FAVARA-IMBS DATASET\n", strrep("=", 80), "\n\n", sep = "")
favara <- read_dta(file.path(data_path, "favara_imbs.dta"))
cat("Data loaded:", nrow(favara), "observations\n\n")

run_test(favara, "Dl_hpi", "county", "year", "inter_bra", "Favara_Imbs", "Baseline",
         effects = 5, placebo = 3, cluster = "state_n")

################################################################################
# DERYUGINA TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "DERYUGINA (2017)\n", strrep("=", 80), "\n\n", sep = "")
deryugina_file <- file.path(data_path, "deryugina_2017.dta")
if (file.exists(deryugina_file)) {
  deryugina <- read_dta(deryugina_file)
  cat("Data loaded:", nrow(deryugina), "observations\n\n")
  run_test(deryugina, "log_curr_trans_ind_gov_pc", "county_fips", "year", "hurricane",
           "Deryugina", "Baseline", effects = 11, placebo = 11, cluster = "county_fips")
} else {
  cat("Dataset not found.\n")
}

################################################################################
# GENTZKOW TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "GENTZKOW (2011)\n", strrep("=", 80), "\n\n", sep = "")
gentzkow_file <- file.path(data_path, "gentzkow.dta")
if (file.exists(gentzkow_file)) {
  gentzkow <- read_dta(gentzkow_file)
  cat("Data loaded:", nrow(gentzkow), "observations\n\n")
  run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Non_Normalized",
           effects = 4, placebo = 4)
  run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Normalized",
           effects = 4, placebo = 4, normalized = TRUE)
} else {
  cat("Dataset not found.\n")
}

################################################################################
# SAVE RESULTS
################################################################################
cat("\n", strrep("=", 80), "\n", "RUNTIME SUMMARY (R)\n", strrep("=", 80), "\n\n", sep = "")
print(runtime_results)
cat("\nTotal runtime:", round(sum(runtime_results$Runtime_sec), 2), "seconds\n")
write.csv(runtime_results, file.path(save_path, "runtime_R.csv"), row.names = FALSE)

cat("\nCOEFFICIENTS SUMMARY\n")
print(head(coef_results, 40))
write.csv(coef_results, file.path(save_path, "coefficients_R.csv"), row.names = FALSE)

cat("\nResults saved to:\n")
cat("  -", file.path(save_path, "runtime_R.csv"), "\n")
cat("  -", file.path(save_path, "coefficients_R.csv"), "\n")

cat("\n", strrep("=", 80), "\n", "COMPLETE\n", strrep("=", 80), "\n", sep = "")
