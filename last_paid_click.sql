with last_paid_visit as (
	select visitor_id,
	max(visit_date) as last_visit_date
	from sessions 
	where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
	group by visitor_id
)

select lpv.visitor_id,
lpv.last_visit_date as visit_date,
s.source as utm_source,
s.medium as utm_medium,
s.campaign as utm_campaign,
l.lead_id,
l.created_at,
l.amount,
l.closing_reason,
l.status_id
from last_paid_visit lpv
join sessions s 
on s.visitor_id = lpv.visitor_id and s.visit_date = lpv.last_visit_date
left join leads l
on lpv.visitor_id = l.visitor_id and l.created_at >= lpv.last_visit_date
order by    
l.amount DESC NULLS LAST,
    lpv.last_visit_date,
    3,
    s.medium,
    s.campaign
    limit 10;