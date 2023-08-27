# CASE STUDY #1: DANNY 'S DINNER

<p align="center">
<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Image" width="450" height="450">

View the case study [here](https://8weeksqlchallenge.com/case-study-1/)

## Table Of Contents
  - [Introduction](#introduction)
  - [Problem Statement](#problem-statement)
  - [Datasets used](#datasets-used)
  - [Entity Relationship Diagram](#entity-relationship-diagram)
  - [Case Study Questions](#case-study-questions)
  - [Solution](#solution)

## Introduction

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers. He plans on using these insights to help him decide whether he should expand the existing customer loyalty program.

## Datasets used

Three key datasets for this case study
- sales: The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.
- menu: The menu table maps the product_id to the actual product_name and price of each menu item.
- members: The members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

## Entity Relationship Diagram
<img src="https://github.com/Hoaithomint/SQL/assets/141213880/e75c446d-183e-4e6e-8843-81e6cbe8c26e" alt="Image" width="450">

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

 
# Solution

#### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT 
	customer_id
	,SUM(price) AS total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;
```
##### Result set:
| customer_id | total_amount|
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

 
#### 2. How many days has each customer visited the restaurant?

```sql
SELECT 
	customer_id
	,COUNT(DISTINCT order_date) AS visit_date
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY visit_date DESC;
```
##### Result set:
| customer_id | visit_date  |
| ----------- | ----------- |
| A           | 6           |
| B           | 4           |
| C           | 2           |


#### 3. What was the first item from the menu purchased by each customer?

```sql
SELECT 
	customer_id
	,GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS first_item_purchased
FROM (
	SELECT customer_id, order_date, product_name
	,RANK() OVER(PARTITION BY customer_id 
				ORDER BY order_date ASC) AS ranking
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id) AS sub
WHERE ranking = 1
GROUP BY customer_id
ORDER BY customer_id;
```
##### Result set:
| customer_id | first_item_purchased  |
| ----------- | --------------------- |
| A           | curry, sushi          |
| B           | curry                 |
| C           | ramen                 |


#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT
	product_name AS most_purchased_item
	,COUNT(order_date) AS time_purchased
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY time_purchased DESC
LIMIT 1;
```
##### Result set:
| most_purchased_item | time_purchased  |
| ------------------- | ----------------|
| ramen               | 8               |


#### 5. Which item was the most popular for each customer?

```sql
SELECT 
	customer_id
	,GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS most_popular_purchased_item
FROM (
	SELECT
		customer_id
	    	,product_name
    		,COUNT(product_name) AS time_purchased
   		,RANK() OVER(PARTITION BY customer_id ORDER BY count(product_name) DESC) AS ranking
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	GROUP BY customer_id, product_name) AS sub
WHERE ranking = 1
GROUP BY customer_id;
```
##### Result set:
| customer_id | most_popular_purchased_item  |
| ----------- | ---------------------------- |
| A           | ramen                        |
| B           | curry,ramen, sushi           |
| C           | ramen                        |


#### 6. Which item was purchased first by the customer after they became a member?

```sql
SELECT 
	customer_id
	,product_name AS first_purchased_item
FROM (
	SELECT
		s.customer_id
    		,order_date
    		,product_name
    		,join_date
    		,RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS ranking
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members m2
	ON s.customer_id = m2.customer_id
	WHERE order_date >= join_date) AS sub
WHERE ranking = 1;
```
##### Result set:
| customer_id | first_purchased_item  |
| ----------- | --------------------- |
| A           | curry                 |
| B           | sushi                 |


#### 7. Which item was purchased just before the customer became a member?

```sql
SELECT 
	customer_id
    	,GROUP_CONCAT(DISTINCT product_name ORDER BY product_name) AS first_purchased_item
FROM (
	SELECT
		s.customer_id
    		,order_date
    		,product_name
    		,join_date
    		,RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS ranking
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members m2
	ON s.customer_id = m2.customer_id
	WHERE order_date < join_date) AS sub
WHERE ranking = 1
GROUP BY customer_id;
```
##### Result set:
| customer_id | first_purchased_item  |
| ----------- | --------------------- |
| A           | curry, sushi          |
| B           | sushi                 |


#### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT
	s.customer_id
  	,COUNT(product_name) AS total_items
    ,SUM(price) AS total_amount_spent
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members m2
ON s.customer_id = m2.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id;
```
##### Result set:
| customer_id | total_items  | total_amount_spent|
| ----------- | -------------|-------------------|
| A           | 2            |25
| B           | 3            |40


#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
SELECT 
	s.customer_id
    	,SUM(CASE WHEN product_name = 'sushi' THEN price*20 ELSE price*10 END) AS total_point
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members m2
ON s.customer_id = m2.customer_id
WHERE order_date >= join_date
GROUP BY customer_id
ORDER BY total_point DESC;
```
##### Result set:
| customer_id | total_point  |
| ----------- | ------------ |
| A           | 510          |
| B           | 440          |


#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
WITH program_week AS (
	SELECT 
		customer_id
		,join_date
		,DATE_ADD(join_date, INTERVAL 6 day) AS last_day_of_program
	FROM dannys_diner.members)
    
SELECT 
	s.customer_id
    	,SUM(CASE 
		WHEN order_date BETWEEN join_date AND last_day_of_program THEN price*20
		WHEN order_date NOT BETWEEN join_date AND last_day_of_program
			AND product_name = 'sushi' THEN price*20 ELSE price*10 END) AS total_point
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
LEFT JOIN program_week p
USING(customer_id)
WHERE customer_id IN ('A','B')
	AND order_date <= '2021-01-31'
    	AND order_date >=join_date
GROUP BY customer_id
ORDER BY total_point DESC;
```
##### Result set:
| customer_id | total_point  |
| ----------- | ------------ |
| A           | 1020         |
| B           | 320          |

***

