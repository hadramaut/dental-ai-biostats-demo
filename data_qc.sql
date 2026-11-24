-- Data QC for the CBCT validation study before statistical analysis.
-- Flags duplicate scans, missing labels/probabilities, invalid probabilities,
-- and implausible reading times. Any returned row is a data problem.

SELECT
    scan_id,
    COUNT(*) AS rows_cnt,
    SUM(CASE WHEN expert_label IS NULL OR ai_prob IS NULL THEN 1 ELSE 0 END) AS missing_values,
    SUM(CASE WHEN ai_prob < 0 OR ai_prob > 1 THEN 1 ELSE 0 END) AS invalid_prob,
    SUM(CASE WHEN reading_time_sec <= 0 OR reading_time_sec > 3600 THEN 1 ELSE 0 END) AS outlier_time
FROM cbct_validation_study
GROUP BY scan_id
HAVING COUNT(*) > 1
    OR SUM(CASE WHEN expert_label IS NULL OR ai_prob IS NULL THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN ai_prob < 0 OR ai_prob > 1 THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN reading_time_sec <= 0 OR reading_time_sec > 3600 THEN 1 ELSE 0 END) > 0;
