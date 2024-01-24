--ЗАПРОСЫ В ДАШБОРД
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
group by
    utm_source;

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
group by cte_ads_s.visit_date, utm_source;


--расчет конверсии  из клика в лид и из лида в оплату
select
    round(
        sum(leads_count) * 100.0 / nullif(sum(visitors_count), 0), 2
    ) as leads_conversion,
    round(
        sum(purchases_count) * 100.0 / nullif(sum(leads_count), 0), 2
    ) as payment_conversion
from final_table;

--количество лидов

select
    visit_date,
    sum(leads_count) as leads_count
from final_table
group by visit_date;




--количество пользователей по каналам и дням, неделям, месяцам
select
    date(visit_date) as visit_day,
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
    end as visit_week,
    case when date(visit_date) between '2023-06-01' and '2023-06-30' then 'June'
    end as visit_month,
    case
        when utm_source like 'vk%' then 'vk'
        when utm_source like '%andex%' then 'yandex'
        when utm_source like 'twitter%' then 'twitter'
        when utm_source like '%telegram%' then 'telegram'
        when utm_source like 'facebook%' then 'facebook'
        when utm_source like '%zen%' then 'Yandex Dzen'
        else utm_source
    end as utm_source,
    sum(visitors_count) as user_count
from final_table
group by visit_day, visit_week, visit_month, utm_source;


--количество пользователей по дням, неделям и месяцам
select
    date(visit_date) as visit_day,
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
    end as visit_week,
    case when date(visit_date) between '2023-06-01' and '2023-06-30' then 'June'
    end as visit_month,
    sum(visitors_count) as user_count
from final_table
group by visit_day, visit_week, visit_month;

--сводная таблица

select
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    coalesce(sum(visitors_count), 0) as visitors,
    coalesce(sum(leads_count), 0) as leads,
    coalesce(sum(total_cost), 0) as total_cost,
    coalesce(sum(purchases_count), 0) as purchases,
    coalesce(sum(revenue), 0) as revenue,
    round(
        coalesce(sum(total_cost) / nullif(sum(visitors_count), 0), 0), 2
    ) as cpu,
    round(coalesce(sum(total_cost) / nullif(sum(leads_count), 0), 0), 2) as cpl,
    round(
        coalesce(sum(total_cost) / nullif(sum(purchases_count), 0), 0), 2
    ) as cppu,
    round(
        coalesce(
            (sum(revenue) - sum(total_cost)) * 1.0 / nullif(sum(total_cost), 0),
            0
        ),
        2
    ) as roi
from
    final_table
group by
    visit_date, utm_source, utm_medium, utm_campaign
order by
    visit_date;
