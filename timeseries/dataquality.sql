CREATE OR REPLACE MACRO compute_stats(tbl_name, hierarchy_cols, time_col, target_col) AS TABLE
WITH aggregated_tbl AS (
    SELECT
        hierarchy_cols as unique_id,
        SUM(target_col) AS sum,
        AVG(target_col) AS avg,
        STDDEV_SAMP(target_col) AS std,
        COUNT(*) AS length,
        MIN(time_col) AS start_date,
        MAX(time_col) AS end_date,
        SUM(CASE WHEN target_col = 0 THEN 1 ELSE 0 END) AS n_zeros,
        SUM(CASE WHEN isnan(target_col) THEN 1 ELSE 0 END) AS n_nan,
        SUM(CASE WHEN target_col IS NULL THEN 1 ELSE 0 END) AS n_null,
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