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

-- HOW HAS EACH OPERATOR'S PUNCTUALITY CHANGED QUARTER ON QUARTER AND YEAR ON YEAR?

WITH quarterly AS (
    SELECT
        o.operator_name,
        r.operator_id,
        r.start_of_period,
        r.arriving_3min_pct AS pct,
        LAG(r.arriving_3min_pct, 1) OVER w AS prev_q,
        LAG(r.arriving_3min_pct, 4) OVER w AS prev_year
    FROM rail_punctuality r
    INNER JOIN operators o ON r.operator_id = o.operator_id
    WHERE r.arriving_3min_pct IS NOT NULL
    WINDOW w AS (PARTITION BY r.operator_id ORDER BY r.start_of_period)
)
SELECT
    operator_name,
    start_of_period,
    pct,
    ROUND(pct - prev_q, 2)    AS qoq_change,
    ROUND(pct - prev_year, 2) AS yoy_change
FROM quarterly
ORDER BY operator_name, start_of_period;

-- WHICH OPERATOR HAS THE BEST PUNCTUALITY PER QUARTER? (RANKED)

SELECT
    r.start_of_period,
    o.operator_name,
    r.arriving_3min_pct,
    RANK() OVER (
        PARTITION BY r.start_of_period
        ORDER BY r.arriving_3min_pct DESC
    ) AS punctuality_rank
FROM rail_punctuality r
INNER JOIN operators o
    ON o.operator_id = r.operator_id
WHERE r.arriving_3min_pct IS NOT NULL
ORDER BY r.start_of_period, punctuality_rank;