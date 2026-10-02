-- WHICH OPERATOR HAS THE BEST/WORST AVERAGE PUNCTUALITY (WITHIN 3 MINUTES)?

-- BEST

SELECT o.operator_name,
       CONCAT(ROUND(AVG(r.arriving_3min_pct), 2), '%') AS avg_punctuality
FROM rail_punctuality r
INNER JOIN operators o ON r.operator_id = o.operator_id
WHERE r.arriving_3min_pct IS NOT NULL
GROUP BY o.operator_name
ORDER BY AVG(r.arriving_3min_pct) DESC
LIMIT 5;

-- WORST 

SELECT o.operator_name, CONCAT(ROUND(AVG(r.arriving_3min_pct), 2), '%') AS worst_avg_punctuality
FROM rail_punctuality r
INNER JOIN operators o
ON r.operator_id = o.operator_id
WHERE arriving_3min_pct IS NOT NULL
GROUP BY operator_name
ORDER BY worst_avg_punctuality ASC
LIMIT 5;

-- RANK ALL OPERATORS BY THEIR MOST RECENT QUARTER'S PERFORMANCE

SELECT o.operator_name,
       CONCAT(ROUND(AVG(r.arriving_3min_pct), 2), '%') AS latest_punctuality
FROM rail_punctuality r
INNER JOIN operators o ON r.operator_id = o.operator_id
WHERE r.arriving_3min_pct IS NOT NULL
  AND r.end_of_period = (SELECT MAX(end_of_period) FROM rail_punctuality)
GROUP BY o.operator_name
ORDER BY AVG(r.arriving_3min_pct) DESC;

-- WHICH OPERATOR HAS THE MOST VARIATION?
SELECT
    o.operator_name,
    COUNT(*) AS quarters,
    ROUND(STDDEV_SAMP(r.arriving_3min_pct), 2) AS std_dev,
    MIN(r.arriving_3min_pct) AS lowest,
    MAX(r.arriving_3min_pct) AS highest,
    MAX(r.arriving_3min_pct) - MIN(r.arriving_3min_pct) AS range_pct
FROM rail_punctuality r
INNER JOIN operators o
    ON r.operator_id = o.operator_id
WHERE r.arriving_3min_pct IS NOT NULL
GROUP BY o.operator_name
HAVING COUNT(*) >= 8
ORDER BY std_dev DESC
LIMIT 5;