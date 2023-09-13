----------------------------
-- CASE STUDY: DATA BANK --
----------------------------

-- Author: Hoaithomint
-- Tool used: MySQL Server

-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;

-- 2. How many customers are allocated to each region?
SELECT
	region_name AS region
    ,COUNT(DISTINCT customer_id) AS customers
FROM data_bank.customer_nodes c
LEFT JOIN data_bank.regions r
USING (region_id)
GROUP BY region_name
ORDER BY customers DESC;

-- 3.How many days on average are customers reallocated to a different node?
SELECT  ROUND(AVG(DATEDIFF(end_date, start_date))) AS avg_day
FROM data_bank.customer_nodes
WHERE end_date <> '9999-12-31';

-- 4.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT  
	region_name AS region
    ,ROUND(AVG(DATEDIFF(end_date, start_date))) AS avg_day
FROM data_bank.customer_nodes c
JOIN data_bank.regions r
USING (region_id)
WHERE end_date <> '9999-12-31'
GROUP BY region;

-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
SELECT
	txn_type AS transaction_type
    ,COUNT(*) AS Unique_count
    ,SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY transaction_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
SELECT
	ROUND(COUNT(customer_id)/
		(SELECT COUNT(DISTINCT customer_id) 
        FROM data_bank.customer_transactions)) AS avg_total_deposit_count
    ,ROUND(AVG(txn_amount)) AS Aavg_total_amount
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit';

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
SELECT month, COUNT(customer_id)
FROM (
	SElECT 
		DATE_FORMAT(txn_date,'%m-%Y') AS month
		,customer_id
		,SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit
		,SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase
		,SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
	FROM data_bank.customer_transactions 
	GROUP BY month, customer_id
	ORDER BY month, customer_id) as count_type_txt
WHERE (deposit > 1 AND purchase = 1)
	OR (deposit > 1 AND withdrawal = 1)
GROUP BY month;
    
-- 4. What is the closing balance for each customer at the end of the month?
SELECT month
		,customer_id
        ,SUM(month_amount) OVER(PARTITION BY customer_id 
								ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
FROM (
	SElECT 
		DATE_FORMAT(txn_date,'%m-%Y') AS month
		,customer_id
		,SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS month_amount
	FROM data_bank.customer_transactions 
	GROUP BY month, customer_id
	ORDER BY customer_id, month) as sub
ORDER BY customer_id, month;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
