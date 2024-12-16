CREATE OR REPLACE MACRO compute_timeseries_quality_metrics(tbl_name, hierarchy_cols, time_col, target_col) AS TABLE
WITH zeros_marked AS (
    SELECT 
        *,
        CASE WHEN target_col = 0 THEN 1 ELSE 0 END as is_zero
    FROM QUERY_TABLE(tbl_name)
),
leading_zeros_count AS (
    SELECT 
        hierarchy_cols AS unique_id,
        SUM(CASE WHEN leading_zeros = 1 THEN 1 ELSE 0 END) as n_leading_zeros
    FROM (
        SELECT 
            *,
            PRODUCT(is_zero) OVER (
                PARTITION BY hierarchy_cols 
                ORDER BY time_col
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) as leading_zeros
        FROM zeros_marked
    )
    GROUP BY hierarchy_cols
),
ending_zeros_count AS (
    SELECT 
        hierarchy_cols AS unique_id,
        SUM(CASE WHEN ending_zeros = 1 THEN 1 ELSE 0 END) as n_ending_zeros
    FROM (
        SELECT 
            *,
            PRODUCT(is_zero) OVER (
                PARTITION BY hierarchy_cols 
                ORDER BY time_col DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) as ending_zeros
        FROM zeros_marked
    )
    GROUP BY hierarchy_cols
),
aggregated_tbl AS (
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
        SUM(CASE WHEN target_col = 0 THEN 1 ELSE 0 END) / COUNT(*) AS perc_zeros,
        SUM(CASE WHEN isnan(target_col) THEN 1 ELSE 0 END) AS n_nan,
        SUM(CASE WHEN isnan(target_col) THEN 1 ELSE 0 END) / COUNT(*) AS perc_nan,
        SUM(CASE WHEN target_col IS NULL THEN 1 ELSE 0 END) AS n_null,
        SUM(CASE WHEN target_col IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS perc_null,
        DATE_DIFF('days', MIN(time_col), MAX(time_col)) + 1 AS expected_length
    FROM QUERY_TABLE(tbl_name)
    GROUP BY hierarchy_cols
),
aggregated_with_zeros_tbl AS (
    SELECT 
        a.*,
        (expected_length - length) AS n_gaps,
        DATE_DIFF('days', end_date, MAX(end_date) OVER ()) AS n_gaps_to_max_date,
        l.n_leading_zeros,
        e.n_ending_zeros
    FROM aggregated_tbl a
    LEFT JOIN leading_zeros_count l ON a.unique_id = l.unique_id
    LEFT JOIN ending_zeros_count e ON a.unique_id = e.unique_id
)
SELECT 
    UNNEST(unique_id), 
    sum,
    avg,
    std,
    unique_values,
    length,
    start_date,
    end_date,
    n_zeros,
    perc_zeros,
    n_nan,
    perc_nan,
    n_null,
    perc_null,
    expected_length,
    n_gaps,
    n_gaps_to_max_date,
    n_leading_zeros,
    n_ending_zeros
FROM aggregated_with_zeros_tbl;


-- Macro that counts the number of series with less than m values (given as parameter). Additionally, it returns the percentage of series with less than m values.
--Inputs are the summary table and the minimum length.
CREATE OR REPLACE MACRO count_short_series(summary_table, min_length) AS TABLE
SELECT COUNT(*) AS n_short_series,
       (COUNT(*) / (SELECT COUNT(*) FROM QUERY_TABLE(summary_table))) AS perc_short_series
FROM QUERY_TABLE(summary_table)
WHERE length < min_length;


-- Macro that counts the number of constant series. Additionally, it returns the percentage of constant series.
-- Inputs are the summary table.
CREATE OR REPLACE MACRO count_constant_series(summary_table) AS TABLE
SELECT COUNT(*) AS n_constant_series,
       (COUNT(*) / (SELECT COUNT(*) FROM QUERY_TABLE(summary_table))) AS perc_constant_series
FROM QUERY_TABLE(summary_table)
WHERE unique_values = 1;

