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
    sess.source AS utm_source,
    sess.medium AS utm_medium,
    sess.campaign AS utm_campaign,
    ld.lead_id,
    ld.created_at,
    ld.amount,
    ld.closing_reason,
    ld.status_id
FROM
    last_paid_visit AS lpv
INNER JOIN sessions AS sess
    ON
        lpv.visitor_id = sess.visitor_id
        AND lpv.last_visit_date = sess.visit_date
LEFT JOIN leads AS ld
    ON
        lpv.visitor_id = ld.visitor_id
        AND lpv.last_visit_date <= ld.created_at
ORDER BY
    ld.amount DESC NULLS LAST,
    lpv.last_visit_date DESC,
    sess.source DESC,
    sess.medium DESC,
    sess.campaign DESC
LIMIT 10;
