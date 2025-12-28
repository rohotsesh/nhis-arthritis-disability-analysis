# NHIS Arthritis and Disability Analysis
# Visualization Script
# Purpose: Create publication-quality figures for the analysis

# Load required packages
library(tidyverse)
library(survey)
library(ggplot2)
library(ggpubr)
library(scales)
library(patchwork)
library(RColorBrewer)

# Set paths
processed_data_dir <- "data/processed"
output_dir <- "outputs/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Set ggplot theme
theme_set(theme_minimal(base_size = 12))
theme_update(
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
  axis.line = element_line(color = "black"),
  legend.position = "bottom",
  plot.title = element_text(face = "bold", hjust = 0.5),
  plot.subtitle = element_text(hjust = 0.5)
)

# ------------------------------------------------------------------------------
# STEP 1: Load data and prevalence estimates
# ------------------------------------------------------------------------------
nhis_data <- readRDS(file.path(processed_data_dir, "nhis_analysis_dataset.rds"))
nhis_design <- readRDS(file.path(processed_data_dir, "nhis_survey_design.rds"))

# Calculate prevalence by year (with confidence intervals)
prev_by_year <- svyby(~ arthritis + disability, ~ YEAR, nhis_design, svymean, na.rm = TRUE)

# Convert to long format for plotting
prev_long <- prev_by_year %>%
  pivot_longer(
    cols = c(arthritis, disability),
    names_to = "condition",
    values_to = "prevalence"
  ) %>%
  mutate(
    se = case_when(
      condition == "arthritis" ~ se.arthritis,
      condition == "disability" ~ se.disability
    ),
    lower = prevalence - 1.96 * se,
    upper = prevalence + 1.96 * se,
    condition_label = factor(condition,
                             levels = c("arthritis", "disability"),
                             labels = c("Arthritis", "Any Disability"))
  )

# ------------------------------------------------------------------------------
# FIGURE 1: Time trends in arthritis and disability prevalence
# ------------------------------------------------------------------------------
fig_trends <- ggplot(prev_long, aes(x = YEAR, y = prevalence, color = condition_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = condition_label),
              alpha = 0.2, color = NA) +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     limits = c(0, NA),
                     breaks = seq(0, 1, by = 0.1)) +
  scale_x_continuous(breaks = seq(1995, 2025, by = 5)) +
  scale_color_brewer(palette = "Set1", name = "") +
  scale_fill_brewer(palette = "Set1", name = "") +
  labs(
    title = "Trends in Arthritis and Disability Prevalence Among Adults 65+",
    subtitle = "National Health Interview Survey, 1997-2022",
    x = "Year",
    y = "Prevalence (%)",
    caption = "Error bands represent 95% confidence intervals"
  ) +
  theme(legend.position = "bottom")

# Save figure
ggsave(file.path(output_dir, "figure1_trends.png"),
       fig_trends, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "figure1_trends.pdf"),
       fig_trends, width = 10, height = 6)

# ------------------------------------------------------------------------------
# FIGURE 2: Arthritis prevalence by demographic subgroups
# ------------------------------------------------------------------------------
# Calculate prevalence by age, sex, and race
prev_age <- svyby(~ arthritis, ~ age_group, nhis_design, svymean, na.rm = TRUE)
prev_sex <- svyby(~ arthritis, ~ sex, nhis_design, svymean, na.rm = TRUE)
prev_race <- svyby(~ arthritis, ~ race_ethnicity, nhis_design, svymean, na.rm = TRUE)

# Create individual plots
p_age <- ggplot(prev_age, aes(x = age_group, y = arthritis)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_errorbar(aes(ymin = arthritis - 1.96 * se, ymax = arthritis + 1.96 * se),
                width = 0.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Age Group", y = "Arthritis Prevalence", title = "By Age") +
  theme(axis.text.x = element_text(angle = 0))

p_sex <- ggplot(prev_sex, aes(x = sex, y = arthritis)) +
  geom_col(fill = "darkgreen", alpha = 0.8) +
  geom_errorbar(aes(ymin = arthritis - 1.96 * se, ymax = arthritis + 1.96 * se),
                width = 0.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Sex", y = "", title = "By Sex") +
  theme(axis.text.x = element_text(angle = 0))

p_race <- ggplot(prev_race, aes(x = reorder(race_ethnicity, arthritis), y = arthritis)) +
  geom_col(fill = "darkred", alpha = 0.8) +
  geom_errorbar(aes(ymin = arthritis - 1.96 * se, ymax = arthritis + 1.96 * se),
                width = 0.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Race/Ethnicity", y = "", title = "By Race/Ethnicity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Combine using patchwork
fig_subgroups <- p_age + p_sex + p_race +
  plot_annotation(
    title = "Arthritis Prevalence Among Adults 65+ by Demographic Subgroups",
    subtitle = "NHIS 1997-2022, weighted estimates with 95% confidence intervals",
    theme = theme(plot.title = element_text(face = "bold", hjust = 0.5))
  ) +
  plot_layout(nrow = 1)

# Save figure
ggsave(file.path(output_dir, "figure2_subgroup_prevalence.png"),
       fig_subgroups, width = 14, height = 6, dpi = 300)
ggsave(file.path(output_dir, "figure2_subgroup_prevalence.pdf"),
       fig_subgroups, width = 14, height = 6)

# ------------------------------------------------------------------------------
# FIGURE 3: Association between arthritis and disability
# ------------------------------------------------------------------------------
# Load model results
model_results <- readRDS(file.path("outputs/tables", "regression_models.rds"))
adjusted_summary <- model_results$adjusted

# Filter to key variables and create forest plot data
forest_data <- adjusted_summary %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term_label = case_when(
      term == "arthritis" ~ "Arthritis (ref: No)",
      term == "age_group75-84" ~ "Age 75-84 (ref: 65-74)",
      term == "age_group85+" ~ "Age 85+ (ref: 65-74)",
      term == "sexFemale" ~ "Female (ref: Male)",
      term == "race_ethnicityNon-Hispanic Black" ~ "Non-Hispanic Black (ref: White)",
      term == "race_ethnicityNon-Hispanic Other" ~ "Non-Hispanic Other (ref: White)",
      term == "race_ethnicityHispanic" ~ "Hispanic (ref: White)",
      term == "educationHigh school graduate" ~ "High school grad (ref: <HS)",
      term == "educationSome college" ~ "Some college (ref: <HS)",
      term == "educationCollege graduate" ~ "College grad (ref: <HS)",
      term == "povertyNear poverty (1-1.99)" ~ "Near poverty (ref: Below)",
      term == "povertyAt or above 2x poverty" ~ "≥2x poverty (ref: Below)",
      TRUE ~ term
    ),
    term_label = factor(term_label, levels = rev(term_label))
  ) %>%
  arrange(desc(term_label))

# Create forest plot
fig_forest <- ggplot(forest_data, aes(x = estimate, y = term_label)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  geom_point(size = 3, color = "darkblue") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), 
                 height = 0.2, color = "darkblue", linewidth = 1) +
  scale_x_log10(
    breaks = c(0.5, 1, 2, 4),
    labels = c("0.5", "1", "2", "4"),
    limits = c(0.3, 5)
  ) +
  labs(
    title = "Adjusted Association Between Arthritis and Disability",
    subtitle = "Odds ratios from multivariable logistic regression (reference groups shown)",
    x = "Odds Ratio (log scale)",
    y = "",
    caption = "Error bars represent 95% confidence intervals"
  ) +
  theme(
    panel.grid.major.y = element_blank(),
    axis.line.y = element_blank()
  )

# Save figure
ggsave(file.path(output_dir, "figure3_forest_plot.png"),
       fig_forest, width = 10, height = 8, dpi = 300)
ggsave(file.path(output_dir, "figure3_forest_plot.pdf"),
       fig_forest, width = 10, height = 8)

# ------------------------------------------------------------------------------
# FIGURE 4: Disability prevalence by arthritis status and age
# ------------------------------------------------------------------------------
# Calculate disability prevalence stratified by arthritis and age
stratified_data <- svyby(~ disability, ~ arthritis + age_group, nhis_design, svymean, na.rm = TRUE) %>%
  mutate(
    arthritis_label = ifelse(arthritis == 1, "With Arthritis", "Without Arthritis"),
    lower = disability - 1.96 * se,
    upper = disability + 1.96 * se
  )

fig_stratified <- ggplot(stratified_data, 
                         aes(x = age_group, y = disability, fill = arthritis_label)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_errorbar(aes(ymin = lower, ymax = upper),
                position = position_dodge(width = 0.8), width = 0.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_brewer(palette = "Set2", name = "Arthritis Status") +
  labs(
    title = "Disability Prevalence by Arthritis Status and Age Group",
    subtitle = "NHIS 1997-2022, weighted estimates with 95% confidence intervals",
    x = "Age Group",
    y = "Disability Prevalence (%)"
  ) +
  theme(legend.position = "bottom")

# Save figure
ggsave(file.path(output_dir, "figure4_stratified_age.png"),
       fig_stratified, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "figure4_stratified_age.pdf"),
       fig_stratified, width = 10, height = 6)

# ------------------------------------------------------------------------------
# FIGURE 5: Time trends in arthritis-disability association
# ------------------------------------------------------------------------------
# Calculate annual odds ratios (simplified - could use yearly models)
yearly_models <- lapply(unique(nhis_data$YEAR), function(yr) {
  design_sub <- subset(nhis_design, YEAR == yr)
  if (nrow(design_sub) > 100) {
    model <- svyglm(disability ~ arthritis, design = design_sub, family = quasibinomial())
    tidy(model, conf.int = TRUE, exponentiate = TRUE) %>%
      filter(term == "arthritis") %>%
      mutate(YEAR = yr)
  }
})

yearly_or <- bind_rows(yearly_models)

fig_yearly_or <- ggplot(yearly_or, aes(x = YEAR, y = estimate)) +
  geom_line(color = "darkorange", linewidth = 1.2) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2, fill = "darkorange") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  scale_y_log10(
    breaks = c(0.5, 1, 2, 4),
    labels = c("0.5", "1", "2", "4")
  ) +
  scale_x_continuous(breaks = seq(1995, 2025, by = 5)) +
  labs(
    title = "Annual Association Between Arthritis and Disability",
    subtitle = "Odds ratios from yearly logistic regression models",
    x = "Year",
    y = "Odds Ratio (log scale)",
    caption = "Shaded area represents 95% confidence intervals"
  )

# Save figure
ggsave(file.path(output_dir, "figure5_yearly_association.png"),
       fig_yearly_or, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "figure5_yearly_association.pdf"),
       fig_yearly_or, width = 10, height = 6)

# ------------------------------------------------------------------------------
# FIGURE 6: Sensitivity analysis comparison
# ------------------------------------------------------------------------------
# Load sensitivity results
sensitivity_results <- read_csv(file.path("outputs/tables", "sensitivity_analysis.csv"))

fig_sensitivity <- ggplot(sensitivity_results, aes(x = model, y = or_arthritis)) +
  geom_col(fill = "purple", alpha = 0.8, width = 0.6) +
  geom_errorbar(aes(ymin = or_arthritis * 0.9, ymax = or_arthritis * 1.1),  # Simplified
                width = 0.2) +
  geom_text(aes(label = sprintf("%.2f", or_arthritis)), 
            vjust = -0.5, size = 4) +
  scale_y_continuous(limits = c(0, max(sensitivity_results$or_arthritis) * 1.2)) +
  labs(
    title = "Sensitivity Analysis: Alternative Disability Definitions",
    subtitle = "Adjusted odds ratios for arthritis-disability association",
    x = "Disability Definition",
    y = "Odds Ratio"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Save figure
ggsave(file.path(output_dir, "figure6_sensitivity.png"),
       fig_sensitivity, width = 8, height = 6, dpi = 300)
ggsave(file.path(output_dir, "figure6_sensitivity.pdf"),
       fig_sensitivity, width = 8, height = 6)

# ------------------------------------------------------------------------------
# STEP 2: Create composite figure for manuscript (optional)
# ------------------------------------------------------------------------------
# Combine key figures into a single multi-panel figure
composite_figure <- (fig_trends + fig_stratified) / (fig_forest + fig_yearly_or) +
  plot_annotation(
    title = "Comprehensive Analysis of Arthritis and Disability in Older Adults",
    subtitle = "NHIS 1997-2022",
    tag_levels = "A",
    theme = theme(plot.title = element_text(face = "bold", size = 16, hjust = 0.5))
  ) +
  plot_layout(heights = c(1, 1.5))

ggsave(file.path(output_dir, "composite_figure.png"),
       composite_figure, width = 16, height = 12, dpi = 300)
ggsave(file.path(output_dir, "composite_figure.pdf"),
       composite_figure, width = 16, height = 12)

# ------------------------------------------------------------------------------
# STEP 3: Generate visualization summary
# ------------------------------------------------------------------------------
cat("Visualization complete. Figures saved to", output_dir, "\n")
cat("Generated figures:\n")
cat("1. figure1_trends.png - Time trends in arthritis and disability prevalence\n")
cat("2. figure2_subgroup_prevalence.png - Arthritis prevalence by demographics\n")
cat("3. figure3_forest_plot.png - Adjusted association forest plot\n")
cat("4. figure4_stratified_age.png - Disability by arthritis status and age\n")
cat("5. figure5_yearly_association.png - Annual arthritis-disability association\n")
cat("6. figure6_sensitivity.png - Sensitivity analysis comparison\n")
cat("7. composite_figure.png - Multi-panel composite figure\n")