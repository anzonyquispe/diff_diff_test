# DiD Package Comparison - R Package Installation Script
# Run with: Rscript install_r_packages.R
# Or source in R: source("install_r_packages.R")

cat("==============================================\n")
cat("Installing R packages for DiD comparison\n")
cat("==============================================\n\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Function to install if not present
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, dependencies = TRUE)
  } else {
    cat(paste(pkg, "already installed\n"))
  }
}

# Core DiD packages
cat("\n--- Installing DiD packages ---\n")
install_if_missing("did")
install_if_missing("fixest")
install_if_missing("DIDmultiplegtDYN")
install_if_missing("didimputation")

# Dependencies for doubly-robust estimation
cat("\n--- Installing DR dependencies ---\n")
install_if_missing("DRDID")

# Python integration (required for Quarto with Python chunks)
cat("\n--- Installing Python integration ---\n")
install_if_missing("reticulate")

# Data manipulation and visualization
cat("\n--- Installing data/viz packages ---\n")
install_if_missing("dplyr")
install_if_missing("ggplot2")
install_if_missing("tidyr")

# Reporting
cat("\n--- Installing reporting packages ---\n")
install_if_missing("knitr")
install_if_missing("rmarkdown")

# Optional: for better fixest plots
install_if_missing("ggfixest")

# Verify installations
cat("\n==============================================\n")
cat("Verifying installations...\n")
cat("==============================================\n\n")

packages <- c("did", "fixest", "DIDmultiplegtDYN", "didimputation",
              "DRDID", "dplyr", "ggplot2", "knitr")

all_ok <- TRUE
for (pkg in packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    version <- as.character(packageVersion(pkg))
    cat(paste("✓", pkg, "version", version, "\n"))
  } else {
    cat(paste("✗", pkg, "FAILED to install\n"))
    all_ok <- FALSE
  }
}

cat("\n")
if (all_ok) {
  cat("All packages installed successfully!\n")
} else {
  cat("Some packages failed to install. Check errors above.\n")
}

# Print session info for reproducibility
cat("\n==============================================\n")
cat("Session Info\n")
cat("==============================================\n")
print(sessionInfo())
