# Data Directory

## Structure
- `raw/`: Contains raw NHIS data files (not stored in repository)
- `processed/`: Cleaned and analysis-ready datasets

## NHIS Data Sources
The National Health Interview Survey (NHIS) data can be downloaded from:
- [CDC/NCHS NHIS Data Download](https://www.cdc.gov/nchs/nhis/data-questionnaires-documentation.htm)
- [IPUMS NHIS](https://nhis.ipums.org/nhis/) (harmonized data)

## Required Files
To run the analysis, you need to download the following files and place them in `data/raw/`:

### Annual NHIS Person Files (1997-2022)
- `nhis_1997_personsx.csv` (or .dat, .sas7bdat)
- `nhis_1998_personsx.csv`
- ... through 2022

### Variable Selection
Key variables needed for analysis:

1. **Arthritis diagnosis**: `ARTHDX` (Has a doctor ever told you that you have arthritis?)
2. **Disability measures**:
   - Activities of Daily Living (ADL): `ADLHELP`, `ADLHAVE`
   - Instrumental Activities of Daily Living (IADL): `IADLHELP`, `IADLHAVE`
   - Functional limitations: `AIDHELP`, `AIDHAVE`
3. **Demographic variables**:
   - Age: `AGE_P`
   - Sex: `SEX`
   - Race/Ethnicity: `RACERPI`, `HISPAN`, `RACEREC`
   - Education: `EDUC`
   - Income: `INCFAM`, `POVRAT`
4. **Survey weights**: `WTFA`, `WTFA_SA`

## Data Processing Steps
1. **Extract**: Download annual NHIS person files
2. **Transform**: Select variables, recode missing values, create consistent coding across years
3. **Combine**: Append annual files into a single longitudinal dataset
4. **Clean**: Apply survey weights, handle missing data, create analysis variables

## Notes
- Due to NHIS confidentiality requirements, no individual-level data is stored in this repository
- Users must obtain NHIS data through proper channels (registration may be required)
- Processed datasets in `data/processed/` can be recreated using the data preparation script