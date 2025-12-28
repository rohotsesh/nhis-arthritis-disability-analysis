# NHIS Arthritis and Disability Analysis
# Environment setup script
# Purpose: Install and load required R packages

# List of required packages
required_packages <- c(
  # Data manipulation
  "tidyverse",      # dplyr, ggplot2, tidyr, readr, purrr, etc.
  "haven",          # Read SAS/SPSS/Stata files
  "readxl",         # Read Excel files
  "data.table",     # Fast data manipulation
  
  # Survey analysis
  "survey",         # Survey-weighted statistics
  "srvyr",          # Tidyverse interface for survey
  "jtools",         # Regression table formatting
  
  # Statistical modeling
  "broom",          # Tidy model outputs
  "broom.mixed",    # Tidy mixed model outputs
  "lmtest",         # Hypothesis testing
  "sandwich",       # Robust standard errors
  
  # Visualization
  "ggplot2",        # Grammar of graphics
  "ggpubr",         # Publication-ready plots
  "patchwork",      # Combine ggplot2 plots
  "RColorBrewer",   # Color palettes
  "viridis",        # Colorblind-friendly palettes
  "scales",         # Scale functions for graphics
  
  # Reporting
  "knitr",          # Dynamic report generation
  "rmarkdown",      # R Markdown documents
  "kableExtra",     # Enhanced table formatting
  
  # Project management
  "here",           # Path management
  "renv"            # Reproducible environments
)

# Function to install missing packages
install_missing <- function(packages) {
  installed <- packages %in% installed.packages()
  if (any(!installed)) {
    cat("Installing missing packages:", packages[!installed], "\n")
    install.packages(packages[!installed], dependencies = TRUE, repos = "https://cloud.r-project.org")
  } else {
    cat("All required packages are already installed.\n")
  }
}

# Install missing packages
install_missing(required_packages)

# Load packages (optional - you can load them in individual scripts)
# lapply(required_packages, library, character.only = TRUE)

# Set global options
options(
  stringsAsFactors = FALSE,   # Don't convert strings to factors
  scipen = 999,              # Disable scientific notation
  digits = 4,                # Number of digits to display
  tibble.width = Inf,        # Show all columns in tibble
  knitr.kable.NA = ""        # Display NA as empty string in kable
)

# Print session info for reproducibility
cat("\n========================================\n")
cat("Environment Setup Complete\n")
cat("========================================\n")
cat("R version:", R.version$version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("Packages installed:", length(required_packages), "\n")
cat("\nTo load all packages, run:\n")
cat("  lapply(c(", paste0('"', required_packages, '"', collapse = ", "), "), library, character.only = TRUE)\n")
cat("\nFor project reproducibility, consider using renv:\n")
cat("  renv::init()     # Initialize renv project\n")
cat("  renv::snapshot() # Capture package versions\n")
cat("========================================\n")