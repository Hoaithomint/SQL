# CASE STUDY: DATA BANK
<p align="center">
<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" alt="Image" width="450" height="450"> 

Table Of Contents
-
  - [Introduction](#introduction)
  - [Problem Statement](#problem-statement)
  - [Dataset](#dataset)
  - [Entity Relationship Diagram](#entity-relationship-diagram)
  - [Case Study Questions](#case-study-questions)
  - [Solution](#solution)
  
Introduction
-

There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

Problem Statement
-
The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

Dataset
-

The Data Bank team have prepared a data model for this case study as well as a few example rows from the complete dataset below to get you familiar with their tables.

- **Table 1: Regions**

Just like popular cryptocurrency platforms - Data Bank is also run off a network of nodes where both money and data is stored across the globe. In a traditional banking sense - you can think of these nodes as bank branches or stores that exist around the world.

This regions table contains the region_id and their respective region_name values

|region_id	|region_name|
|-----------|-----------|
|1	        |Africa     |      
|2	        |America    |
|3	        |Asia       |
|4	        |Europe     |
|5	        |Oceania    |

- **Table 2: Customer Nodes**

Customers are randomly distributed across the nodes according to their region - this also specifies exactly which node contains both their cash and data.

This random distribution changes frequently to reduce the risk of hackers getting into Data Bank’s system and stealing customer’s money and data!

Below is a sample of the top 10 rows of the data_bank.customer_nodes

|customer_id	|region_id	  |node_id	    |start_date	  |end_date  |
|-------------|-------------|-------------|-------------|----------|
|1	          |3	          |4	          |2020-01-02	  |2020-01-03|
|2	          |3	          |5	          |2020-01-03  	|2020-01-17|
|3	          |5	          |4	          |2020-01-27	  |2020-02-18|
|4	          |5	          |4	          |2020-01-07	  |2020-01-19|
|5	          |3	          |3	          |2020-01-15	  |2020-01-23|
|6	          |1	          |1	          |2020-01-11	  |2020-02-06|
|7	          |2	          |5	          |2020-01-20	  |2020-02-04|
|8	          |1	          |2	          |2020-01-15	  |2020-01-28|
|9	          |4	          |5	          |2020-01-21  	|2020-01-25|
|10	          |3	          |4	          |2020-01-13	  |2020-01-14|

- **Table 3: Customer Transactions**

This table stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

|customer_id|	txn_date	|txn_type	|txn_amount|
|-----------|-----------|---------|----------|
|429	      |2020-01-21	|deposit	|82        |
|155	      |2020-01-10	|deposit	|712       |
|398	      |2020-01-01	|deposit	|196       |
|255	      |2020-01-14	|deposit	|563       |
|185	      |2020-01-29	|deposit	|626       |
|309	      |2020-01-13	|deposit	|995       |
|312	      |2020-01-20	|deposit	|485       |
|376        |2020-01-03	|deposit	|706       |
|188	      |2020-01-13	|deposit	|601       |
|138	      |2020-01-11	|deposit	|520       |

Entity Relationship Diagram
-
<img width="669" alt="image" src="https://github.com/Hoaithomint/SQL/assets/141213880/e074f0df-c0dc-4036-a528-cf1bbe49c4ad">

Case Study Questions
--

The following case study questions include some general data exploration analysis for the nodes and transactions before diving right into the core business questions and finishes with a challenging final request!

**A. Customer Nodes Exploration**

1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

**B. Customer Transactions**

1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?

Solution
-

### A. Customer Nodes Exploration

#### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;
```
##### Result set:
|unique_nodes|
|------------|
|5           |

#### 2. How many customers are allocated to each region?
```sql
SELECT
    region_name AS region
    ,COUNT(DISTINCT customer_id) AS customers
FROM data_bank.customer_nodes c
LEFT JOIN data_bank.regions r
USING (region_id)
GROUP BY region_name
ORDER BY customers DESC;
```
##### Result set:
|region	  |customers |
|---------|----------|
|Australia|	110      |
|America	|105       |
|Africa	  |102       |
|Asia	    |95        |
|Europe	  |88        |


#### 3.How many days on average are customers reallocated to a different node?
```sql
SELECT  ROUND(AVG(DATEDIFF(end_date, start_date))) AS avg_day
FROM data_bank.customer_nodes
WHERE end_date <> '9999-12-31';
```
##### Result set:
|avg_day|
|-------|
|15     |


#### 4.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
SELECT
    region_name AS region
    ,ROUND(AVG(DATEDIFF(end_date, start_date))) AS avg_day
FROM data_bank.customer_nodes c
JOIN data_bank.regions r
USING (region_id)
WHERE end_date <> '9999-12-31'
GROUP BY region;
```
##### Result set:
|region	    |avg_day|
|-----------|-------|
|Africa	    |15     |
|Europe	    |15     |
|Australia	|15     |
|America	  |15     |
|Asia	      |14     |

### B. Customer Transactions

#### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT
    txn_type AS transaction_type
    ,COUNT(*) AS unique_count
    ,SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY transaction_type;
```
##### Result set:
|transaction_type	|unique_count	|total_amount|
|-----------------|-------------|------------|
|deposit	        |2671	        |1359168     |
|withdrawal	      |1580	        |793003      |
|purchase	        |1617	        |806537      |


#### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
SELECT
    ROUND(COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id)
                              FROM data_bank.customer_transactions)) AS avg_total_deposit_count
    ,ROUND(AVG(txn_amount)) AS avg_total_amount
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit';
```
##### Result set:
|avg_total_deposit_count|avg_total_amount|
|-----------------------|----------------|
|5                      |509             |

#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
WITH count_type_txt AS (
    SELECT
        DATE_FORMAT(txn_date,'%m-%Y') AS month
        ,customer_id
        ,SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit
        ,SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase
        ,SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
    FROM data_bank.customer_transactions
    GROUP BY month, customer_id
    ORDER BY month, customer_id
)
SELECT
    month
    ,COUNT(customer_id) AS no_customer
FROM count_type_txt	
WHERE (deposit > 1 AND purchase = 1)
    OR (deposit > 1 AND withdrawal = 1)
GROUP BY month;
```
##### Result set:
|month	|no_customer|
|-------|-----------|
|01-2020|	115       |
|02-2020|	108       |
|03-2020|	113       |
|04-2020|	50        |

    
#### 4. What is the closing balance for each customer at the end of the month?
```sql
WITH month_amount AS (
    SELECT
        DATE_FORMAT(txn_date,'%m-%Y') AS month
        ,customer_id
        ,SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS month_amount
    FROM data_bank.customer_transactions
    GROUP BY month, customer_id
    ORDER BY customer_id, month
)
SELECT
    month
    ,customer_id
    ,SUM(month_amount) OVER(PARTITION BY customer_id
                            ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
FROM month_amount	
ORDER BY customer_id, month;
```
##### Result set:
|month  |	customer_id	|closing_balance|
|-------|-------------|---------------|
|01-2020|	1	          |312            |
|03-2020|	1	          |-640           |
|01-2020|	2	          |549            |
|03-2020|	2	          |610            |
|01-2020|	3	          |144            |
|02-2020|	3	          |-821           |
|03-2020|	3	          |-1222          |
|04-2020|	3	          |-729           |
|01-2020|	4	          |848            |
|03-2020|	4	          |655            |
|01-2020|	5	          |954            |
|03-2020| 5	          |-1923          |
|04-2020|	5	          |-2413          |  
|01-2020|	6	          |733            |
|02-2020|	6	          |-52            |
|03-2020|	6	          |340            |
|01-2020|	7	          |964            |
|02-2020|	7	          |3173           |
|03-2020|	7	          |2533           |
|04-2020|	7	          |2623           |
|01-2020|	8	          |587            |
|...    |...          |...            |  

#### 5. What is the percentage of customers who increase their closing balance by more than 5%?

