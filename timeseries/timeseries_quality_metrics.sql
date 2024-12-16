CREATE OR REPLACE MACRO compute_timeseries_quality_metrics(tbl_name, hierarchy_cols, time_col, target_col) AS TABLE
WITH aggregated_tbl AS (
    SELECT
        hierarchy_cols as unique_id,
        SUM(target_col) AS sum,
        AVG(target_col) AS avg,
        STDDEV_SAMP(target_col) AS std,
        COUNT(DISTINCT target_col) AS unique_values,
        COUNT(*) AS length,
        MIN(time_col) AS start_date,
        MAX(time_col) AS end_date,
        SUM(CASE WHEN target_col = 0 THEN 1 ELSE 0 END) AS n_zeros,
        n_zeros / length AS perc_zeros,
        SUM(CASE WHEN isnan(target_col) THEN 1 ELSE 0 END) AS n_nan,
        n_nan / length AS perc_nan,
        SUM(CASE WHEN target_col IS NULL THEN 1 ELSE 0 END) AS n_null,
        n_null / length AS perc_null,
        DATE_DIFF('days', MIN(time_col), MAX(time_col)) + 1 AS expected_length
    FROM QUERY_TABLE(tbl_name)
    GROUP BY hierarchy_cols
)
SELECT 
    UNNEST(unique_id), 
    *  EXCLUDE(unique_id),
    (expected_length - length) AS n_gaps,
    DATE_DIFF('days', end_date, MAX(end_date) OVER ()) AS n_gaps_to_max_date
FROM aggregated_tbl;


-- Macro that counts the number of series with less than m values (given as parameter). Additionally, it returns the percentage of series with less than m values.
--Inputs are the summary table and the minimum length.
CREATE OR REPLACE MACRO count_short_series(summary_table, min_length) AS TABLE
SELECT COUNT(*) AS n_short_series,
       (COUNT(*) / (SELECT COUNT(*) FROM QUERY_TABLE(summary_table))) AS perc_short_series
FROM QUERY_TABLE(summary_table)
WHERE length < min_length;


-- Macro that drops series with less than m values (given as parameter).
--Inputs are the summary table and the original time series table.
CREATE OR REPLACE MACRO drop_short_series(summary_table, original_table, min_length) AS TABLE
SELECT o.* 
FROM QUERY_TABLE(original_table) o
INNER JOIN QUERY_TABLE(summary_table) s
    ON o.hierarchy_cols = s.unique_id
WHERE s.length >= min_length;


-- Macro that counts the number of constant series. Additionally, it returns the percentage of constant series.
-- Inputs are the summary table.
CREATE OR REPLACE MACRO count_constant_series(summary_table) AS TABLE
SELECT COUNT(*) AS n_constant_series,
       (COUNT(*) / (SELECT COUNT(*) FROM QUERY_TABLE(summary_table))) AS perc_constant_series
FROM QUERY_TABLE(summary_table)
WHERE unique_values = 1;


-- Macro that selects constant series using unique_values and drop them from the original time series table. 
--Inputs are the summary table and the original time series table.
CREATE OR REPLACE MACRO drop_constant_series(summary_table, original_table) AS TABLE
SELECT o.* 
FROM QUERY_TABLE(original_table) o
INNER JOIN QUERY_TABLE(summary_table) s
    ON o.hierarchy_cols = s.unique_id
WHERE s.unique_values = 1;

