# DuckDB SQL Recipes

A collection of useful SQL recipes and macros for DuckDB, focusing on common data analysis patterns and utilities.

## Overview

This repository contains ready-to-use SQL recipes for DuckDB, making it easier to perform common data analysis tasks. The recipes are organized by domain and use case.

## Table of Contents

- [Overview](#overview)
- [Recipes](#recipes)
  - [Time Series Analysis](#time-series-analysis)
    - [Data Quality Statistics](#data-quality-statistics-timeseriesdataqualitysql)
    - [Data Preparation](#data-preparation-timeseriesdata_preparationsql)
- [Contributing](#contributing)
- [License](#license)


## Recipes

### Time Series Analysis

<details>

<summary>Data Quality Statistics</summary>

#### Data Quality Statistics ([`timeseries/timeseries_quality_metrics.sql`](timeseries/timeseries_quality_metrics.sql))

A collection of macros for analyzing and filtering time series data quality. The main macro computes comprehensive statistics, and additional utility macros help identify and handle problematic series.

**Usage:**
```sql
SELECT * FROM compute_timeseries_quality_metrics(timeseries_tbl, {'product_id': product_id, 'store_id': store_id}, date_column, sales_value);
```

**Parameters:**
- **tbl_name**: Name of the table or subquery to analyze (string)
- **hierarchy_cols**: Struct of column names and values that define the time series grouping
- **time_col**: Date/timestamp column for the time series
- **target_col**: The metric column to analyze

**Output Metrics:**
- **sum**: Total sum of the target variable
- **avg**: Average value
- **std**: Standard deviation
- **unique_values**: Number of distinct values in the target column
- **length**: Number of actual data points
- **start_date**: First date in the series
- **end_date**: Last date in the series
- **n_zeros**: Count of zero values
- **perc_zeros**: Percentage of zero values
- **n_nan**: Count of NaN values
- **perc_nan**: Percentage of NaN values
- **n_null**: Count of NULL values
- **perc_null**: Percentage of NULL values
- **expected_length**: Expected number of data points based on date range
- **n_gaps**: Number of missing data points in the series
- **n_gaps_to_max_date**: Number of days between series end date and the maximum end date across all series
- **n_leading_zeros**: Number of consecutive zeros at the start of the series
- **n_ending_zeros**: Number of consecutive zeros at the end of the series

##### Utility Macros

###### Count Short Series
Identifies series with fewer than m values.

```sql
SELECT * FROM count_short_series(timeseries_summary_tbl, 30);
```

**Parameters:**
- **summary_table**: Summary table of the time series data
- **min_length**: Minimum length of the series

**Output:**
- **n_short_series**: Number of series with length < m
- **perc_short_series**: Percentage of series with length < m


###### Count Constant Series
Identifies series with only one unique value.

```sql
SELECT * FROM count_constant_series(timeseries_summary_tbl);
```
**Parameters:**
- **summary_table**: Summary table of the time series data
**Output:**
- **n_constant_series**: Number of constant series
- **perc_constant_series**: Percentage of constant series

</details>

<details>
<summary>Data Preparation</summary>

#### Data Preparation ([`timeseries/data_preparation.sql`](timeseries/data_preparation.sql))

A macro that fills gaps in daily time series data by generating missing timestamps and filling target values with NULL.

**Usage:**
```sql
SELECT * FROM fill_time_gaps(timeseries_tbl, {'product_id': product_id, 'store_id': store_id}, date_column, sales_value);
```

**Parameters:**
- **tbl_name**: Name of the table or subquery to process (string)
- **hierarchy_cols**: Struct of column names and values that define the time series grouping
- **time_col**: Date/timestamp column for the time series
- **target_col**: The metric column to fill with NULL for missing dates

**Output:**
- Returns the original data with additional rows for missing dates
- Missing values are filled with NULL
- Results are ordered by hierarchy columns and date


##### Utility Macros

###### Drop Short Series
Removes series with fewer than m values from the dataset.

```sql
SELECT * FROM drop_short_series(timeseries_summary_tbl, timeseries_tbl, 30);
```

**Parameters:**
- **summary_table**: Summary table of the time series data
- **min_length**: Minimum length of the series

###### Drop Constant Series
Removes constant series from the dataset.

```sql
SELECT * FROM drop_constant_series(timeseries_summary_tbl, timeseries_tbl);
```

**Parameters:**
- **summary_table**: Summary table of the time series data

###### Remove Leading Zeros
Removes sequences of zeros at the start of each time series.

```sql
SELECT * FROM remove_leading_zeros(timeseries_tbl, {'product_id': product_id, 'store_id': store_id}, date_column, sales_value);
```

**Parameters:**
- **tbl_name**: Name of the table or subquery to process
- **hierarchy_cols**: Struct of column names and values that define the time series grouping
- **time_col**: Date/timestamp column for the time series
- **target_col**: The metric column to check for zeros

**Output:**
- Returns the original data with leading zeros removed
- Keeps all data points after the first non-zero value in each series
- Maintains original column structure

</details>


## Contributing

Feel free to contribute additional SQL recipes by submitting a pull request. Please ensure your recipes are well-documented and include example usage.

## License

This project is open source and available under the MIT License.
