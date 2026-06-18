

/*
“We need to understand at what stage of the process we’re losing users and how we can improve user retention over time.”

 use SQL to map the entire conversion funnel, identify the main drop-off points, and evaluate user retention by cohort.
Finally, you’ll need to propose actionable improvements based on the data.

Project Objectives

1.    Build multi-stage funnels in SQL using CTEs.
2.    Calculate conversion rates between steps and detect drops.
3.    Analyze user retention by cohort.
4.    Simulate improvements in conversion or retention.
5.    Validate results and communicate executive-level findings.

1- Explore the dataset to understand the user journey and identify key events that represent stages in the conversion funnel.
Know data estructure of "mercadolibre_funnel " and  "mercadolibre_retention"  Tables

*/

--Exploring mercadolibre_funnel
SELECT *
FROM mercadolibre_funnel
LIMIT 5;

--Exploring mercadolibre_retention
SELECT *
FROM mercadolibre_retention
LIMIT 5;

-- Confirm funnel sequency 
SELECT DISTINCT event_name
FROM mercadolibre_funnel
ORDER BY event_name;

/*
Create CTE per event using users as reference and keep the desired date range, between '2025-01-01' and '2025-08-31'.
Remember to avoid duplicates.

Usa nombres consistentes para las CTEs: first_visit, select_item, add_to_cart, begin_checkout, add_shipping_info, add_payment_info, purchase.
En la CTE select_item, incluye los eventos select_item y select_promotion.

use consistent naming for CTEs: first_visit, select_item, add_to_cart, begin_checkout, add_shipping_info, add_payment_info, purchase.
In the select_item CTE, include both select_item and select_promotion events.

merge CTEs starting from first_visit and chaining LEFT JOIN by user.

use COUNT(<alias>.user_id) in each stage in the final SELECT.

use the following names: 
-> usuarios_first_visit,
-> usuarios_select_item, usuarios_add_to_cart,
-> usuarios_begin_checkout,
-> usuarios_add_shipping_info,
-> usuarios_add_payment_info 
-> usuarios_purchase.
*/

-- 1) created CTEs for each event with the specified date range and avoiding duplicates
WITH first_visit AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'first_visit'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
select_item AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name IN ('select_item', 'select_promotion')
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_to_cart AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'add_to_cart'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
begin_checkout AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'begin_checkout'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
 add_shipping_info AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'add_shipping_info'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
 add_payment_info AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'add_payment_info'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
 purchase AS (
    SELECT DISTINCT user_id
    FROM mercadolibre_funnel
    WHERE event_name = 'purchase'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
-- 2) Count unique users in each funnel stage by merging CTEs with LEFT JOINs starting from first_visit
funnel_counts AS(
SELECT
  fv.country,
  COUNT(fv.user_id) AS usuarios_first_visit,
  COUNT(si.user_id) AS usuarios_select_item,
  COUNT(a.user_id) AS usuarios_add_to_cart,
  COUNT(bc.user_id) AS usuarios_begin_checkout,
  COUNT(asi.user_id) AS usuarios_add_shipping_info,
  COUNT(api.user_id) AS usuarios_add_payment_info,
  COUNT(p.user_id) AS usuarios_purchase,
  COUNT(fv.country) AS pais_first_visit,
  COUNT(si.country) AS pais_select_item,
  COUNT(a.country) AS pais_add_to_cart,
  COUNT(bc.country) AS pais_begin_checkout,
  COUNT(asi.country) AS pais_add_shipping_info,
  COUNT(api.country) AS pais_add_payment_info,
  COUNT(p.country) AS pais_purchase  
FROM first_visits fv
LEFT JOIN select_item si        ON fv.user_id = si.user_id   AND fv.country = si.country
LEFT JOIN add_to_cart a         ON fv.user_id = a.user_id    AND fv.country = a.country
LEFT JOIN begin_checkout bc     ON fv.user_id = bc.user_id   AND fv.country = bc.country
LEFT JOIN add_shipping_info asi ON fv.user_id = asi.user_id  AND fv.country = asi.country
LEFT JOIN add_payment_info api  ON fv.user_id = api.user_id  AND fv.country = api.country
LEFT JOIN purchase p            ON fv.user_id = p.user_id    AND fv.country = p.country
GROUP BY fv.country   
)
    
/*
3) calculate conversion rates from the initial stage (first_visit) to each subsequent stage using the counts obtained in the previous step.
*/
SELECT
ROUND(usuarios_select_item * 100.0/ usuarios_first_visit,2) AS conversion_select_item,
ROUND(usuarios_add_to_cart * 100.0/ usuarios_first_visit,2) AS conversion_add_to_cart,
ROUND(usuarios_begin_checkout * 100.0/ usuarios_first_visit,2) AS conversion_begin_checkout,
ROUND(usuarios_add_shipping_info * 100.0/ usuarios_first_visit,2) AS conversion_add_shipping_info,
ROUND(usuarios_add_payment_info * 100.0/ usuarios_first_visit,2) AS conversion_add_payment_info,
ROUND(usuarios_purchase * 100.0/ usuarios_first_visit,2) AS conversion_purchase
FROM funnel_counts;

/*
4) group by conversions per country and detect what is the funnel with higher user drop.
*/

SELECT
-- Muestra country
country,
-- Calculate conversion_select_item,
usuarios_select_item * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_select_item,
-- Calculate conversion_add_to_cart,
usuarios_add_to_cart * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_add_to_cart,
-- Calculate conversion_begin_checkout,
usuarios_begin_checkout * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_begin_checkout,
-- Calculate conversion_add_shipping_info,
usuarios_add_shipping_info * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_add_shipping_info,
-- Calculate conversion_add_payment_info,
usuarios_add_payment_info * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_add_payment_info ,
-- Calculate conversion_purchase
usuarios_purchase * 100.0 / NULLIF(usuarios_first_visit , 0)AS conversion_purchase
FROM funnel_counts
-- Ordena
ORDER BY conversion_purchase DESC;


/* 
5) calculate the retention rate for each cohort by month using "mercadolibre_retention"
*/

-- 1: count active users since registeration date and group by country and day after signup.

SELECT
  country,
  ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 7  AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d7_pct,
  ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 14 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d14_pct,
  ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 21 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d21_pct,
  ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 28 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d28_pct
FROM mercadolibre_retention
WHERE activity_date BETWEEN '2025-01-01' AND '2025-08-31'
GROUP BY country
ORDER BY country;

/*
6) analyze retention per cohort using "mercadolibre_retention". 
*/
WITH cohort AS (
SELECT 
-- group by user id
user_id,
-- take earliest date of signup and convert to cohort by month
MIN(signup_date) AS signup_date,
-- group by month and formant to YYYY-MM
TO_CHAR(DATE_TRUNC('month', MIN(signup_date)), 'YYYY-MM') AS cohort
FROM mercadolibre_retention
GROUP BY user_id
LIMIT 5;)

/*
      user_id	                        signup_date	 cohort
0002b1ba-9c7f-4989-87cb-54109b84c2cb	2025-05-02	2025-05
0011c921-8b74-4984-9f90-b50daae0442b	2025-02-19	2025-02
00147274-7efe-42fd-aaaf-a1b7aefb834f	2025-02-01	2025-02
0017b94f-3a9f-4850-a011-4b3b3141c201	2025-08-05	2025-08
00198c1f-bc1e-403e-b46a-67b0b3ac7657	2025-05-01	2025-05
*/


/*
2) CTE activity: take key columns from  mercadolibre_retention add cohort 
*/
-- ESCRIBE TU CODIGO AQUI
activity AS (
    SELECT
    r.user_id,
    c.cohort,
    r.day_after_signup,
    r.active
    FROM mercadolibre_retention AS r
    LEFT JOIN cohort AS c 
    ON r.user_id = c.user_id
    WHERE r.activity_date BETWEEN '2025-01-01' AND '2025-08-31' 
)
-- 3) SELECT final: conteos exactos por día acumulado X / tamaño de cohorte -> % redondeado
-- ESCRIBE TU CODIGO AQUI
SELECT
cohort,
ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 7  AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d7_pct,
ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 14 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d14_pct,
ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 21 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d21_pct,
ROUND((COUNT(DISTINCT CASE WHEN day_after_signup >= 28 AND active = 1 THEN user_id END))*100.0 / NULLIF(COUNT(DISTINCT user_id),0),1)  AS retention_d28_pct
FROM activity
GROUP BY cohort
ORDER BY cohort;

/*

Results:
cohort	retention_d7_pct	retention_d14_pct	retention_d21_pct	retention_d28_pct
2025-01	        86.2	             56.2	             24.1	           3
2025-02	        86.8	             56	                 24.6	           2.7
2025-03	        87.7	             56.8	             26.6	           3
2025-04	        87.2	             53.9	             23	               2
2025-05	        86	                 54.5	             26.2	           3
2025-06	        85.9	             55.1	             25.2	           2.1
2025-07	        86.4	             56.4	             25.9	           2.7
2025-08	        70.8	             29.7	             7.5	           0.2

*/