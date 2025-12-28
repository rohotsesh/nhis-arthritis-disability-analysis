# NHIS Arthritis and Disability Analysis

## Project Overview
This repository contains a reproducible analysis workflow examining the relationship between arthritis and disability in adults aged 65+ using data from the National Health Interview Survey (NHIS). The project focuses on establishing research practices for chronic disease surveillance among the elderly population.

## Research Question
How has the prevalence of arthritis-related disability changed over time among older adults (65+) in the United States, and what factors are associated with disability trends?

## Repository Structure
```
nhis-arthritis-disability-analysis/
├── analysis/
│   ├── 01_data_preparation.R
│   ├── 02_statistical_analysis.R
│   ├── 03_visualization.R
│   └── run_all.R
├── data/
│   ├── raw/           # Raw NHIS data (not stored in repo)
│   ├── processed/     # Processed analysis datasets
│   └── README.md      # Data documentation
├── outputs/
│   ├── figures/       # Generated visualizations
│   ├── tables/        # Statistical tables
│   └── reports/       # Analysis reports
├── docs/
│   └── methodology.md # Detailed methodology
├── .gitignore
├── LICENSE
├── README.md
└── environment.R      # R package dependencies
```

## Analysis Workflow
1. **Data Preparation**: Download and clean NHIS data (1997-2022) focusing on arthritis and disability variables
2. **Statistical Analysis**: Calculate prevalence estimates, trend analysis, logistic regression models
3. **Visualization**: Create time series plots, prevalence maps, and stratified visualizations

## Getting Started
1. Clone this repository: `git clone https://github.com/rohotsesh/nhis-arthritis-disability-analysis.git`
2. Install required R packages: `source("environment.R")`
3. Run the analysis: `Rscript analysis/run_all.R`

## Data Sources
### Primary Data: National Health Interview Survey (NHIS)
- Years: 1997-2022 (annual cross-sectional surveys)
- Target population: Civilian non-institutionalized U.S. population
- Key variables:
  - Arthritis diagnosis (ARTHDX)
  - Disability measures (ADL, IADL limitations)
  - Demographic covariates (age, sex, race, education, income)
  - Survey weights

### Data Access
NHIS data is publicly available from the CDC/NCHS website. Due to size restrictions, raw data files are not stored in this repository. Users must download the data separately and place it in the `data/raw/` directory.

## Methodology
See [docs/methodology.md](docs/methodology.md) for detailed statistical methods, including:
- Survey-weighted prevalence estimation
- Joinpoint regression for trend analysis
- Multivariable logistic regression
- Sensitivity analyses

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- National Center for Health Statistics for NHIS data
- CDC for making health survey data publicly available
- R community for survey analysis packages