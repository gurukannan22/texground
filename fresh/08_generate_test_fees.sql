-- Step 8: GENERATE 4 test-fee INSERTs on deal 2001371316, txn 5 (the OLD txn for the amend)
-- Each is a copy of the existing fee 1 on txn 5, with TYPE / PAYMENT_DATE / AMOUNT / DESCRIPTION overridden.
--   444.44  type 24  20220101  desc 18607953  -> SCENARIO 1: past-dated maturity
--   111.11  type 24  20230314  desc 18607953  -> SCENARIO 3: same-day maturity (THE FIX, like prod)
--   222.22  type 24  20231231  desc 18607954  -> SCENARIO 2: future-dated maturity (linked-trade fee, carried by existing logic)
--   333.33  type 5   20230314  desc 18607953  -> NEGATIVE: same-day NON-maturity, fix must not move it
WITH p AS (
  SELECT 1 seq, '24' t, '20220101' d, '444.44' a, '18607953' s FROM dual UNION ALL
  SELECT 2,     '24',   '20230314',   '111.11',   '18607953'   FROM dual UNION ALL
  SELECT 3,     '24',   '20231231',   '222.22',   '18607954'   FROM dual UNION ALL
  SELECT 4,     '5',    '20230314',   '333.33',   '18607953'   FROM dual
),
c AS (
  SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) AS cols,
         LISTAGG(CASE column_name
                   WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2001371316)'
                   WHEN 'TYPE'         THEN '#T#'
                   WHEN 'PAYMENT_DATE' THEN '#D#'
                   WHEN 'AMOUNT'       THEN '#A#'
                   WHEN 'DESCRIPTION'  THEN '''#S#'''
                   ELSE column_name
                 END, ', ') WITHIN GROUP (ORDER BY column_id) AS vals
  FROM all_tab_columns
  WHERE owner = 'TRADE' AND table_name = 'FEE'
)
SELECT 'INSERT INTO TRADE.FEE (' || c.cols || ') SELECT '
       || REPLACE(REPLACE(REPLACE(REPLACE(c.vals, '#T#', p.t), '#D#', p.d), '#A#', p.a), '#S#', p.s)
       || ' FROM TRADE.FEE WHERE DEAL = 2001371316 AND TRANSACTION_ID = 5 AND FEE_NUMBER = 1;' AS STMT
FROM p, c
ORDER BY p.seq;

-- HOW TO USE: run (Ctrl+Enter) -> 4 rows. Select all 4 cells, Ctrl+C.
-- Paste into an EMPTY worksheet, add  COMMIT;  select all, F5.
-- Expect "1 row inserted." x4 and "Commit complete."

-- 8b. BEFORE snapshot  >>> SCREENSHOT FOR EVIDENCE <<<  (expect 6 rows: fee on txn 3, 5 fees on txn 5)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;
