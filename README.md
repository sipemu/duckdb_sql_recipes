# DuckDB SQL Recipes

A collection of useful SQL recipes and macros for DuckDB, focusing on common data analysis patterns and utilities.

## Overview

This repository contains ready-to-use SQL recipes for DuckDB, making it easier to perform common data analysis tasks. The recipes are organized by domain and use case.

## Table of Contents

- [Overview](#overview)
- [Recipes](#recipes)
  - [Time Series Analysis](#time-series-analysis)
    - [Data Quality Statistics](#data-quality-statistics-timeseriesdataqualitysql)
- [Contributing](#contributing)
- [License](#license)


## Recipes

### Time Series Analysis

<details>
#### Data Quality Statistics (`timeseries/dataquality.sql`)
</details>

A macro that computes comprehensive statistics for time series data, helping identify data quality issues and gaps. This macro is for daily data, please adjust the macro for other time granularities accordingly.

**Usage:**
```sql
SELECT * FROM compute_stats('my_table', {'product_id': product_id, 'store_id': store_id}, date_column, sales_value);
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
- **length**: Number of actual data points
- **start_date**: First date in the series
- **end_date**: Last date in the series
- **n_zeros**: Count of zero values
- **n_nan**: Count of NaN values
- **n_null**: Count of NULL values
- **expected_length**: Expected number of data points based on date range
- **n_gaps**: Number of missing data points in the series
- **n_gaps_to_max_date**: Number of days between series end date and the maximum end date across all series

## Contributing

Feel free to contribute additional SQL recipes by submitting a pull request. Please ensure your recipes are well-documented and include example usage.

## License

This project is open source and available under the MIT License.
