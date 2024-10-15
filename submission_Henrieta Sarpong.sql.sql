/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  USE VEHDB;
  
  SHOW TABLES;
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

SELECT STATE, 
       COUNT(customer_id) AS NUMBER_CUSTOMERS
FROM customer_t
GROUP BY STATE
ORDER BY COUNT(customer_id) DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/

-- This query calculates the average rating per quarter for customer feedback on orders
-- First, I create a temporary table with a rating column based on the customer_feedback value 
WITH Customer_feedback AS
(SELECT *,
        CASE
            WHEN customer_feedback = 'Very Bad' THEN 1
            WHEN customer_feedback = 'Bad' THEN 2
            WHEN customer_feedback = 'Okay' THEN 3
            WHEN customer_feedback = 'Good' THEN 4
            WHEN customer_feedback = 'Very Good' THEN 5
        END AS rating
FROM order_t)

-- Then, I calculate the average rating for each quarter using the temporary table
SELECT
    quarter_number AS QUARTER,
    ROUND (AVG(rating), 2) AS AVERAGE_RATING
FROM Customer_feedback

GROUP BY QUARTER
ORDER BY QUARTER;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/

-- This query calculates the percentage of customer feedback for each quarter, broken down by feedback type
-- First, I create a temporary table to count the number of feedback entries for each quarter and feedback type
WITH feedback_counts AS (
  SELECT 
    quarter_number,
    customer_feedback,
    COUNT(*) AS feedback_count,
    SUM(COUNT(*)) OVER (PARTITION BY quarter_number) AS total_feedback_count
  FROM 
    order_t 
  GROUP BY 
    quarter_number, 
    customer_feedback
),

-- Then, I calculate the feedback percentage for each quarter and feedback type using the counts from the previous table
feedback_percentages AS (
  SELECT 
    quarter_number,
    customer_feedback,
    ROUND((feedback_count / total_feedback_count) * 100, 2) AS feedback_percentage
  FROM 
    feedback_counts 
)
SELECT 
  quarter_number AS QUARTER,
  SUM(CASE WHEN customer_feedback = 'very bad' THEN feedback_percentage ELSE 0 END) AS VERY_BAD_PERCENTAGE,
  SUM(CASE WHEN customer_feedback = 'bad' THEN feedback_percentage ELSE 0 END) AS BAD_PERCENTAGE,
  SUM(CASE WHEN customer_feedback = 'okay' THEN feedback_percentage ELSE 0 END) AS OKAY_PERCENTAGE,
  SUM(CASE WHEN customer_feedback = 'good' THEN feedback_percentage ELSE 0 END) AS GOOD_PERCENTAGE,
  SUM(CASE WHEN customer_feedback = 'very good' THEN feedback_percentage ELSE 0 END) AS VERY_GOOD_PERCENTAGE
FROM 
  feedback_percentages 
GROUP BY 
  QUARTER
ORDER BY 
  QUARTER;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT P.VEHICLE_MAKER, 
        COUNT(O.customer_id) AS NUMBER_CUSTOMERS
FROM product_t as p

      INNER JOIN order_t AS O
      ON P.product_id = O.product_id
            
GROUP BY P.VEHICLE_MAKER
ORDER BY NUMBER_CUSTOMERS DESC
LIMIT 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

SELECT * FROM

(SELECT *,
        RANK() OVER (PARTITION BY STATE ORDER BY NUMBER_CUSTOMERS DESC) AS RNK
FROM        
( SELECT
    C.STATE,
    P.VEHICLE_MAKER,
    COUNT(O.customer_id) AS NUMBER_CUSTOMERS
    
FROM order_t AS O

INNER JOIN product_t AS P 
ON O.product_id = P.product_id

INNER JOIN customer_t AS C 
ON O.customer_id = C.customer_id

GROUP BY C.STATE, P.VEHICLE_MAKER
ORDER BY NUMBER_CUSTOMERS DESC ) A) B

WHERE RNK = 1;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
SELECT
  quarter_number AS QUARTER, 
  COUNT(customer_id) AS NUMBER_ORDERS
FROM order_t
GROUP BY QUARTER
ORDER BY QUARTER;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
WITH quarterly_revenue AS (
  SELECT 
    quarter_number,
    ROUND(SUM(quantity * (vehicle_price - ((discount/100) * vehicle_price ))), 2) AS REVENUE
  FROM 
    order_t 
  GROUP BY 
    quarter_number
)
SELECT 
  quarter_number AS QUARTER,
  REVENUE, 
 TRUNCATE (((revenue - LAG(revenue) OVER (ORDER BY quarter_number)) / LAG(revenue) OVER (ORDER BY quarter_number)), 2) * 100 AS QoQ_CHANGE
FROM 
  quarterly_revenue 
ORDER BY 
  QUARTER;
  

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT quarter_number AS QUARTER,
				  COUNT(order_id) AS NUMBER_ORDERS,
                 ROUND (SUM(quantity *(vehicle_price - ((discount/100) * vehicle_price ))), 2) AS REVENUE
FROM order_t
GROUP BY QUARTER
ORDER BY QUARTER;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT C.CREDIT_CARD_TYPE, 
	   ROUND(AVG(discount), 2) AS AVERAGE_DISCOUNT
       
FROM customer_t AS C 
INNER JOIN order_t AS O
ON C.customer_id = O.customer_id
 
GROUP BY C.CREDIT_CARD_TYPE
ORDER BY AVERAGE_DISCOUNT;
 
 
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT QUARTER_NUMBER AS QUARTER, 
	   ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS AVG_SHIP_TIME
FROM order_t
GROUP BY QUARTER
ORDER BY QUARTER;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



