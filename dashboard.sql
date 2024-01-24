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
group by utm_source

--расходы на рекламу по каналам в динамике



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
