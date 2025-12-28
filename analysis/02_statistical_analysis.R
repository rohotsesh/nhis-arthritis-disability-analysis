# NHIS Arthritis and Disability Analysis
# Statistical Analysis Script
# Purpose: Perform survey-weighted analyses of arthritis-disability relationship

# Load required packages
library(tidyverse)
library(survey)
library(broom)
library(ggplot2)
library(ggpubr)

# Set paths
processed_data_dir <- "data/processed"
output_dir <- "outputs/tables"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# STEP 1: Load prepared data
# ------------------------------------------------------------------------------
nhis_data <- readRDS(file.path(processed_data_dir, "nhis_analysis_dataset.rds"))
nhis_design <- readRDS(file.path(processed_data_dir, "nhis_survey_design.rds"))

# Check data structure
cat("Data dimensions:", dim(nhis_data), "\n")
cat("Years included:", unique(nhis_data$YEAR), "\n")

# ------------------------------------------------------------------------------
# STEP 2: Descriptive statistics
# ------------------------------------------------------------------------------
# Overall prevalence of arthritis and disability by year
prev_by_year <- svyby(~ arthritis + disability, ~ YEAR, nhis_design, svymean, na.rm = TRUE)
print("Prevalence by year:")
print(prev_by_year)

# Save prevalence table
write_csv(prev_by_year, file.path(output_dir, "prevalence_by_year.csv"))

# Prevalence by demographic subgroups
prev_by_age <- svyby(~ arthritis + disability, ~ age_group, nhis_design, svymean, na.rm = TRUE)
prev_by_sex <- svyby(~ arthritis + disability, ~ sex, nhis_design, svymean, na.rm = TRUE)
prev_by_race <- svyby(~ arthritis + disability, ~ race_ethnicity, nhis_design, svymean, na.rm = TRUE)

# Combine subgroup tables
subgroup_tables <- list(
  age_group = prev_by_age,
  sex = prev_by_sex,
  race_ethnicity = prev_by_race
)

# Save subgroup tables
for (name in names(subgroup_tables)) {
  write_csv(subgroup_tables[[name]], 
            file.path(output_dir, sprintf("prevalence_by_%s.csv", name)))
}

# ------------------------------------------------------------------------------
# STEP 3: Trend analysis (Joinpoint regression would require NCI software)
# ------------------------------------------------------------------------------
# Linear trend test for arthritis prevalence over time
arthritis_trend <- svyglm(arthritis ~ YEAR, design = nhis_design, family = quasibinomial())
disability_trend <- svyglm(disability ~ YEAR, design = nhis_design, family = quasibinomial())

# Extract trend coefficients
trend_results <- data.frame(
  outcome = c("arthritis", "disability"),
  beta = c(coef(arthritis_trend)["YEAR"], coef(disability_trend)["YEAR"]),
  se = c(SE(arthritis_trend)["YEAR"], SE(disability_trend)["YEAR"]),
  p_value = c(summary(arthritis_trend)$coefficients["YEAR", "Pr(>|t|)"],
              summary(disability_trend)$coefficients["YEAR", "Pr(>|t|)"])
)

print("Trend analysis results:")
print(trend_results)
write_csv(trend_results, file.path(output_dir, "trend_analysis.csv"))

# Annual percentage change (APC) approximation
apc_arthritis <- exp(coef(arthritis_trend)["YEAR"]) - 1
apc_disability <- exp(coef(disability_trend)["YEAR"]) - 1

cat(sprintf("\nApproximate Annual Percentage Change (APC):\n"))
cat(sprintf("Arthritis: %.2f%%\n", apc_arthritis * 100))
cat(sprintf("Disability: %.2f%%\n", apc_disability * 100))

# ------------------------------------------------------------------------------
# STEP 4: Association between arthritis and disability
# ------------------------------------------------------------------------------
# Crude association (unadjusted)
crude_model <- svyglm(disability ~ arthritis, design = nhis_design, family = quasibinomial())
crude_summary <- tidy(crude_model, conf.int = TRUE, exponentiate = TRUE)

print("Crude association (arthritis -> disability):")
print(crude_summary)

# Adjusted model (multivariable)
adjusted_model <- svyglm(
  disability ~ arthritis + age_group + sex + race_ethnicity + education + poverty,
  design = nhis_design,
  family = quasibinomial()
)

adjusted_summary <- tidy(adjusted_model, conf.int = TRUE, exponentiate = TRUE)

print("Adjusted association (arthritis -> disability, controlling for demographics):")
print(adjusted_summary)

# Save model results
model_results <- list(
  crude = crude_summary,
  adjusted = adjusted_summary
)

saveRDS(model_results, file.path(output_dir, "regression_models.rds"))

# Write to CSV for easier viewing
write_csv(crude_summary, file.path(output_dir, "crude_association.csv"))
write_csv(adjusted_summary, file.path(output_dir, "adjusted_association.csv"))

# ------------------------------------------------------------------------------
# STEP 5: Stratified analyses
# ------------------------------------------------------------------------------
# Effect modification by age group
stratified_by_age <- by(nhis_data, nhis_data$age_group, function(df) {
  design_sub <- subset(nhis_design, age_group == unique(df$age_group))
  if (nrow(design_sub) > 0) {
    model <- svyglm(disability ~ arthritis, design = design_sub, family = quasibinomial())
    tidy(model, conf.int = TRUE, exponentiate = TRUE) %>%
      mutate(age_group = unique(df$age_group))
  }
})

age_stratified_results <- bind_rows(stratified_by_age)
print("Stratified analysis by age group:")
print(age_stratified_results)

# Effect modification by sex
stratified_by_sex <- by(nhis_data, nhis_data$sex, function(df) {
  design_sub <- subset(nhis_design, sex == unique(df$sex))
  if (nrow(design_sub) > 0) {
    model <- svyglm(disability ~ arthritis, design = design_sub, family = quasibinomial())
    tidy(model, conf.int = TRUE, exponentiate = TRUE) %>%
      mutate(sex = unique(df$sex))
  }
})

sex_stratified_results <- bind_rows(stratified_by_sex)
print("Stratified analysis by sex:")
print(sex_stratified_results)

# Save stratified results
write_csv(age_stratified_results, file.path(output_dir, "stratified_by_age.csv"))
write_csv(sex_stratified_results, file.path(output_dir, "stratified_by_sex.csv"))

# ------------------------------------------------------------------------------
# STEP 6: Population attributable fraction (PAF)
# ------------------------------------------------------------------------------
# Calculate PAF for arthritis on disability
# PAF = (prevalence of exposure * (RR - 1)) / (1 + prevalence of exposure * (RR - 1))

# Get prevalence of arthritis
arthritis_prev <- svymean(~ arthritis, nhis_design, na.rm = TRUE)[1]

# Use adjusted relative risk (approximated by odds ratio since outcome is not rare)
# Note: For common outcomes, odds ratio overestimates relative risk
adj_or <- exp(coef(adjusted_model)["arthritis"])

# Convert OR to RR using formula: RR = OR / ((1 - P0) + (P0 * OR))
# where P0 is disability prevalence among unexposed
# Simplified approximation for PAF using OR (may be biased)
paf <- (arthritis_prev * (adj_or - 1)) / (arthritis_prev * (adj_or - 1) + 1)

cat(sprintf("\nPopulation Attributable Fraction (PAF) for arthritis on disability:\n"))
cat(sprintf("Arthritis prevalence: %.1f%%\n", arthritis_prev * 100))
cat(sprintf("Adjusted OR: %.2f\n", adj_or))
cat(sprintf("Approximate PAF: %.1f%%\n", paf * 100))

# Save PAF results
paf_results <- data.frame(
  arthritis_prevalence = arthritis_prev,
  adjusted_or = adj_or,
  paf = paf
)
write_csv(paf_results, file.path(output_dir, "population_attributable_fraction.csv"))

# ------------------------------------------------------------------------------
# STEP 7: Sensitivity analyses
# ------------------------------------------------------------------------------
# 1. Complete case analysis (already done)
# 2. Alternative disability definition (ADL only)
sensitivity_adl <- svyglm(
  adl_limitation ~ arthritis + age_group + sex + race_ethnicity + education + poverty,
  design = nhis_design,
  family = quasibinomial()
)

# 3. Alternative disability definition (IADL only)
sensitivity_iadl <- svyglm(
  iadl_limitation ~ arthritis + age_group + sex + race_ethnicity + education + poverty,
  design = nhis_design,
  family = quasibinomial()
)

# Compare results
sensitivity_results <- data.frame(
  model = c("Main (any disability)", "ADL only", "IADL only"),
  or_arthritis = c(exp(coef(adjusted_model)["arthritis"]),
                   exp(coef(sensitivity_adl)["arthritis"]),
                   exp(coef(sensitivity_iadl)["arthritis"])),
  p_value = c(summary(adjusted_model)$coefficients["arthritis", "Pr(>|t|)"],
              summary(sensitivity_adl)$coefficients["arthritis", "Pr(>|t|)"],
              summary(sensitivity_iadl)$coefficients["arthritis", "Pr(>|t|)"])
)

print("Sensitivity analysis results:")
print(sensitivity_results)
write_csv(sensitivity_results, file.path(output_dir, "sensitivity_analysis.csv"))

# ------------------------------------------------------------------------------
# STEP 8: Generate analysis summary report
# ------------------------------------------------------------------------------
sink(file.path(output_dir, "statistical_analysis_summary.txt"))
cat("NHIS Arthritis and Disability Statistical Analysis Summary\n")
cat("==========================================================\n\n")
cat(sprintf("Sample size: %d adults aged 65+\n", nrow(nhis_data)))
cat(sprintf("Years: %d-%d\n", min(nhis_data$YEAR), max(nhis_data$YEAR)))
cat("\n--- Prevalence Estimates ---\n")
print(prev_by_year)
cat("\n--- Trend Analysis ---\n")
print(trend_results)
cat("\n--- Association Analysis ---\n")
cat("Crude OR (arthritis -> disability):\n")
print(crude_summary %>% filter(term == "arthritis"))
cat("\nAdjusted OR (arthritis -> disability):\n")
print(adjusted_summary %>% filter(term == "arthritis"))
cat("\n--- Stratified Analyses ---\n")
cat("By age group:\n")
print(age_stratified_results %>% filter(term == "arthritis"))
cat("\nBy sex:\n")
print(sex_stratified_results %>% filter(term == "arthritis"))
cat("\n--- Population Attributable Fraction ---\n")
cat(sprintf("PAF: %.1f%%\n", paf * 100))
cat("\n--- Sensitivity Analyses ---\n")
print(sensitivity_results)
sink()

cat("\nStatistical analysis complete. Results saved to", output_dir, "\n")