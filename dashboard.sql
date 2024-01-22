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
),
	
final_table as ( 
    select
    date(lvl.visit_date) as visit_date,
    count(lvl.visitor_id) as visitors_count,
    lvl.utm_source,
    lvl.utm_medium,
    lvl.utm_campaign,
    ads.total_cost,
    count(lvl.visitor_id) filter (where lvl.lead_id is not null) as leads_count,
    count(lvl.visitor_id) filter (where lvl.status_id = 142) as purchases_count,
    sum(lvl.amount) filter (where lvl.status_id = 142) as revenue
from last_visits_and_leads as lvl
left join ads_ya_vk as ads
    on
        lvl.visit_date = ads.advertising_date and lvl.utm_source = ads.utm_source and lvl.utm_medium = ads.utm_medium and lvl.utm_campaign = ads.utm_campaign
group by 1, 3, 4, 5, 6
order by 9 desc nulls last, 1, 5 desc, 2, 3, 4
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
	round(cast(coalesce(corr(total_cost, revenue), 0) as numeric), 3) as correlation
from final_table
group by 1

--сводная таблица
SELECT 
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COALESCE(SUM(visitors_count),0) AS visitors,
    COALESCE(SUM(leads_count),0) AS leads,
    COALESCE(SUM(total_cost),0) AS total_cost,
    COALESCE(SUM(purchases_count),0) AS purchases,
    COALESCE(SUM(revenue),0) AS revenue,
    round(COALESCE(SUM(total_cost) / NULLIF(SUM(visitors_count), 0),0),2) AS cpu,
    round(COALESCE(SUM(total_cost) / NULLIF(SUM(leads_count), 0),0),2) AS cpl,
    round(COALESCE(SUM(total_cost) / NULLIF(SUM(purchases_count), 0),0),2) AS cppu,
    round(COALESCE((SUM(revenue) - SUM(total_cost)) * 1.0 / NULLIF(SUM(total_cost), 0), 0),2) AS roi
FROM 
    final_table
GROUP BY 
    1, 2, 3, 4
order by 
    1;


--расходы на рекламу по каналам в динамике
with cte_for_ads_spendings as (

select
visit_date,
utm_source,
sum(total_cost) AS total_cost
from final_table
where utm_source like 'vk%' or utm_source like '%andex%'
group by 1, 2)

select
cte.visit_date,
case 
	when cte.utm_source like 'vk%' then 'vk'
    when cte.utm_source like '%andex%' then 'yandex'
end as utm_source,
coalesce(max(cte.total_cost), 0) AS total_cost
from cte_for_ads_spendings cte

group by 1, 2


--расчет конверсии  из клика в лид и из лида в оплату
select 
round(sum(leads_count) * 100.0 / nullif(sum(visitors_count), 0), 2) as leads_conversion,
round(sum(purchases_count) * 100.0 / nullif(sum(leads_count), 0), 2) as payment_conversion
from final_table


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
