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
