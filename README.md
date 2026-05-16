# E-Commerce Retail Operations — SQL Business Case Analysis

## Business Problem

An e-commerce retailer operating in Brazil processed 100,000+ orders between 2016 and 2018 across 8 interconnected datasets. As a data analyst on the team, the objective was to extract actionable insights across six business domains:

- **Order trends** — Is the business growing month over month?
- **Customer behaviour** — When and where do customers order?
- **Economic impact** — How is revenue and freight distributed across states?
- **Delivery performance** — How fast are orders delivered vs estimates?
- **Payment patterns** — What payment methods do customers prefer?

**Score: 78/80 (97.5%) — evaluated by Scaler Institute**

---

## Dataset

- **Source:** Academic business case — e-commerce retail operations in Brazil (2016–2018)
- **Volume:** 100,000+ orders across 8 tables
- **Platform:** Google BigQuery
- **Tables:** `customers`, `orders`, `order_items`, `payments`, `reviews`, `products`, `sellers`, `geolocation`

### Schema

```
customers ──── orders ──── order_items ──── products
                 │                │
              payments          sellers
                 │
              reviews
```

| Table | Key Columns |
|-------|------------|
| customers | customer_id, customer_unique_id, customer_city, customer_state |
| orders | order_id, customer_id, order_status, order_purchase_timestamp, order_delivered_customer_date, order_estimated_delivery_date |
| order_items | order_id, product_id, seller_id, price, freight_value |
| payments | order_id, payment_type, payment_installments, payment_value |
| reviews | order_id, review_score, review_comment_message |
| products | product_id, product_category_name, product_weight_g |
| sellers | seller_id, seller_city, seller_state |
| geolocation | geolocation_zip_code_prefix, geolocation_lat, geolocation_lng |

---

## SQL Analysis — 6 Sections, 15 Queries

### Section I — Initial Exploration (10/10)
- Column data types via `INFORMATION_SCHEMA.COLUMNS`
- First and last order timestamps — time range of the dataset
- Unique cities and states where orders were placed

### Section II — In-Depth Exploration (10/10)
- Year-over-year order volume growth
- Monthly seasonality — identifying peak order months
- Time-of-day ordering behaviour using `CASE WHEN` bucketing (Dawn / Morning / Afternoon / Night)

### Section III — E-Commerce Evolution by State (10/10)
- Month-on-month orders per state — multi-table JOIN with date extraction
- Customer distribution across all Brazilian states

### Section IV — Economic Impact (8/10)
- % increase in order revenue from 2017 → 2018 (Jan–Aug) — CTE with conditional aggregation
- Total and average order price per state — 3-table JOIN
- Total and average freight value per state

### Section V — Delivery & Freight Analysis (10/10)
- Delivery time + estimated vs actual deviation in a single query using `DATE_DIFF`
- Top 5 / bottom 5 states by average freight value — CTE + `UNION ALL`
- Top 5 / bottom 5 states by average delivery time — CTE + `UNION ALL`
- Top 5 states with fastest delivery relative to estimated date

### Section VI — Payment Analysis (10/10)
- Month-on-month orders by payment type
- Order distribution by number of payment installments

---

## Key Findings

- **Afternoon is peak ordering time** — majority of orders placed between 13:00–18:00; marketing campaigns should target this window
- **Orders grew significantly YoY** — strong growth from 2016 through 2018, with a 136.97% revenue increase from 2017 to 2018 (Jan–Aug)
- **Peak seasonality: Nov 2017 – Mar 2018** — holiday season drives a sharp spike in order volumes
- **SP dominates everything** — highest customer count, order volume, revenue, and freight — São Paulo is the business centre of gravity
- **RR has the highest freight cost and longest delivery time** — remote northern states face logistics challenges
- **AC delivers fastest vs estimate** — some states consistently beat their estimated delivery dates
- **Longest single delivery: 209 days** — 181 days beyond the estimated date, indicating severe outlier cases in logistics
- **Credit card dominates payments** in every month across both years; a significant portion of customers use installments — indicating high-value purchase behaviour

---

## Actionable Recommendations

1. **Fix logistics in North/Northeast Brazil** — RR and neighbouring states have the highest freight costs and delivery times. Regional warehouse expansion or seller onboarding closer to demand centres would reduce both.

2. **Launch afternoon promotions** — peak ordering is 13:00–18:00. Flash sales, push notifications, and discounts timed to this window will maximise conversion.

3. **Investigate delivery outliers** — a 209-day delivery is a severe failure case. An alerting system for orders exceeding 30 days would allow proactive intervention.

4. **Double down on SP** — São Paulo drives disproportionate revenue. Prioritising seller acquisition, inventory depth, and faster fulfilment in SP will compound returns.

5. **Incentivise installment plans** — a large customer base already uses EMI. Offering lower interest rates or cashback on installment purchases could increase average order value.

6. **Replicate fast-delivery logistics from AC** — states that consistently beat estimated delivery dates have logistics models worth studying and scaling to slower regions.

---

## SQL Techniques Demonstrated

- Multi-table `JOIN` (up to 3 tables in a single query)
- `EXTRACT(YEAR/MONTH/HOUR FROM timestamp)` for time-series decomposition
- `CASE WHEN` for conditional bucketing (time-of-day categorisation)
- `DATE_DIFF` for delivery time and deviation calculations
- `CTE` (Common Table Expressions) for modular query structure
- `UNION ALL` for combining top/bottom rankings in a single result
- `INFORMATION_SCHEMA.COLUMNS` for schema introspection
- `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` aggregations
- `NULLIF` to prevent division-by-zero in percentage calculations
- Conditional aggregation using `CASE WHEN` inside `SUM`

---

## Files

```
retail-business-case-sql-analysis/
│
├── README.md
└── retail_ecommerce_analysis.sql    ← All 15 queries across 6 sections
```

---

## About

This SQL business case was completed as part of an MSc AI & ML programme (Scaler/Woolf University), analysing e-commerce retail operations data to extract business insights across customer behaviour, delivery performance, revenue trends, and payment patterns. Scored 78/80 on evaluation.

**Author:** Anurag Rane
**LinkedIn:** [linkedin.com/in/anurag-rane-a2743aa9](https://linkedin.com/in/anurag-rane-a2743aa9)
**GitHub:** [github.com/anurag-rane](https://github.com/anurag-rane)
