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
        row_number()
        over (partition by s.visitor_id order by s.visit_date desc)
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where
        s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    order by s.visitor_id
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
    group by advertising_date, utm_source, utm_medium, total_cost
    union all
    select
        date(campaign_date) as advertising_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by advertising_date, utm_source, utm_medium, total_cost
),

final_table as (
    select
        lvl.utm_source,
        lvl.utm_medium,
        lvl.utm_campaign,
        ads.total_cost,
        date(lvl.visit_date) as visit_date,
        count(lvl.visitor_id) filter (where lvl.lead_id is not null)
        as leads_count,
        count(lvl.visitor_id) filter (where lvl.status_id = 142)
        as purchases_count,
        sum(lvl.amount) filter (where lvl.status_id = 142)
        as revenue,
        count(lvl.visitor_id) as visitors_count
    from last_visits_and_leads as lvl
    left join ads_ya_vk as ads
        on
            lvl.visit_date = ads.advertising_date
            and lvl.utm_source = ads.utm_source
            and lvl.utm_medium = ads.utm_medium
            and lvl.utm_campaign = ads.utm_campaign
    group by
        lvl.utm_source, lvl.utm_medium, lvl.utm_campaign,
        ads.total_cost, visit_date
    order by
        revenue desc nulls last, visit_date asc,
        lvl.utm_campaign desc,
        visitors_count asc, lvl.utm_source asc,
        lvl.utm_medium asc
),

--корреляция пирсона
select
    case
        when utm_source = 'vk' then utm_source
        when utm_source = 'yandex' then utm_source
        else 'other sourses'
    end as utm_source,
    coalesce(sum(total_cost), 0) as total_cost,
    sum(revenue) as revenue,
    round(cast(coalesce(corr(total_cost, revenue), 0) as numeric), 3)
    as correlation
from final_table
group by utm_source

--расходы на рекламу по каналам в динамике
	
with cte_for_ads_spendings as (
    select
        visit_date,
        utm_source,
        sum(total_cost) as total_cost
    from final_table
    where utm_source like 'vk%' or utm_source like '%andex%'
    group by visit_date, utm_source
)

select
    cte_ads_s.visit_date,
    case
        when cte_ads_s.utm_source like 'vk%' then 'vk'
        when cte_ads_s.utm_source like '%andex%' then 'yandex'
    end as utm_source,
    coalesce(max(cte_ads_s.total_cost), 0) as total_cost
from cte_for_ads_spendings as cte_ads_s

group by cte_ads_s.visit_date, utm_source

--количество лидов

select visit_date,
sum(leads_count)
from final_table
group by 1



----количество пользователей по каналам и дням, неделям, месяцам
select  
	date(visit_date) AS day,
	case 
		when date(visit_date) between '2023-06-01' and '2023-06-04' then '01-06 - 04-06' 
		when date(visit_date) between '2023-06-05' and '2023-06-11' then '05-06 - 11-06' 
		when date(visit_date) between '2023-06-12' and '2023-06-18' then '12-06 - 18-06' 
		when date(visit_date) between '2023-06-19' and '2023-06-25' then '19-06 - 25-06'  
		when date(visit_date) between '2023-06-26' and '2023-06-30' then '26-06 - 30-06'
	end as week,
	case when date(visit_date) between '2023-06-01' and '2023-06-30' then 'June'
	end as month,
	case 	
		when utm_source like 'vk%' then 'vk'
    	when utm_source like '%andex%' then 'yandex'
    	when utm_source like 'twitter%' then 'twitter'
    	when utm_source like '%telegram%' then 'telegram'
    	when utm_source like 'facebook%' then 'facebook'
    	when utm_source like '%zen%' then 'Yandex Dzen'
    		else utm_source end,
	sum(visitors_count) AS user_count
from final_table
group by 1, 2, 3, 4


--количество пользователей по дням, неделям и месяцам
select
    date(visit_date) as day,
    case
        when
            date(visit_date) between '2023-06-01' and '2023-06-04'
            then '01-06 - 04-06'
        when
            date(visit_date) between '2023-06-05' and '2023-06-11'
            then '05-06 - 11-06'
        when
            date(visit_date) between '2023-06-12' and '2023-06-18'
            then '12-06 - 18-06'
        when
            date(visit_date) between '2023-06-19' and '2023-06-25'
            then '19-06 - 25-06'
        when
            date(visit_date) between '2023-06-26' and '2023-06-30'
            then '26-06 - 30-06'
    end as week,
    case when date(visit_date) between '2023-06-01' and '2023-06-30' then 'June'
    end as month,
    sum(visitors_count) as user_count
from final_table
group by 1, 2, 3
