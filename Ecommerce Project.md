# ECOMMERCE PROJECT
Click [here](https://console.cloud.google.com/bigquery?sq=419516868446:ee029ce0d51b402aa4de14f41b7a2950) to see my origin code on BigQuery

## Table Of Contents
  - [Source](#source)
  - [Case Study Questions](#case-study-questions)
  - [Solution](#solution)
    
## Source
#### 1. Table Schema [here](https://support.google.com/analytics/answer/3437719?hl=en)
- Datasets

For each Analytics view that is enabled for BigQuery integration, a dataset is added using the view ID as the name.

- Tables
Within each dataset, a table is imported for each day of export. Daily tables have the format "ga_sessions_YYYYMMDD".

Intraday data is imported at least three times a day. Intraday tables have the format "ga_sessions_intraday_YYYYMMDD". During the same day, each import of intraday data overwrites the previous import in the same table.

When the daily import is complete, the intraday table from the previous day is deleted. For the current day, until the first intraday import, there is no intraday table. If an intraday-table write fails, then the previous day's intraday table is preserved.

Data for the current day is not final until the daily import is complete. You may notice differences between intraday and daily data based on active user sessions that cross the time boundary of last intraday import.
 
#### 2. Discription Table:
<img src="https://github.com/Hoaithomint/SQL/assets/141213880/7cd3b640-30ad-4bfe-99a0-0d7035b06e8d" alt="Image" width="900">

#### 3. Format Element [here](https://cloud.google.com/bigquery/docs/reference/standard-sql/format-elements)

## Case Study Questions
1. Calculate total visit, pageview, transaction for Jan, Feb and March 2017 order by month
2. Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
3. Revenue by traffic source by week, by month in June 2017
4. Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017
5. Average number of transactions per user that made a purchase in July 2017
6. Average amount of money spent per session. Only include purchaser data in July 2017
7. Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017
8. Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase

## Solution
#### 1. Calculate total visit, pageview, transaction for Jan, Feb and March 2017 order by month

```sql
SELECT  
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month --field date ở trong ga_session đang ở dạng string, để chuyển nó thành dạng yyyymm hoặc yyyyww(year-week) thì phải chuyển nó về dạng datetime bằng parse_date
    , SUM(totals.visits) AS total_visits
    , SUM(totals.pageviews) AS total_pageviews
    , SUM(totals.transactions) AS total_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;
```
##### Result set:
| month       | total_visits |total_pageviews| total_transactions|
| ----------- | ------------ |---------------|-------------------|
| 201701      | 64694        |257708         |713                |
| 201702      | 62192        |233373         |733                |
| 201703      | 69931        |259522         |993                |

***
#### 2. Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
Bounce session is the session that user does not raise any click after landing on the website

```sql
SELECT  
    trafficSource.source AS source
    , SUM(totals.visits) AS total_visits
    , SUM(totals.bounces) AS total_no_of_bounces
    , 100*(SUM(totals.bounces)/SUM(totals.visits)) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
GROUP BY source
ORDER BY SUM(totals.visits) DESC;
```
##### Result set:
|source	             |total_visits	|total_no_of_bounces|bounce_rate|
|--------------------|--------------|-------------------|-----------|
|google	             |38400	        |19798	            |51.55729167|
|(direct)	         |19891       	|8606	            |43.2657986 |
|youtube.com	     |6351	        |4238	            |66.72964887|
|analytics.google.com|1972	        |1064	            |53.95537525|

***
#### 3. Revenue by traffic source by week, by month in June 2017

```sql
(SELECT  
    'Month' AS time_type
    , format_date('%Y%m', PARSE_DATE('%Y%m%d',date)) AS time
    , trafficSource.source AS source
    , SUM(productRevenue)/1000000 AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
WHERE productRevenue is not null
GROUP BY source, time)
UNION ALL
(SELECT  
    'Week' AS time_type
    , format_date('%Y%W', PARSE_DATE('%Y%m%d',date)) AS time
    , trafficSource.source AS source
    , SUM(productRevenue)/1000000 AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
WHERE productRevenue is not null
GROUP BY source, time)
ORDER BY revenue DESC;
```
##### Result set:
|time_type	|time	|source	  |revenue       |
|-----------|-------|---------|--------------|
|Month	    |201706	|(direct) |97333.6197    |
|Week	    |201724	|(direct) |30908.9099    |
|Week	    |201725	|(direct) |27295.3199    |
|Month	    |201706	|google   |18757.1799    |

***
#### 4. Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017
###### Note: 
fullVisitorId field is user id.
We have to: UNNEST(hits) AS hits, UNNEST(hits.product) to access productRevenue

- Purchaser: totals.transactions >=1; productRevenue is not null.

- Non-purchaser: totals.transactions IS NULL;  product.productRevenue is null 

- Avg pageview = total pageview / number unique user.

```sql
WITH APP AS (
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month
        ,SUM(totals.pageviews)/count(distinct fullVisitorId) AS avg_pageviews_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST (hits) hits,
        UNNEST (hits.product) product
    WHERE 
        _table_suffix BETWEEN '0601' AND '0731'
        AND (totals.transactions >= 1 and productRevenue is not null)
    GROUP BY month
)

, APNP AS (
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month
        ,SUM(totals.pageviews)/COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST (hits) hits,
        UNNEST (hits.product) product
    WHERE 
        _table_suffix BETWEEN '0601' AND '0731'
        AND (totals.transactions is null and productRevenue is null)
    GROUP BY month
)

SELECT 
    APP.month
    , avg_pageviews_purchase
    , avg_pageviews_non_purchase
FROM APP, APNP
WHERE APP.month = APNP.month
ORDER BY month;   
```
##### Result set:
|month	  |avg_pageviews_purchase	|avg_pageviews_non_purchase|
|---------|-------------------------|--------------------------|
|201706	  |94.02050114	            |316.8655885               |
|201707	  |124.2375519	            |334.0565598               |

***
#### 5. Average number of transactions per user that made a purchase in July 2017
- purchaser: totals.transactions >=1; productRevenue is not null. fullVisitorId field is user id.
- Add condition "product.productRevenue is not null" to calculate correctly

```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month
    , SUM(totals.transactions)/count(distinct fullVisitorId) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
WHERE productRevenue IS NOT NULL
GROUP BY month;
```
##### Result set:
|Month	|Avg_total_transactions_per_user|
|-------|-------------------------------|
|201707	|4.163900415                    |

***
#### 6. Average amount of money spent per session. Only include purchaser data in July 2017	
- Where clause must be include "totals.transactions IS NOT NULL" and "product.productRevenue is not null"
- avg_spend_per_session = total revenue/ total visit
- To shorten the result, productRevenue should be divided by 1000000
###### Notice: per visit is different to per visitor

```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month
    , ROUND(SUM(productRevenue)/COUNT(totals.visits)/1000000,2) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
WHERE 
    totals.transactions IS NOT NULL
    AND product.productRevenue IS NOT NULL
GROUP BY month;
```
##### Result set:
|Month	|avg_revenue_by_user_per_visit|
|-------|-----------------------------|
|201707	|43.85                        |

***
#### 7. Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017	
- We have to    UNNEST(hits) AS hits
               , UNNEST(hits.product) as product to get v2ProductName."
- Add condition "product.productRevenue is not null" to calculate correctly
- Using productQuantity to calculate quantity.

```sql
SELECT 
    product.v2ProductName AS other_purchased_products
    , SUM(productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
WHERE 
    product.productRevenue is not null
    AND product.v2ProductName != "YouTube Men's Vintage Henley"
    AND fullVisitorId IN 
        (SELECT fullVisitorId 
         FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
            UNNEST (hits) hits,
            UNNEST (hits.product) product
         WHERE 
            productRevenue is not null
            AND product.v2ProductName = "YouTube Men's Vintage Henley")
GROUP BY other_purchased_products
ORDER BY quantity DESC;
```
##### Result set:
|other_purchased_products	                      |quantity|
|-------------------------------------------------|--------|
|Google Sunglasses	                              |20      |
|Google Women's Vintage Hero Tee Black	          |7       |
|SPF-15 Slim & Slender Lip Balm	                  |6       |
|Google Women's Short Sleeve Hero Tee Red Heather |4       |

***
#### 8. Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
- hits.eCommerceAction.action_type = '2' is view product page; hits.eCommerceAction.action_type = '3' is add to cart; hits.eCommerceAction.action_type = '6' is purchase
- Add condition "product.productRevenue is not null"  for purchase to calculate correctly
- To access action_type, you only need unnest hits

```sql
WITH product_view as (
    SELECT
        FORMAT_DATE("%Y%m",PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(product.v2ProductName) AS num_product_view
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) hits,
        UNNEST(product) product
    WHERE 
        _table_suffix between '0101' and '0331'
        AND eCommerceAction.action_type = '2'
    GROUP BY month
)

, addtocart as (
    SELECT
        FORMAT_DATE("%Y%m",PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(product.v2ProductName) AS num_addtocart
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) hits,
        UNNEST(product) product
    WHERE 
        _table_suffix between '0101' and '0331'
        AND eCommerceAction.action_type = '3'
    GROUP BY month
)

, purchase as (
    SELECT
        FORMAT_DATE("%Y%m",PARSE_DATE('%Y%m%d',date)) AS month
        , COUNT(product.v2ProductName) as num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) hits,
        UNNEST(product) product
    WHERE 
        _table_suffix between '0101' and '0331'
        AND eCommerceAction.action_type = '6'
        AND productRevenue is not null
    GROUP BY month
)

SELECT
    product_view.month
    , product_view.num_product_view
    , addtocart.num_addtocart
    , purchase.num_purchase
    , ROUND((num_addtocart/num_product_view)*100,2) AS add_to_cart_rate
    , ROUND((num_purchase/num_product_view)*100,2) AS purchase_rate
FROM product_view
JOIN addtocart USING(month)
JOIN purchase USING(month)
ORDER BY month;
```
##### Result set:
|month	|num_product_view	|num_addtocart	|num_purchase	|add_to_cart_rate	|purchase_rate|
|-------|-------------------|---------------|---------------|-------------------|-------------|
|201701	|25787	            |7342	        |2143	        |28.47	            |8.31         |
|201702	|21489	            |7360	        |2060	        |34.25         	    |9.59         |
|201703	|23549          	|8782	        |2977	        |37.29	            |12.64        |
