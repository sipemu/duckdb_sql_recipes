CREATE OR REPLACE MACRO fill_time_gaps(tbl_name, hierarchy_cols, time_col, target_col) AS TABLE
WITH date_bounds AS (
    -- Get min and max dates per series
    SELECT 
        hierarchy_cols as unique_id,
        MIN(time_col) as start_date,
        MAX(time_col) as end_date
    FROM QUERY_TABLE(tbl_name)
    GROUP BY hierarchy_cols
),
date_sequence AS (
    -- Generate complete date sequence for each series
    SELECT 
        unique_id,
        UNNEST(GENERATE_SERIES(
            start_date::DATE,
            end_date::DATE,
            INTERVAL '1' DAY
        )) as complete_date
    FROM date_bounds
),
original_data AS (
    -- Prepare original data with struct keys
    SELECT 
        hierarchy_cols as unique_id,
        time_col,
        target_col
    FROM QUERY_TABLE(tbl_name)
)
SELECT 
    UNNEST(d.unique_id),
    d.complete_date as time_col,
    o.target_col
FROM date_sequence d
LEFT JOIN original_data o 
    ON d.unique_id = o.unique_id 
    AND d.complete_date = o.time_col
ORDER BY UNNEST(d.unique_id), d.complete_date;


-- Macro that drops series with less than m values (given as parameter).
--Inputs are the summary table and the original time series table.
CREATE OR REPLACE MACRO drop_short_series(summary_table, original_table, min_length) AS TABLE
SELECT o.* 
FROM QUERY_TABLE(original_table) o
INNER JOIN QUERY_TABLE(summary_table) s
    ON o.hierarchy_cols = s.unique_id
WHERE s.length >= min_length;


-- Macro that selects constant series using unique_values and drop them from the original time series table. 
--Inputs are the summary table and the original time series table.
CREATE OR REPLACE MACRO drop_constant_series(summary_table, original_table) AS TABLE
SELECT o.* 
FROM QUERY_TABLE(original_table) o
INNER JOIN QUERY_TABLE(summary_table) s
    ON o.hierarchy_cols = s.unique_id
WHERE s.unique_values = 1;


-- Macro that sets leading zeros to NULL in time series.
-- A leading zero is a sequence of zeros at the start of a time series.
CREATE OR REPLACE MACRO remove_leading_zeros(tbl_name, hierarchy_cols, time_col, target_col) AS TABLE
WITH zeros_marked AS (
    SELECT 
        *,
        CASE WHEN target_col = 0 THEN 1 ELSE 0 END as is_zero
    FROM QUERY_TABLE(tbl_name)
),
cumulative_zeros AS (
    SELECT 
        *,
        -- Product of is_zero values within each group, ordered by time
        -- Will be 1 for sequences of zeros, 0 after first non-zero value
        PRODUCT(is_zero) OVER (
            PARTITION BY hierarchy_cols 
            ORDER BY time_col
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as leading_zeros
    FROM zeros_marked
)
SELECT 
    * EXCLUDE(is_zero, leading_zeros)
FROM cumulative_zeros
WHERE leading_zeros = 0;