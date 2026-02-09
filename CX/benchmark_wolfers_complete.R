# Comprehensive Benchmark: DID Estimators Comparison
# Comparing: R (DIDmultiplegtDYN), did (CS), didimputation, fixest (Sun-Abraham)
# Dataset: wolfers2006_didtextbook.dta
# Specification: did_multiplegt_dyn div_rate state year udl, effects(13) placebo(13) weight(stpop)
#
# UPDATED 2026-02-06: Per Clément's email, now using 13 effects and 13 placebos
# NOTE: csdid/did uses bootstrap for inference in Stata (affects runtime comparison)

library(haven)
library(DIDmultiplegtDYN)
library(did)
library(didimputation)
library(fixest)
library(dplyr)
library(data.table)
library(ggplot2)
library(polars)
library(R.utils)

# Set timeout (5 minutes in seconds)
TIMEOUT_SECONDS <- 300
setwd('/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX')

# Helper function for separator
sep_line <- function() paste(rep("=", 70), collapse = "")

# Output file for logging
log_file <- "benchmark_wolfers_complete.log"
sink(log_file, split = TRUE)

cat(sep_line(), "\n")
cat("COMPREHENSIVE BENCHMARK: DID Estimators Comparison\n")
cat(sep_line(), "\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("Packages: DIDmultiplegtDYN, did (CS), didimputation, fixest (SA)\n")
cat("Timeout: 5 minutes (300 seconds)\n\n")

# Load original data
cat("Loading data...\n")
wolfers <- as.data.frame(read_dta("../_data/wolfers2006_didtextbook.dta"))
cat("Original data rows:", nrow(wolfers), "\n")

# Prepare data for different packages
# Create first treatment time variable for CS/SA estimators
wolfers <- as.data.table(wolfers)
wolfers[, cohort_sa := fifelse(cohort == 0, 5000, cohort)]
wolfers[, event_time_binned := fcase(
  cohort_sa == 5000, 0,
  year - cohort_sa + 1 < -13, -13,
  year - cohort_sa + 1 > 13, 13,
  default = year - cohort_sa + 1
)]

cat("Unique states:", length(unique(wolfers$state)), "\n")
cat("Year range:", min(wolfers$year), "-", max(wolfers$year), "\n")
cat("Treatment groups (first_treat):", paste(sort(unique(wolfers$first_treat)), collapse = ", "), "\n\n")

# Function to run benchmark with timeout
run_with_timeout <- function(expr, timeout_sec = TIMEOUT_SECONDS) {
  result <- list(time = NA, output = NULL, status = "error")
  tryCatch({
    start_time <- Sys.time()
    result$output <- withTimeout(eval(expr), timeout = timeout_sec)
    end_time <- Sys.time()
    result$time <- as.numeric(difftime(end_time, start_time, units = "secs"))
    result$status <- "completed"
  }, TimeoutException = function(e) {
    result$time <- timeout_sec
    result$status <- paste("timeout: exceeded", timeout_sec, "seconds")
  }, error = function(e) {
    result$status <- paste("error:", e$message)
  })
  return(result)
}

# Function to create synthetic data by duplicating groups
# Each replication gets unique state IDs: state + (replication-1) * max_state
create_synthetic_data <- function(df, multiplier) {
  if (multiplier == 1) return(df)

  max_state <- max(df$state)

  result_list <- list()
  for (i in 1:multiplier) {
    temp_df <- copy(df)
    # Apply offset to create unique state IDs for each replication
    offset <- (i - 1) * max_state
    temp_df$state <- temp_df$state + offset
    result_list[[i]] <- temp_df
  }

  result <- rbindlist(result_list)

  cat("Created synthetic data with", nrow(result), "observations\n")
  cat("Unique states:", length(unique(result$state)), "\n")

  return(result)
}

# Store all results
results <- data.frame(
  scenario = character(),
  package = character(),
  rows = numeric(),
  time_seconds = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

# ============================================================
# SCENARIO 1: Original Data (1,683 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 1: Original Data (", nrow(wolfers), " rows)\n")
cat(sep_line(), "\n\n")

# 1. DIDmultiplegtDYN
cat("1. Running DIDmultiplegtDYN...\n")
res_cran <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 13,
    placebo = 13,
    weight = "stpop"
  )
}))
cat("   Time:", ifelse(res_cran$status == "completed",
                       paste(round(res_cran$time, 2), "seconds"),
                       res_cran$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "DIDmultiplegtDYN",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_cran$status == "completed", res_cran$time, NA),
  status = res_cran$status
))

# 2. did (Callaway-Sant'Anna)
cat("2. Running did (Callaway-Sant'Anna)...\n")
res_cs <- run_with_timeout(quote({
  out <- att_gt(
    yname = "div_rate",
    tname = "year",
    idname = "state",
    gname = "cohort",
    data = wolfers,
    weightsname = "stpop",
    est_method = "dr",
    base_period = "universal"
  )
  aggte(out, type = "dynamic", min_e = -13, max_e = 13)
}))
cat("   Time:", ifelse(res_cs$status == "completed",
                       paste(round(res_cs$time, 2), "seconds"),
                       res_cs$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "did-CS",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_cs$status == "completed", res_cs$time, NA),
  status = res_cs$status
))

# 3. didimputation
cat("3. Running didimputation...\n")
res_didimp <- run_with_timeout(quote({
  did_imputation(
    data = wolfers,
    yname = "div_rate",
    gname = "cohort",
    tname = "year",
    idname = "state",
    wname = "stpop",
    horizon = c(1:13),
    pretrends = c(-13:-1)
  )
}))
cat("   Time:", ifelse(res_didimp$status == "completed",
                       paste(round(res_didimp$time, 2), "seconds"),
                       res_didimp$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "didimputation",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_didimp$status == "completed", res_didimp$time, NA),
  status = res_didimp$status
))

# 4. fixest (Sun-Abraham)
cat("4. Running fixest (Sun-Abraham)...\n")
res_sa <- run_with_timeout(quote({
  feols(
    div_rate ~ sunab(cohort_sa, event_time_binned, ref.p = 0) | state + year,
    data = wolfers,
    weights = ~stpop,
    vcov = ~state
  )
}))
cat("   Time:", ifelse(res_sa$status == "completed",
                       paste(round(res_sa$time, 2), "seconds"),
                       res_sa$status), "\n")
results <- rbind(results, data.frame(
  scenario = "Original (1.7K)",
  package = "fixest-SA",
  rows = nrow(wolfers),
  time_seconds = ifelse(res_sa$status == "completed", res_sa$time, NA),
  status = res_sa$status
))

# ============================================================
# SCENARIO 2: Synthetic Data 100x (168,300 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 2: Synthetic Data 100x\n")
cat(sep_line(), "\n\n")

wolfers_100x <- create_synthetic_data(wolfers, 100)
cat("Synthetic data rows:", nrow(wolfers_100x), "\n\n")

# 1. DIDmultiplegtDYN
cat("1. Running DIDmultiplegtDYN...\n")
res_cran_100x <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers_100x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 13,
    placebo = 13,
    weight = "stpop"
  )
}))
cat("   Time:", ifelse(res_cran_100x$status == "completed",
                       paste(round(res_cran_100x$time, 2), "seconds"),
                       res_cran_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "DIDmultiplegtDYN",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_cran_100x$status == "completed", res_cran_100x$time, NA),
  status = res_cran_100x$status
))

# 2. did (Callaway-Sant'Anna)
cat("2. Running did (Callaway-Sant'Anna)...\n")
res_cs_100x <- run_with_timeout(quote({
  out <- att_gt(
    yname = "div_rate",
    tname = "year",
    idname = "state",
    gname = "cohort",
    data = wolfers_100x,
    weightsname = "stpop",
    est_method = "dr",
    base_period = "universal"
  )
  aggte(out, type = "dynamic", min_e = -13, max_e = 13)
}))
cat("   Time:", ifelse(res_cs_100x$status == "completed",
                       paste(round(res_cs_100x$time, 2), "seconds"),
                       res_cs_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "did-CS",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_cs_100x$status == "completed", res_cs_100x$time, NA),
  status = res_cs_100x$status
))

# 3. didimputation
cat("3. Running didimputation...\n")
res_didimp_100x <- run_with_timeout(quote({
  did_imputation(
    data = wolfers_100x,
    yname = "div_rate",
    gname = "cohort",
    tname = "year",
    idname = "state",
    wname = "stpop",
    horizon = c(1:13),
    pretrends = c(-13:-1)
  )
}))
cat("   Time:", ifelse(res_didimp_100x$status == "completed",
                       paste(round(res_didimp_100x$time, 2), "seconds"),
                       res_didimp_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "didimputation",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_didimp_100x$status == "completed", res_didimp_100x$time, NA),
  status = res_didimp_100x$status
))

# 4. fixest (Sun-Abraham)
cat("4. Running fixest (Sun-Abraham)...\n")
res_sa_100x <- run_with_timeout(quote({
  feols(
    div_rate ~ sunab(cohort_sa, event_time_binned, ref.p = 0) | state + year,
    data = wolfers_100x,
    weights = ~stpop,
    vcov = ~state
  )
}))
cat("   Time:", ifelse(res_sa_100x$status == "completed",
                       paste(round(res_sa_100x$time, 2), "seconds"),
                       res_sa_100x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "100x (168K)",
  package = "fixest-SA",
  rows = nrow(wolfers_100x),
  time_seconds = ifelse(res_sa_100x$status == "completed", res_sa_100x$time, NA),
  status = res_sa_100x$status
))

# Clean up
rm(wolfers_100x)
gc()

# ============================================================
# SCENARIO 3: Synthetic Data 1000x (1,683,000 rows)
# ============================================================
cat("\n", sep_line(), "\n")
cat("SCENARIO 3: Synthetic Data 1000x\n")
cat(sep_line(), "\n\n")

wolfers_1000x <- create_synthetic_data(wolfers, 1000)
cat("Synthetic data rows:", nrow(wolfers_1000x), "\n\n")

# 1. DIDmultiplegtDYN
cat("1. Running DIDmultiplegtDYN...\n")
res_cran_1000x <- run_with_timeout(quote({
  DIDmultiplegtDYN::did_multiplegt_dyn(
    df = wolfers_1000x,
    outcome = "div_rate",
    group = "state",
    time = "year",
    treatment = "udl",
    effects = 13,
    placebo = 13,
    weight = "stpop"
  )
}))
cat("   Time:", ifelse(res_cran_1000x$status == "completed",
                       paste(round(res_cran_1000x$time, 2), "seconds"),
                       res_cran_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "DIDmultiplegtDYN",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_cran_1000x$status == "completed", res_cran_1000x$time, NA),
  status = res_cran_1000x$status
))

# 2. did (Callaway-Sant'Anna)
cat("2. Running did (Callaway-Sant'Anna)...\n")
res_cs_1000x <- run_with_timeout(quote({
  out <- att_gt(
    yname = "div_rate",
    tname = "year",
    idname = "state",
    gname = "cohort",
    data = wolfers_1000x,
    weightsname = "stpop",
    est_method = "dr",
    base_period = "universal"
  )
  aggte(out, type = "dynamic", min_e = -13, max_e = 13)
}))
cat("   Time:", ifelse(res_cs_1000x$status == "completed",
                       paste(round(res_cs_1000x$time, 2), "seconds"),
                       res_cs_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "did-CS",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_cs_1000x$status == "completed", res_cs_1000x$time, NA),
  status = res_cs_1000x$status
))

# 3. didimputation
cat("3. Running didimputation...\n")
res_didimp_1000x <- run_with_timeout(quote({
  did_imputation(
    data = wolfers_1000x,
    yname = "div_rate",
    gname = "cohort",
    tname = "year",
    idname = "state",
    wname = "stpop",
    horizon = c(1:13),
    pretrends = c(-13:-1)
  )
}))
cat("   Time:", ifelse(res_didimp_1000x$status == "completed",
                       paste(round(res_didimp_1000x$time, 2), "seconds"),
                       res_didimp_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "didimputation",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_didimp_1000x$status == "completed", res_didimp_1000x$time, NA),
  status = res_didimp_1000x$status
))

# 4. fixest (Sun-Abraham)
cat("4. Running fixest (Sun-Abraham)...\n")
res_sa_1000x <- run_with_timeout(quote({
  feols(
    div_rate ~ sunab(cohort_sa, event_time_binned, ref.p = 0) | state + year,
    data = wolfers_1000x,
    weights = ~stpop,
    vcov = ~state
  )
}))
cat("   Time:", ifelse(res_sa_1000x$status == "completed",
                       paste(round(res_sa_1000x$time, 2), "seconds"),
                       res_sa_1000x$status), "\n")
results <- rbind(results, data.frame(
  scenario = "1000x (1.68M)",
  package = "fixest-SA",
  rows = nrow(wolfers_1000x),
  time_seconds = ifelse(res_sa_1000x$status == "completed", res_sa_1000x$time, NA),
  status = res_sa_1000x$status
))

# Clean up
rm(wolfers_1000x)
gc()

# ============================================================
# SUMMARY
# ============================================================
cat("\n", sep_line(), "\n")
cat("SUMMARY OF RESULTS\n")
cat(sep_line(), "\n\n")

print(results)

# Create pivot table for easier comparison
cat("\n\nPIVOT TABLE (Time in seconds):\n")
cat(sep_line(), "\n\n")

pivot_results <- reshape(results[, c("scenario", "package", "time_seconds")],
                         idvar = "package",
                         timevar = "scenario",
                         direction = "wide")
names(pivot_results) <- gsub("time_seconds.", "", names(pivot_results))
print(pivot_results)

# Save results to CSV
write.csv(results, "runtime_R.csv", row.names = FALSE)

cat("\n\nBenchmark completed at:", as.character(Sys.time()), "\n")
sink()

cat("Log saved to:", log_file, "\n")
cat("Results saved to: runtime_R.csv\n")
