with
visitors_leads as (
    select
        s.visitor_id,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.amount,
        l.created_at,
        l.status_id,
        date(s.visit_date) as visit_date,
        row_number() over (
            partition by s.visitor_id
            order by s.visit_date desc
        ) as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where
        s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_visits_and_leads as (
    select * from visitors_leads
    where rn = 1
),

ads_ya_vk as (
    select
        date(campaign_date) as advertising_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by 1, 2, 3, 4
    union all
    select
        date(campaign_date) as advertising_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by 1, 2, 3, 4
)

select
    lvl.utm_source,
    lvl.utm_medium,
    lvl.utm_campaign,
    ads.total_cost,
    date(lvl.visit_date) as visit_date,
    count(lvl.visitor_id) filter (where lvl.lead_id is not null) as leads_count,
    count(lvl.visitor_id) filter (where lvl.status_id = 142) as purchases_count,
    sum(lvl.amount) filter (where lvl.status_id = 142) as revenue,
    count(lvl.visitor_id) as visitors_count
from last_visits_and_leads as lvl
left join ads_ya_vk as ads
    on
        lvl.visit_date = ads.advertising_date
        and lvl.utm_source = ads.utm_source
        and lvl.utm_medium = ads.utm_medium
        and lvl.utm_campaign = ads.utm_campaign
group by
    1, 2, 3,
    4, 5
order by
    8 desc nulls last,
    5 asc,
    3 desc,
    9 asc, 1 asc,
    2 asc
limit 15;
