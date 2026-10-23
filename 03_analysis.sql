-- 03_analysis.sql
-- Transaction anomaly analysis. Each query is labelled Q1-Q6.
-- Convention: deposits are positive, withdrawals are negative.

-- Q1. Monthly summary per customer: deposits, withdrawals, net change
--     Skills: JOIN, GROUP BY, conditional aggregation (CASE WHEN)
SELECT
  a.customer_name,
  strftime('%Y-%m', t.txn_date)                                   AS month,
  ROUND(SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END), 2)  AS total_deposits,
  ROUND(-SUM(CASE WHEN t.amount < 0 THEN t.amount ELSE 0 END), 2) AS total_withdrawals,
  ROUND(SUM(t.amount), 2)                                         AS net_change
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
GROUP BY a.customer_name, strftime('%Y-%m', t.txn_date)
ORDER BY a.customer_name, month;

-- Q2. Running balance per account
--     Skills: window function SUM() OVER (PARTITION BY ... ORDER BY ...)
SELECT
  a.customer_name,
  t.txn_id,
  t.txn_date,
  t.amount,
  ROUND(SUM(t.amount) OVER (
          PARTITION BY t.account_id
          ORDER BY t.txn_date, t.txn_id), 2) AS running_balance
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
ORDER BY a.customer_name, t.txn_date, t.txn_id;

-- Q3. Outlier withdrawals: more than 3x that account's average withdrawal
--     Skills: CTE, aggregation, join back to detail rows
WITH withdrawal_stats AS (
  SELECT account_id, AVG(-amount) AS avg_withdrawal
  FROM transactions
  WHERE amount < 0
  GROUP BY account_id
)
SELECT
  t.txn_id,
  a.customer_name,
  t.txn_date,
  t.merchant_category,
  -t.amount                                  AS withdrawal,
  ROUND(s.avg_withdrawal, 2)                 AS account_avg_withdrawal,
  ROUND(-t.amount / s.avg_withdrawal, 2)     AS multiple_of_avg
FROM transactions t
JOIN withdrawal_stats s ON s.account_id = t.account_id
JOIN accounts a         ON a.account_id = t.account_id
WHERE t.amount < 0
  AND -t.amount > 3 * s.avg_withdrawal
ORDER BY multiple_of_avg DESC;

-- Q4. Rapid-fire spending: 3 or more withdrawals on the same day
--     Skills: GROUP BY multiple columns, HAVING
SELECT
  a.customer_name,
  t.txn_date,
  COUNT(*)              AS withdrawals_that_day,
  ROUND(-SUM(t.amount), 2) AS total_withdrawn
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
WHERE t.amount < 0
GROUP BY t.account_id, a.customer_name, t.txn_date
HAVING COUNT(*) >= 3
ORDER BY total_withdrawn DESC;

-- Q5. Rank customers by total spend
--     Skills: RANK() window function over an aggregate
SELECT
  a.customer_name,
  ROUND(-SUM(t.amount), 2)                      AS total_spend,
  RANK() OVER (ORDER BY SUM(-t.amount) DESC)    AS spend_rank
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
WHERE t.amount < 0
GROUP BY a.account_id, a.customer_name
ORDER BY spend_rank;

-- Q6. Combined alert list: every account flagged by either rule, with the reason
--     Skills: multiple CTEs, UNION ALL
WITH withdrawal_stats AS (
  SELECT account_id, AVG(-amount) AS avg_withdrawal
  FROM transactions WHERE amount < 0 GROUP BY account_id
),
outliers AS (
  SELECT t.account_id,
         'Large withdrawal: ' || CAST(-t.amount AS INTEGER) || ' on ' || t.txn_date AS reason
  FROM transactions t
  JOIN withdrawal_stats s ON s.account_id = t.account_id
  WHERE t.amount < 0 AND -t.amount > 3 * s.avg_withdrawal
),
rapid_fire AS (
  SELECT account_id,
         COUNT(*) || ' withdrawals on ' || txn_date AS reason
  FROM transactions
  WHERE amount < 0
  GROUP BY account_id, txn_date
  HAVING COUNT(*) >= 3
)
SELECT a.customer_name, f.reason
FROM (SELECT * FROM outliers UNION ALL SELECT * FROM rapid_fire) f
JOIN accounts a ON a.account_id = f.account_id
ORDER BY a.customer_name;
