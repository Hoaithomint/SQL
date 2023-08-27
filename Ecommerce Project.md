# ECOMMERCE PROJECT

- Table Schema [here](https://support.google.com/analytics/answer/3437719?hl=en)
- Format Element [here](https://cloud.google.com/bigquery/docs/reference/standard-sql/format-elements)
- Origin code on BigQuery [here](https://console.cloud.google.com/bigquery?sq=419516868446:ee029ce0d51b402aa4de14f41b7a2950)

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
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month
    , SUM(totals.visits) AS total_visits
    , SUM(totals.pageviews) AS total_pageviews
    , SUM(totals.transactions) AS total_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;
```

#### 2. Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)

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

#### 4. Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017

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

#### 5. Average number of transactions per user that made a purchase in July 2017

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

#### 6. Average amount of money spent per session. Only include purchaser data in July 2017	

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

#### 7. Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017	

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

#### 8. Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.

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
        FORMAT_DATE("%Y%m",PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(product.v2ProductName) as num_purchase
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
    product_view.month,
    product_view.num_product_view,
    addtocart.num_addtocart,
    purchase.num_purchase,
    ROUND((num_addtocart/num_product_view)*100,2) AS add_to_cart_rate,
    ROUND((num_purchase/num_product_view)*100,2) AS purchase_rate
FROM product_view
JOIN addtocart USING(month)
JOIN purchase USING(month)
ORDER BY month;
```
