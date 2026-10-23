-- 02_seed.sql
-- Small simulated dataset (3 customers, 16 transactions across Sept and Oct 2026).
-- Deliberately includes two "suspicious" patterns for the analysis to find:
--   1. A very large one-off withdrawal (account 1, txn 4)
--   2. Three near-identical withdrawals in one day (account 3, txns 8-10)

INSERT INTO accounts VALUES
(1, 'A. Patel', 'current', '2022-03-01'),
(2, 'B. Jones', 'savings', '2021-07-15'),
(3, 'C. Smith', 'current', '2023-01-10');

INSERT INTO transactions VALUES
(1,  1, '2026-09-01',  2500.00, 'deposit',    'salary'),
(2,  1, '2026-09-02',   -60.00, 'withdrawal', 'groceries'),
(3,  1, '2026-09-03',   -45.00, 'withdrawal', 'transport'),
(4,  1, '2026-09-04', -4800.00, 'withdrawal', 'electronics'),
(5,  2, '2026-09-01',  1000.00, 'deposit',    'transfer_in'),
(6,  2, '2026-09-05',  -200.00, 'withdrawal', 'utilities'),
(7,  3, '2026-09-02',  3000.00, 'deposit',    'salary'),
(8,  3, '2026-09-02',  -900.00, 'withdrawal', 'travel'),
(9,  3, '2026-09-02',  -950.00, 'withdrawal', 'travel'),
(10, 3, '2026-09-02',  -980.00, 'withdrawal', 'travel'),
(11, 1, '2026-10-01',  2500.00, 'deposit',    'salary'),
(12, 1, '2026-10-03',   -85.00, 'withdrawal', 'groceries'),
(13, 2, '2026-10-02',  -150.00, 'withdrawal', 'utilities'),
(14, 3, '2026-10-02',  3000.00, 'deposit',    'salary'),
(15, 3, '2026-10-05',  -120.00, 'withdrawal', 'groceries'),
(16, 1, '2026-10-06',   -70.00, 'withdrawal', 'transport');
