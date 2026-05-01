WITH users_s1 as(
--CTE 1 очищаємо  signup_datetime: 
--1.прибираємо зайві пробіли (btrim); 
--2.відсікаємо час, лишаючи лише частину до 1 пробілу (split_part); 
--3. приводимо всі розділювачі до "-" (replace).
--4. отримуємо нову очищену колонку "cleaned"
--5. виводимо колонки 	user_id та promo_signup_flag
SELECT 
	user_id 
   	,promo_signup_flag 
   	,signup_datetime 
    ,replace(replace(
      split_part(btrim(signup_datetime), ' ', 1),
         '.', '-'),
         '/', '-'  )  AS cleaned
FROM cohort_users_raw
),
 users_s2 as(
 -- СТЕ 2 перетворюємо  "cleaned" з формату "текст" у формат "дата" через "TO_DATE" і називаємо "signup_ts" 
 -- через CASE та регулярний вираз (REGECT)приводимо дати до одного вигляду
SELECT
	users_s1.user_id
    ,users_s1.promo_signup_flag  
    ,cleaned 
    ,case 
    	when cleaned ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(cleaned, 'YYYY-MM-DD') --якщо формат YYYY-MM-DD то зробити 'YYYY-MM-DD' 
 		when cleaned ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(cleaned, 'DD-MM-YYYY') -- якщо формат DD-MM-YYYY то зробити  'DD-MM-YYYY'
   		when cleaned ~ '^\d{1,2}-\d{1,2}-\d{2}$' then to_date(cleaned, 'DD-MM-YY') -- якщо формат DD-MM-YY зробити 'DD-MM-YY'
        else null --якщо формат інший то вивести "NULL"
        end as signup_ts
FROM users_s1
), 
events_s1 as (
-- СТЕ 3 повторюємо кроки із СТЕ 1 для таблиці cohort_events_raw. Очищуємо дату з колонки event_datetime та отримуємо clean_date
SELECT 
	user_id
    ,event_type
    ,replace(replace(
      split_part(btrim(event_datetime), ' ', 1),
         '.', '-'),
         '/','-') AS clean_date
FROM cohort_events_raw 
),
events_s2 as (
-- СТЕ 4 перетворюєко колонку clean_date з текстового формату у формат дата і   даємо назву event_ts
-- логіка дій така як і у СТЕ 2
SELECT
	events_s1.user_id
   ,events_s1.event_type
   ,clean_date
   ,case 
      when clean_date ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(clean_date, 'YYYY-MM-DD')
      when clean_date ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(clean_date, 'DD-MM-YYYY')
      when clean_date ~ '^\d{1,2}-\d{1,2}-\d{2}$' then to_date(clean_date, 'DD-MM-YY')
       else NULL
      end as event_ts
FROM events_s1
),
user_activity as(
-- СТЕ 5 об'єднуємо таблиці з подіями та користувачами по user_id
-- створюємо cohort_month = місяць реєстрації (signup_ts), обрізаний до першого дня місяця
-- створюємо activity_month = місяць події (event_ts), обрізаний до першого дня місяця
-- обчислюємо month_offset - різниця в місяцях між датою реєстрацією та датою події
SELECT
	u.user_id
    ,u.promo_signup_flag
    ,e.event_type
    ,e.event_ts
    ,date_trunc('month', signup_ts)::date AS cohort_month
    ,date_trunc('month', event_ts)::date AS activity_month
      ,((extract(year from event_ts) * 12 + extract(month from event_ts)) -- рахуємо номер місяця події
      -
      (extract(year from signup_ts) * 12 + extract(month from signup_ts)) -- рахуємо номер місяця реєстрації
    ) AS month_offset
FROM users_s2 u
JOIN events_s2 e
  ON e.user_id = u.user_id
 where 
   signup_ts is not null  -- виключаємо користувачів без дати реєстрації 
   and event_ts is not null -- виключаємо події з відсутньою датою
   and event_type is not null -- виключаємо події по яким не вказано тип
   and event_type !='test_event' -- виключаємо тестові події
)
select
-- Основний SELECT. будуємо когортну таблицю
-- групуємо дані по: promo_signup_flag - канали залучення користувачів; cohort_month - місяць реєстрації; month_offset- місяць відносно реєстрації
-- рахуємо кількість унікальних користувачів
-- обмежуємо період спостереження за подіями січень-червень 2025р.
-- сортуємо дані
	promo_signup_flag
	,cohort_month
	,month_offset
	,count (distinct user_id) as total_users
from user_activity
where 
	activity_month >=  date '2025-01-01' 
	and activity_month <date '2025-07-01'
group by
	promo_signup_flag
	,cohort_month
	,month_offset
order by
	promo_signup_flag
	,cohort_month
	,month_offset
;
