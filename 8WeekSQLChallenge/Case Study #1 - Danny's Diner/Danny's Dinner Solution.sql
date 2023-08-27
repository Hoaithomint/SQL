-- CASE STUDY #1: DANNY'S DINNER

-- Author: Hoaithomint
-- Tool used: MySQL Server

/* --------------------------------
   Case Study Questions & Solutions
   --------------------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	customer_id
    ,SUM(price) AS total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id
    ,COUNT(DISTINCT order_date) AS visit_date
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY visit_date DESC;

-- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	product_name AS most_purchased_item
	,COUNT(order_date) AS time_purchased
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY time_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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

-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
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

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
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

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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
