# Transaction Anomaly Detection in SQL

A small SQL project that analyses a simulated retail-banking dataset to summarise account activity and flag suspicious transactions. It uses CTEs, window functions and conditional aggregation, the techniques most commonly asked for in analytics and finance SQL roles.

## Dataset

Simulated data (no real customers), two tables:

| Table | Columns |
|---|---|
| `accounts` | `account_id`, `customer_name`, `account_type`, `opened_date` |
| `transactions` | `txn_id`, `account_id`, `txn_date`, `amount`, `txn_type`, `merchant_category` |

Deposits are positive amounts and withdrawals are negative. The data covers 3 customers and 16 transactions across September and October 2026, with two suspicious patterns planted deliberately so the queries have something to find.

## How to run

Requires SQLite 3.25+ (for window functions).

```bash
sqlite3 bank.db < sql/01_schema.sql
sqlite3 bank.db < sql/02_seed.sql
sqlite3 -header -column bank.db < sql/03_analysis.sql
```

Or paste the three files, in order, into an online SQLite editor such as SQLite Online.

## Questions answered (`sql/03_analysis.sql`)

### Q1. Monthly deposits, withdrawals and net change per customer
Conditional aggregation with `CASE WHEN` inside `SUM`, grouped by customer and month.

| customer_name | month | total_deposits | total_withdrawals | net_change |
|---|---|---|---|---|
| A. Patel | 2026-09 | 2500.0 | 4905.0 | -2405.0 |
| A. Patel | 2026-10 | 2500.0 | 155.0 | 2345.0 |
| B. Jones | 2026-09 | 1000.0 | 200.0 | 800.0 |
| B. Jones | 2026-10 | 0.0 | 150.0 | -150.0 |
| C. Smith | 2026-09 | 3000.0 | 2830.0 | 170.0 |
| C. Smith | 2026-10 | 3000.0 | 120.0 | 2880.0 |

### Q2. Running balance per account
`SUM(amount) OVER (PARTITION BY account_id ORDER BY txn_date, txn_id)`. Highlights: A. Patel's balance drops to -2,405 after a single 4,800 withdrawal on 4 Sept, and C. Smith's falls from 3,000 to 170 within one day.

### Q3. Outlier withdrawals (more than 3x the account's average withdrawal)
A CTE computes each account's average withdrawal, then joins back to the detail rows.

| txn_id | customer_name | txn_date | merchant_category | withdrawal | account_avg_withdrawal | multiple_of_avg |
|---|---|---|---|---|---|---|
| 4 | A. Patel | 2026-09-04 | electronics | 4800 | 1012.0 | 4.74 |

### Q4. Rapid-fire spending (3 or more withdrawals in one day)
`GROUP BY` account and date with `HAVING COUNT(*) >= 3`.

| customer_name | txn_date | withdrawals_that_day | total_withdrawn |
|---|---|---|---|
| C. Smith | 2026-09-02 | 3 | 2830.0 |

### Q5. Customers ranked by total spend
`RANK() OVER (ORDER BY SUM(-amount) DESC)`.

| customer_name | total_spend | spend_rank |
|---|---|---|
| A. Patel | 5060.0 | 1 |
| C. Smith | 2950.0 | 2 |
| B. Jones | 350.0 | 3 |

### Q6. Combined alert list
Two CTEs (outliers and rapid-fire) merged with `UNION ALL`, giving one row per flag with a plain-English reason.

| customer_name | reason |
|---|---|
| A. Patel | Large withdrawal: 4800 on 2026-09-04 |
| C. Smith | 3 withdrawals on 2026-09-02 |

## Key findings

- **A. Patel**: one electronics withdrawal of 4,800 is 4.7x their typical withdrawal and pushes the account into overdraft. A real system would check this against the account's overdraft limit.
- **C. Smith**: three travel withdrawals of 900, 950 and 980 on the same day, each just under 1,000. Repeated near-identical amounts just below a round threshold are a classic pattern for structuring or card testing, and would be escalated for manual review.
- **B. Jones**: no flags; low, steady activity.

## Limitations and possible extensions

- The outlier rule compares each withdrawal with an average that already includes it, which dilutes the signal. A median or a z-score against a rolling window would be more robust.
- Thresholds (3x average, 3 per day) are illustrative, not tuned on real data.
- The dataset is tiny. A natural next step is generating 10k+ rows with a Python script and checking query performance and indexes.
- SQLite-specific syntax: `strftime('%Y-%m', txn_date)` becomes `TO_CHAR(txn_date, 'YYYY-MM')` or `DATE_TRUNC('month', txn_date)` in PostgreSQL.

## Repository structure

```
transaction-anomaly-sql/
├── README.md
└── sql/
    ├── 01_schema.sql
    ├── 02_seed.sql
    └── 03_analysis.sql
```
