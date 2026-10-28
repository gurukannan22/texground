-- Step 3b (replacement for the PL/SQL block)
-- This query GENERATES the 3 INSERT statements using the real TRADE.FEE column list.
-- Each new fee is a copy of fee 4 (the 705.05 fee) on txn 1, with TYPE / PAYMENT_DATE / AMOUNT changed
-- and the next FEE_NUMBER.
--   row 1: 111.11  type 24  20230314  (same-day maturity  -> the fix)
--   row 2: 222.22  type 24  20231231  (future-dated maturity)
--   row 3: 333.33  type 5   20230314  (same-day NON-maturity)
WITH p AS (
  SELECT 1 seq, '24' t, '20230314' d, '111.11' a FROM dual UNION ALL
  SELECT 2,     '24',   '20231231',   '222.22'   FROM dual UNION ALL
  SELECT 3,     '5',    '20230314',   '333.33'   FROM dual
),
c AS (
  SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) AS cols,
         LISTAGG(CASE column_name
                   WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2001389343)'
                   WHEN 'TYPE'         THEN '#T#'
                   WHEN 'PAYMENT_DATE' THEN '#D#'
                   WHEN 'AMOUNT'       THEN '#A#'
                   ELSE column_name
                 END, ', ') WITHIN GROUP (ORDER BY column_id) AS vals
  FROM all_tab_columns
  WHERE owner = 'TRADE' AND table_name = 'FEE'
)
SELECT 'INSERT INTO TRADE.FEE (' || c.cols || ') SELECT '
       || REPLACE(REPLACE(REPLACE(c.vals, '#T#', p.t), '#D#', p.d), '#A#', p.a)
       || ' FROM TRADE.FEE WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1 AND FEE_NUMBER = 4;' AS STMT
FROM p, c
ORDER BY p.seq;

-- HOW TO USE:
-- 1. Run this query (Ctrl+Enter). You get 3 rows in STMT.
-- 2. Click the first cell, Shift+click the last cell, Ctrl+C.
-- 3. Paste into a NEW worksheet, add a line:  COMMIT;
-- 4. Press F5 (Run Script). Expect "1 row inserted." three times, then "Commit complete."
