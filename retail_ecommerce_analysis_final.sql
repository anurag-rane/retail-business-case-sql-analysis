-- ============================================================
-- E-Commerce Retail Operations — SQL Business Case Analysis
-- Dataset: 100,000+ orders from a large-scale e-commerce
--          retailer operating in Brazil (2016–2018)
-- Author: Anurag Rane
-- Platform: Google BigQuery
-- Score: 78/80 (97.5%)
-- Tables: customers, orders, order_items, payments,
--         reviews, products, sellers, geolocation
-- ============================================================


-- ============================================================
-- SECTION I: INITIAL EXPLORATION
-- Structure & characteristics of the dataset
-- ============================================================

-- Q1.A: Data type of all columns in the customers table
-- Insight: Most columns are STRING type; zip code is INTEGER
SELECT
    column_name,
    data_type
FROM
    target_SQL.INFORMATION_SCHEMA.COLUMNS
WHERE
    table_name = 'customers';


-- Q1.B: Time range between which orders were placed
-- Insight: Brazil market was active for a little over two years
--          between the last quarters of 2016 and 2018
SELECT
    MIN(order_purchase_timestamp)   AS first_order,
    MAX(order_purchase_timestamp)   AS last_order
FROM
    target_SQL.orders;


-- Q1.C: Count of unique cities and states where orders were placed
-- Insight: A city called Itu in state SP had the highest order count
SELECT DISTINCT
    customer_state,
    customer_city,
    COUNT(*)                        AS order_count
FROM
    target_SQL.customers
GROUP BY
    customer_city, customer_state
ORDER BY
    order_count DESC;


-- ============================================================
-- SECTION II: IN-DEPTH EXPLORATION
-- Order trends, seasonality, time-of-day behaviour
-- ============================================================

-- Q2.A: Growing trend — number of orders placed per year
-- Insight: Significant increase in orders in 2017 and 2018
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp)     AS order_year,
    COUNT(*)                                        AS order_count
FROM
    target_SQL.orders
GROUP BY
    order_year
ORDER BY
    order_year;


-- Q2.B: Monthly seasonality — peak order months
-- Insight: Orders peaked between November 2017 and March 2018
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp)     AS order_year,
    EXTRACT(MONTH FROM order_purchase_timestamp)    AS order_month,
    COUNT(*)                                        AS order_count
FROM
    target_SQL.orders
GROUP BY
    order_year, order_month
ORDER BY
    order_year, order_month;


-- Q2.C: Time of day when Brazilian customers place most orders
-- Dawn: 0-6 | Morning: 7-12 | Afternoon: 13-18 | Night: 19-23
-- Insight: Customers mainly prefer ordering in the Afternoon
SELECT
    CASE
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0  AND 6  THEN 'Dawn'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7  AND 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
    END                             AS time_of_day,
    COUNT(*)                        AS order_count
FROM
    target_SQL.orders
GROUP BY
    time_of_day
ORDER BY
    order_count DESC;


-- ============================================================
-- SECTION III: EVOLUTION OF E-COMMERCE IN BRAZIL
-- State-level order distribution and customer spread
-- ============================================================

-- Q3.A: Month on month orders placed in each state
-- Insight: States MG, RJ, SP had the highest order counts
--          throughout both years, particularly in Q4
SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp)   AS order_year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp)  AS order_month,
    c.customer_state,
    COUNT(*)                                        AS order_count
FROM
    target_SQL.orders o
JOIN
    target_SQL.customers c
ON
    o.customer_id = c.customer_id
GROUP BY
    order_year, order_month, customer_state
ORDER BY
    order_year, order_month, customer_state;


-- Q3.B: Customer distribution across all states
-- Insight: SP has the highest customer count; RR has the lowest
SELECT
    customer_state,
    COUNT(*)                        AS customer_count
FROM
    target_SQL.customers
GROUP BY
    customer_state
ORDER BY
    customer_count DESC;


-- ============================================================
-- SECTION IV: IMPACT ON ECONOMY
-- Revenue, freight and money movement analysis
-- ============================================================

-- Q4.A: % increase in cost of orders from 2017 to 2018 (Jan–Aug)
-- Correct answer: 136.97% increase
-- Note: Query below corrects the CTE logic from the original submission
--       Original used window function which caused aggregation mismatch
WITH yearly_cost AS (
    SELECT
        EXTRACT(YEAR FROM o.order_purchase_timestamp)   AS order_year,
        SUM(p.payment_value)                            AS total_cost
    FROM
        target_SQL.orders o
    JOIN
        target_SQL.payments p
    ON
        o.order_id = p.order_id
    WHERE
        EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
        AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY
        order_year
)
SELECT
    MAX(CASE WHEN order_year = 2017 THEN total_cost END)    AS cost_2017,
    MAX(CASE WHEN order_year = 2018 THEN total_cost END)    AS cost_2018,
    ROUND(
        (MAX(CASE WHEN order_year = 2018 THEN total_cost END) -
         MAX(CASE WHEN order_year = 2017 THEN total_cost END)) /
        MAX(CASE WHEN order_year = 2017 THEN total_cost END) * 100
    , 2)                                                    AS pct_increase
FROM
    yearly_cost;


-- Q4.B: Total and average order price for each state
-- Insight: SP has the highest total order price; RR has the lowest
SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2)         AS total_order_price,
    ROUND(AVG(oi.price), 2)         AS avg_order_price
FROM
    target_SQL.customers c
JOIN
    target_SQL.orders o
ON
    c.customer_id = o.customer_id
JOIN
    target_SQL.order_items oi
ON
    o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_order_price DESC;


-- Q4.C: Total and average freight value for each state
-- Insight: Freight value totals mirror order price totals by state —
--          high-volume states also incur the highest freight costs
SELECT
    c.customer_state,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_value
FROM
    target_SQL.customers c
JOIN
    target_SQL.orders o
ON
    c.customer_id = o.customer_id
JOIN
    target_SQL.order_items oi
ON
    o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_freight_value DESC;


-- ============================================================
-- SECTION V: SALES, FREIGHT AND DELIVERY TIME ANALYSIS
-- ============================================================

-- Q5.A: Days to deliver each order + deviation from estimated date
-- Insight: Longest delivery was 209 days — 181 days beyond estimate
SELECT
    order_id,
    DATE_DIFF(order_delivered_customer_date,
              order_purchase_timestamp, DAY)        AS time_to_deliver,
    DATE_DIFF(order_delivered_customer_date,
              order_estimated_delivery_date, DAY)   AS diff_estimated_delivery
    -- Negative = delivered earlier than estimated (good)
    -- Positive = delivered later than estimated (bad)
FROM
    target_SQL.orders
ORDER BY
    time_to_deliver DESC;


-- Q5.B: Top 5 states with highest AND lowest average freight value
-- Insight: RR has the highest avg freight; SP has the lowest
WITH state_avg_freight AS (
    SELECT
        c.customer_state,
        ROUND(AVG(oi.freight_value), 2)     AS avg_freight_value
    FROM
        target_SQL.customers c
    JOIN
        target_SQL.orders o ON c.customer_id = o.customer_id
    JOIN
        target_SQL.order_items oi ON o.order_id = oi.order_id
    GROUP BY
        c.customer_state
)
(
    SELECT customer_state, avg_freight_value, 'Highest' AS category
    FROM state_avg_freight
    ORDER BY avg_freight_value DESC
    LIMIT 5
)
UNION ALL
(
    SELECT customer_state, avg_freight_value, 'Lowest' AS category
    FROM state_avg_freight
    ORDER BY avg_freight_value ASC
    LIMIT 5
);


-- Q5.C: Top 5 states with highest AND lowest average delivery time
-- Insight: RR has the highest avg delivery time; SP has the lowest
WITH state_avg_delivery AS (
    SELECT
        c.customer_state,
        ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date,
                            o.order_purchase_timestamp, DAY)), 2) AS avg_delivery_days
    FROM
        target_SQL.customers c
    JOIN
        target_SQL.orders o ON c.customer_id = o.customer_id
    WHERE
        o.order_delivered_customer_date IS NOT NULL
    GROUP BY
        c.customer_state
)
(
    SELECT customer_state, avg_delivery_days, 'Slowest' AS category
    FROM state_avg_delivery
    ORDER BY avg_delivery_days DESC
    LIMIT 5
)
UNION ALL
(
    SELECT customer_state, avg_delivery_days, 'Fastest' AS category
    FROM state_avg_delivery
    ORDER BY avg_delivery_days ASC
    LIMIT 5
);


-- Q5.D: Top 5 states where delivery is fastest vs estimated date
-- Insight: AC has the highest positive difference between
--          estimated and actual delivery — consistently ahead of schedule
WITH delivery_speed AS (
    SELECT
        c.customer_state,
        ROUND(AVG(DATE_DIFF(o.order_estimated_delivery_date,
                            o.order_delivered_customer_date, DAY)), 2) AS avg_speed
    FROM
        target_SQL.customers c
    JOIN
        target_SQL.orders o ON c.customer_id = o.customer_id
    WHERE
        o.order_delivered_customer_date IS NOT NULL
    GROUP BY
        c.customer_state
)
SELECT
    customer_state,
    avg_speed
FROM
    delivery_speed
ORDER BY
    avg_speed DESC
LIMIT 5;


-- ============================================================
-- SECTION VI: PAYMENT ANALYSIS
-- ============================================================

-- Q6.A: Month on month orders by payment type
-- Insight: Credit card was the most used payment method
--          in every month across all years
SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp)   AS order_year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp)  AS order_month,
    p.payment_type,
    COUNT(*)                                        AS order_count
FROM
    target_SQL.orders o
JOIN
    target_SQL.payments p
ON
    o.order_id = p.order_id
GROUP BY
    order_year, order_month, payment_type
ORDER BY
    order_year, order_month, payment_type;


-- Q6.B: Orders by number of payment installments paid
-- Insight: A large number of customers relied on installments
--          to purchase products — indicating high-value purchases
SELECT
    payment_installments,
    COUNT(*)                        AS order_count
FROM
    target_SQL.payments
GROUP BY
    payment_installments
ORDER BY
    payment_installments;
