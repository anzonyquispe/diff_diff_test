################################################################################
# File: test_did_multiplegt_dyn_polars.R
# Purpose: Test did_multiplegt_dyn using DIDmultiplegtDYNpolars package
# OUTPUT: runtime_R_polars.csv, coefficients_R_polars.csv
################################################################################

library(DIDmultiplegtDYN)
library(haven)
library(dplyr)
library(polars)

data_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
save_path <- "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

# Initialize results storage
runtime_results <- data.frame(Example=character(), Model=character(),
                               Runtime_sec=numeric(), Platform=character())
coef_results <- data.frame(Example=character(), Model=character(),
                            Type=character(), Index=integer(),
                            Estimate=numeric(), SE=numeric())

# Helper function
run_test <- function(df, outcome, group, time, treatment, example, model, ...) {
  cat("---", example, ":", model, "---\n")
  start <- Sys.time()

  result <- tryCatch({
    did_multiplegt_dyn(df=df, outcome=outcome, group=group, time=time,
                       treatment=treatment, graph_off=TRUE, ...)
  }, error = function(e) { cat("Error:", e$message, "\n"); NULL })

  elapsed <- as.numeric(difftime(Sys.time(), start, units="secs"))
  cat("Runtime:", round(elapsed, 4), "seconds\n\n")

  # Store runtime
  runtime_results <<- rbind(runtime_results,
    data.frame(Example=example, Model=model, Runtime_sec=elapsed, Platform="R_Polars"))
  print(summary(result))

  # Extract Effects if successful
  if (!is.null(result) && "results" %in% names(result) && "Effects" %in% names(result$results)) {
    effects_mat <- result$results$Effects
    for (i in seq_len(nrow(effects_mat))) {
      coef_results <<- rbind(coef_results,
        data.frame(Example=example, Model=model, Type="Effect", Index=i,
                   Estimate=effects_mat[i, "Estimate"], SE=effects_mat[i, "SE"]))
    }
  }

  # Extract Placebos if available
  if (!is.null(result) && "results" %in% names(result) && "Placebos" %in% names(result$results)) {
    placebos_mat <- result$results$Placebos
    for (i in seq_len(nrow(placebos_mat))) {
      coef_results <<- rbind(coef_results,
        data.frame(Example=example, Model=model, Type="Placebo", Index=i,
                   Estimate=placebos_mat[i, "Estimate"], SE=placebos_mat[i, "SE"]))
    }
  }

  invisible(result)
}

cat(strrep("=", 80), "\n")
cat("did_multiplegt_dyn R POLARS Package Tests\n")
cat("Polars version:", as.character(packageVersion("polars")), "\n")
cat(strrep("=", 80), "\n\n")

################################################################################
# WAGEPAN TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "WAGEPAN DATASET\n", strrep("=", 80), "\n\n", sep="")
wagepan <- read_dta(file.path(data_path, "wagepan.dta"))
cat("Data loaded:", nrow(wagepan), "observations\n\n")

run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Baseline", effects=5)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Placebos", effects=5, placebo=2)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Normalized", effects=5, placebo=2, normalized=TRUE)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Controls", effects=5, placebo=2, controls=c("hours"))
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Nonparam", effects=5, placebo=2, trends_nonparam="black")
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Trends_Lin", effects=5, placebo=2, trends_lin=TRUE)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Cluster", effects=5, placebo=2, cluster="hisp")
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Same_Switchers", effects=5, placebo=2, same_switchers=TRUE)
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_In", effects=5, placebo=2, switchers="in")
run_test(wagepan, "lwage", "nr", "year", "union", "Wagepan", "Switchers_Out", effects=5, placebo=2, switchers="out")

################################################################################
# FAVARA-IMBS TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "FAVARA-IMBS DATASET\n", strrep("=", 80), "\n\n", sep="")
favara <- read_dta(file.path(data_path, "favara_imbs.dta"))
cat("Data loaded:", nrow(favara), "observations\n\n")
run_test(favara, "Dl_hpi", "county", "year", "inter_bra", "Favara_Imbs", "Baseline",
         effects=5, placebo=3, cluster="state_n")

################################################################################
# DERYUGINA TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "DERYUGINA (2017)\n", strrep("=", 80), "\n\n", sep="")
deryugina_file <- file.path(data_path, "deryugina_2017.dta")
if (file.exists(deryugina_file)) {
  deryugina <- read_dta(deryugina_file)
  cat("Data loaded:", nrow(deryugina), "observations\n\n")
  run_test(deryugina, "log_curr_trans_ind_gov_pc", "county_fips", "year", "hurricane",
           "Deryugina", "Baseline", effects=11, placebo=11, cluster="county_fips")
} else {
  cat("Dataset not found.\n")
}

################################################################################
# GENTZKOW TESTS
################################################################################
cat("\n", strrep("=", 80), "\n", "GENTZKOW (2011)\n", strrep("=", 80), "\n\n", sep="")
gentzkow_file <- file.path(data_path, "gentzkow.dta")
if (file.exists(gentzkow_file)) {
  gentzkow <- read_dta(gentzkow_file)
  cat("Data loaded:", nrow(gentzkow), "observations\n\n")
  run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Non_Normalized", effects=4, placebo=4)
  run_test(gentzkow, "prestout", "cnty90", "year", "numdailies", "Gentzkow", "Normalized", effects=4, placebo=4, normalized=TRUE)
} else {
  cat("Dataset not found.\n")
}

################################################################################
# SAVE RESULTS
################################################################################
cat("\n", strrep("=", 80), "\n", "RUNTIME SUMMARY (R POLARS)\n", strrep("=", 80), "\n\n", sep="")
print(runtime_results)
cat("\nTotal runtime:", round(sum(runtime_results$Runtime_sec), 2), "seconds\n")
write.csv(runtime_results, file.path(save_path, "runtime_R_polars.csv"), row.names=FALSE)

cat("\nCOEFFICIENTS SUMMARY\n")
print(head(coef_results, 30))
write.csv(coef_results, file.path(save_path, "coefficients_R_polars.csv"), row.names=FALSE)

cat("\nResults saved to:\n")
cat("  -", file.path(save_path, "runtime_R_polars.csv"), "\n")
cat("  -", file.path(save_path, "coefficients_R_polars.csv"), "\n")

# Load CRAN results for comparison if available
cran_file <- file.path(save_path, "runtime_R_cran.csv")
if (file.exists(cran_file)) {
  cat("\n", strrep("=", 80), "\n", "COMPARISON: Polars vs CRAN\n", strrep("=", 80), "\n\n", sep="")
  cran <- read.csv(cran_file)
  comparison <- runtime_results %>%
    select(Example, Model, Runtime_Polars=Runtime_sec) %>%
    left_join(cran %>% select(Example, Model, Runtime_CRAN=Runtime_sec), by=c("Example", "Model")) %>%
    mutate(Speedup = Runtime_CRAN / Runtime_Polars,
           Speedup_pct = (Runtime_CRAN - Runtime_Polars) / Runtime_CRAN * 100)
  print(comparison)
  cat("\nAverage speedup:", round(mean(comparison$Speedup, na.rm=TRUE), 2), "x\n")
  write.csv(comparison, file.path(save_path, "runtime_comparison_polars_vs_cran.csv"), row.names=FALSE)
}

cat("\n", strrep("=", 80), "\n", "COMPLETE\n", strrep("=", 80), "\n", sep="")
