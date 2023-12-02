WITH last_paid_visit AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit_date
    FROM
        sessions
    WHERE
        medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    GROUP BY
        visitor_id
)

SELECT
    lpv.visitor_id,
    lpv.last_visit_date AS visit_date,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
FROM
    last_paid_visit lpv
JOIN
    sessions s ON s.visitor_id = lpv.visitor_id AND s.visit_date = lpv.last_visit_date
LEFT JOIN
    leads l ON lpv.visitor_id = l.visitor_id AND l.created_at >= lpv.last_visit_date
ORDER BY
    l.amount DESC NULLS LAST,
    lpv.last_visit_date DESC,
    s.source DESC,
    s.medium DESC,
    s.campaign DESC
LIMIT 10;



