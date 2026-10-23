-- 01_schema.sql
-- Simulated retail banking dataset: accounts and their transactions.
-- Written for SQLite; see README for notes on porting to PostgreSQL.

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
  account_id    INTEGER PRIMARY KEY,
  customer_name TEXT NOT NULL,
  account_type  TEXT NOT NULL,   -- 'current' or 'savings'
  opened_date   DATE NOT NULL
);

CREATE TABLE transactions (
  txn_id            INTEGER PRIMARY KEY,
  account_id        INTEGER NOT NULL REFERENCES accounts(account_id),
  txn_date          DATE NOT NULL,
  amount            DECIMAL(10,2) NOT NULL,  -- positive = money in, negative = money out
  txn_type          TEXT NOT NULL,           -- 'deposit', 'withdrawal'
  merchant_category TEXT
);
