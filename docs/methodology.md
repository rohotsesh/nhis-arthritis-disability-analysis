# Methodology Document
## NHIS Arthritis and Disability Analysis

### 1. Study Design
- **Type**: Repeated cross-sectional analysis
- **Data Source**: National Health Interview Survey (NHIS), 1997-2022
- **Population**: Civilian non-institutionalized U.S. population
- **Study Sample**: Adults aged 65 years and older
- **Sampling**: Complex multistage probability sampling design

### 2. Variables

#### 2.1 Outcome Variables
**Primary Outcome**: Disability
- **Definition**: Any limitation in Activities of Daily Living (ADL) or Instrumental Activities of Daily Living (IADL)
- **ADL Limitations**: Needing help with or having difficulty in bathing, dressing, eating, transferring, toileting, or walking
- **IADL Limitations**: Needing help with or having difficulty in meal preparation, shopping, managing money, using telephone, or doing housework
- **Measurement**: Binary variable (1 = any ADL/IADL limitation, 0 = no limitations)

**Secondary Outcomes**:
- ADL limitations only
- IADL limitations only

#### 2.2 Exposure Variable
**Primary Exposure**: Arthritis
- **Definition**: Self-reported doctor-diagnosed arthritis
- **Measurement**: Binary variable from NHIS question "Has a doctor ever told you that you have arthritis?" (ARTHDX)
- **Coding**: 1 = Yes, 2 = No (recoded to 1/0)

#### 2.3 Covariates
- **Age**: Categorized as 65-74, 75-84, 85+ years
- **Sex**: Male, Female
- **Race/Ethnicity**: Non-Hispanic White, Non-Hispanic Black, Hispanic, Non-Hispanic Other
- **Education**: Less than high school, High school graduate, Some college, College graduate
- **Poverty Status**: Below poverty, Near poverty (1-1.99× poverty line), At or above 2× poverty line
- **Survey Year**: Continuous (1997-2022) for trend analysis

#### 2.4 Survey Weights
- **Primary weight**: WTFA (final annual weight for adult sample)
- **Weight normalization**: Weights normalized to mean = 1 for analysis
- **Design variables**: Strata and cluster variables would be used in full analysis (simplified in demonstration)

### 3. Statistical Methods

#### 3.1 Descriptive Analysis
- **Prevalence estimates**: Survey-weighted proportions with 95% confidence intervals
- **Stratification**: By year, age group, sex, race/ethnicity
- **Trend visualization**: Time series plots with smoothing

#### 3.2 Trend Analysis
- **Annual percentage change (APC)**: Estimated using survey-weighted logistic regression with year as continuous predictor
- **Joinpoint regression**: Recommended for formal trend analysis (requires NCI software)
- **Linear trend test**: Wald test for year coefficient in logistic regression

#### 3.3 Association Analysis
- **Crude association**: Survey-weighted logistic regression of disability on arthritis (unadjusted)
- **Adjusted association**: Multivariable survey-weighted logistic regression including all covariates
- **Effect modification**: Stratified analyses by age group and sex
- **Odds ratios**: Exponentiated coefficients with 95% confidence intervals

#### 3.4 Population Attributable Fraction (PAF)
- **Formula**: PAF = [p × (RR - 1)] / [1 + p × (RR - 1)], where p = exposure prevalence, RR = relative risk
- **Approximation**: Using adjusted odds ratio as approximation for relative risk (acknowledging limitations for common outcomes)
- **Interpretation**: Proportion of disability cases that could be prevented if arthritis were eliminated

#### 3.5 Sensitivity Analyses
1. **Alternative disability definitions**:
   - ADL limitations only
   - IADL limitations only
2. **Complete case vs. multiple imputation**: Primary analysis uses complete cases; sensitivity could use multiple imputation
3. **Survey design specification**: Comparing simplified vs. full design (strata, clusters)

### 4. Survey Analysis Considerations

#### 4.1 Weighting
- NHIS uses complex sampling weights to account for:
  - Differential selection probabilities
  - Non-response adjustments
  - Post-stratification to census population totals
- **Weight application**: All analyses incorporate normalized weights using `svydesign()` from R's survey package

#### 4.2 Variance Estimation
- **Taylor series linearization**: Default method in survey package
- **Strata and PSUs**: Proper accounting requires stratum and primary sampling unit variables
- **Limitation in demonstration**: Simplified design used due to data access restrictions

#### 4.3 Missing Data
- **Pattern**: Missingness assessed for all analysis variables
- **Approach**: Complete case analysis for primary results
- **Potential bias**: Assessed through comparison of complete vs. incomplete cases

### 5. Software and Implementation

#### 5.1 Software
- **Primary**: R version 4.3.0 or higher
- **Key packages**: survey, tidyverse, ggplot2, broom
- **Reproducibility**: renv for package management, Git for version control

#### 5.2 Code Structure
```
analysis/
├── 01_data_preparation.R     # Data cleaning and variable creation
├── 02_statistical_analysis.R # Statistical models and tests
├── 03_visualization.R        # Figure generation
└── run_all.R                 # Master script
```

#### 5.3 Reproducibility
- **Data**: Raw NHIS data not included in repository (publicly available)
- **Code**: All analysis scripts fully documented
- **Environment**: Package versions captured via renv
- **Random seeds**: Set for any stochastic processes

### 6. Limitations

#### 6.1 Design Limitations
- **Cross-sectional**: Cannot establish temporal sequence or causality
- **Self-report**: Arthritis diagnosis and disability based on self-report
- **Survival bias**: Older adults with severe disability may be underrepresented

#### 6.2 Measurement Limitations
- **Arthritis definition**: Broad category includes osteoarthritis, rheumatoid arthritis, etc.
- **Disability measures**: ADL/IADL limitations may not capture all aspects of disability
- **Covariate measurement**: Income, education measured at single time point

#### 6.3 Analysis Limitations
- **Survey design simplification**: Full stratum/PSU variables not used in demonstration
- **Multiple testing**: No adjustment for multiple comparisons
- **Temporal trends**: Changing survey instruments over 25-year period

### 7. Ethical Considerations
- **Public data**: NHIS data is de-identified and publicly available
- **Privacy**: No individual identifiers included in analysis
- **Data use agreement**: Compliance with NCHS data use agreements

### 8. References
1. National Center for Health Statistics. National Health Interview Survey, 1997-2022. Hyattsville, MD.
2. Lumley T (2010). Complex Surveys: A Guide to Analysis Using R. Wiley.
3. Heeringa SG, West BT, Berglund PA (2017). Applied Survey Data Analysis. Chapman & Hall/CRC.
4. CDC/NCHS. Survey Description, National Health Interview Survey. Available at: https://www.cdc.gov/nchs/nhis.htm

### 9. Version History
- Version 1.0 (2025-12-28): Initial methodology document
- Version 1.1 (2025-12-28): Added sensitivity analysis details