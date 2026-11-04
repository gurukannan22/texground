-- UAT test deal setup - Step 6: add one test fee per scenario on deal 2002739527, txn 1
-- UAT process date = 20260306. Each new fee is a copy of existing fee 1 (premium) with
-- TYPE / PAYMENT_DATE / AMOUNT changed and the next FEE_NUMBER.
--   444.44  type 24  20260101  -> past-dated maturity
--   111.11  type 24  20260306  -> SAME-DAY maturity (the fix)
--   222.22  type 24  20261231  -> future-dated maturity
--   333.33  type 5   20260306  -> same-day NON-maturity (also makes the amend create a new txn)

-- 6a. GENERATE the 4 INSERTs. Run (Ctrl+Enter) -> 4 rows.
--     Select all 4 cells, Ctrl+C, paste into an EMPTY worksheet, add  COMMIT;  select all, F5.
--     Expect "1 row inserted." x4 and "Commit complete."
WITH p AS (
  SELECT 1 seq, '24' t, '20260101' d, '444.44' a FROM dual UNION ALL
  SELECT 2,     '24',   '20260306',   '111.11'   FROM dual UNION ALL
  SELECT 3,     '24',   '20261231',   '222.22'   FROM dual UNION ALL
  SELECT 4,     '5',    '20260306',   '333.33'   FROM dual
),
c AS (
  SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) AS cols,
         LISTAGG(CASE column_name
                   WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002739527)'
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
       || ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = 1 AND FEE_NUMBER = 1;' AS STMT
FROM p, c
ORDER BY p.seq;

-- 6b. BEFORE snapshot  >>> SCREENSHOT FOR EVIDENCE <<<
--     Expect 5 rows on txn 1: premium 1090000, 444.44, 111.11, 222.22, 333.33
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT,
       PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE
WHERE DEAL = 2002739527
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 6c. Transactions before (expect only txn 1)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527
ORDER BY TRANSACTION_ID;
