# NHIS Arthritis and Disability Analysis
# Data Preparation Script
# Purpose: Download, clean, and prepare NHIS data for analysis

# Load required packages
library(tidyverse)
library(haven)
library(survey)
library(ipumsr)

# Set paths
raw_data_dir <- "data/raw"
processed_data_dir <- "data/processed"
dir.create(raw_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_data_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# STEP 1: Download NHIS data (manual step - instructions)
# ------------------------------------------------------------------------------
# NHIS data must be downloaded manually from:
# 1. CDC/NCHS: https://www.cdc.gov/nchs/nhis/data-questionnaires-documentation.htm
# 2. IPUMS NHIS: https://nhis.ipums.org/nhis/
#
# Place downloaded files in `data/raw/` with naming convention:
# - nhis_1997_personsx.sas7bdat
# - nhis_1998_personsx.sas7bdat
# - etc.

# ------------------------------------------------------------------------------
# STEP 2: Load and combine annual files
# ------------------------------------------------------------------------------
# Function to load a single NHIS year
load_nhis_year <- function(year) {
  file_path <- file.path(raw_data_dir, sprintf("nhis_%d_personsx.sas7bdat", year))
  
  if (!file.exists(file_path)) {
    warning(sprintf("File for year %d not found at %s", year, file_path))
    return(NULL)
  }
  
  # Read SAS file
  df <- read_sas(file_path)
  
  # Add year variable
  df$YEAR <- year
  
  # Select variables of interest
  vars_to_keep <- c(
    # Identifiers
    "HHX", "FMX", "FPX",
    # Demographics
    "AGE_P", "SEX", "RACERPI", "HISPAN", "RACEREC", 
    "EDUC", "INCFAM", "POVRAT",
    # Arthritis
    "ARTHDX", "ARTHTYPE", "ARTHPAIN",
    # Disability measures
    "ADLHELP", "ADLHAVE", "IADLHELP", "IADLHAVE",
    "AIDHELP", "AIDHAVE", "EQUIPHELP", "EQUIPHAVE",
    # Survey weights
    "WTFA", "WTFA_SA"
  )
  
  # Keep only variables that exist in this year's file
  existing_vars <- intersect(vars_to_keep, names(df))
  df <- df[, c("YEAR", existing_vars)]
  
  return(df)
}

# Load data for years 1997-2022
years <- 1997:2022
nhis_list <- lapply(years, load_nhis_year)

# Remove NULL entries (years without data)
nhis_list <- nhis_list[!sapply(nhis_list, is.null)]

# Combine into single dataframe
nhis_combined <- bind_rows(nhis_list)

# ------------------------------------------------------------------------------
# STEP 3: Clean and recode variables
# ------------------------------------------------------------------------------
# Create analysis dataset for adults aged 65+
nhis_analysis <- nhis_combined %>%
  filter(AGE_P >= 65) %>%
  mutate(
    # Arthritis diagnosis (binary)
    arthritis = case_when(
      ARTHDX == 1 ~ 1,  # Yes
      ARTHDX == 2 ~ 0,  # No
      TRUE ~ NA_real_
    ),
    
    # Any ADL limitation
    adl_limitation = case_when(
      ADLHELP == 1 | ADLHAVE == 1 ~ 1,
      ADLHELP == 2 & ADLHAVE == 2 ~ 0,
      TRUE ~ NA_real_
    ),
    
    # Any IADL limitation
    iadl_limitation = case_when(
      IADLHELP == 1 | IADLHAVE == 1 ~ 1,
      IADLHELP == 2 & IADLHAVE == 2 ~ 0,
      TRUE ~ NA_real_
    ),
    
    # Any disability (ADL or IADL)
    disability = ifelse(adl_limitation == 1 | iadl_limitation == 1, 1, 0),
    
    # Demographic factors
    age_group = cut(AGE_P, 
                    breaks = c(65, 74, 84, Inf),
                    labels = c("65-74", "75-84", "85+"),
                    right = FALSE),
    
    sex = factor(SEX, levels = 1:2, labels = c("Male", "Female")),
    
    race_ethnicity = case_when(
      HISPAN %in% 1:12 ~ "Hispanic",
      RACEREC == 1 ~ "Non-Hispanic White",
      RACEREC == 2 ~ "Non-Hispanic Black",
      RACEREC == 3 ~ "Non-Hispanic Other",
      TRUE ~ "Unknown"
    ),
    
    education = case_when(
      EDUC <= 12 ~ "Less than high school",
      EDUC == 13 ~ "High school graduate",
      EDUC >= 14 & EDUC <= 15 ~ "Some college",
      EDUC >= 16 ~ "College graduate",
      TRUE ~ "Unknown"
    ),
    
    poverty = case_when(
      POVRAT < 1 ~ "Below poverty",
      POVRAT >= 1 & POVRAT < 2 ~ "Near poverty (1-1.99)",
      POVRAT >= 2 ~ "At or above 2x poverty",
      TRUE ~ "Unknown"
    ),
    
    # Survey weight normalization
    weight = WTFA / mean(WTFA, na.rm = TRUE)
  )

# ------------------------------------------------------------------------------
# STEP 4: Handle missing data
# ------------------------------------------------------------------------------
# Count missing values
missing_summary <- sapply(nhis_analysis, function(x) sum(is.na(x)))
print("Missing value counts:")
print(missing_summary)

# For analysis, we'll create a complete case dataset
# (alternative: multiple imputation could be implemented)
nhis_complete <- nhis_analysis %>%
  filter(!is.na(arthritis) & !is.na(disability) & !is.na(weight))

# ------------------------------------------------------------------------------
# STEP 5: Create survey design object
# ------------------------------------------------------------------------------
# NHIS uses complex survey design with stratification and clustering
# Note: Actual design variables vary by year; simplified approach here
nhis_design <- svydesign(
  id = ~1,  # Simplified - would need actual cluster variable
  strata = ~YEAR,  # Simplified - would need actual stratum variable
  weights = ~weight,
  data = nhis_complete,
  nest = TRUE
)

# ------------------------------------------------------------------------------
# STEP 6: Save processed data
# ------------------------------------------------------------------------------
saveRDS(nhis_complete, file.path(processed_data_dir, "nhis_analysis_dataset.rds"))
saveRDS(nhis_design, file.path(processed_data_dir, "nhis_survey_design.rds"))

# Also save as CSV for non-R users
write_csv(nhis_complete, file.path(processed_data_dir, "nhis_analysis_dataset.csv"))

# ------------------------------------------------------------------------------
# STEP 7: Create data summary report
# ------------------------------------------------------------------------------
sink(file.path(processed_data_dir, "data_preparation_summary.txt"))
cat("NHIS Arthritis and Disability Data Preparation Summary\n")
cat("=====================================================\n\n")
cat(sprintf("Total observations (65+): %d\n", nrow(nhis_analysis)))
cat(sprintf("Complete cases: %d\n", nrow(nhis_complete)))
cat(sprintf("Years included: %s\n", paste(unique(nhis_complete$YEAR), collapse = ", ")))
cat("\nArthritis prevalence:\n")
print(prop.table(table(nhis_complete$arthritis)) * 100)
cat("\nDisability prevalence:\n")
print(prop.table(table(nhis_complete$disability)) * 100)
cat("\nDemographic distribution:\n")
print(summary(nhis_complete[, c("age_group", "sex", "race_ethnicity", "education")]))
sink()

cat("Data preparation complete. Processed data saved to", processed_data_dir, "\n")