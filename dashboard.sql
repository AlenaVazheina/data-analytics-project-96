--ЗАПРОСЫ В ДАШБОРД
--корреляция пирсона
SELECT
    CASE
        WHEN utm_source = 'vk' THEN utm_source
        WHEN utm_source = 'yandex' THEN utm_source
        ELSE 'other sources'
    END AS utm_source_grouped,
    COALESCE(SUM(total_cost), 0) AS total_cost,
    SUM(revenue) AS revenue,
    ROUND(CAST(COALESCE(CORR(total_cost, revenue), 0) AS NUMERIC), 3) AS correlation
FROM final_table
GROUP BY utm_source_grouped;



--количество пользователей по каналам и дням, неделям, месяцам
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
group by 1, 2, 3, 4;


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
