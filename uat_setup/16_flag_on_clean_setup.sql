-- UAT FLAG ON run - clean up txn 4 of deal 2002739527 to ONE fee per scenario, then run.
-- Current txn 4 (fee no.): 2=444.44 past | 3=555.55 future linked | 4=1090000 premium |
--                          5=555.55 future linked (DUPLICATE, added again) | 6=222.22 future own | 7=333.33 same-day type 5

-- 16a. Remove the extra test rows on txn 4 (duplicate 555.55 and 222.22). Expect "2 rows deleted".
DELETE FROM TRADE.FEE
WHERE DEAL = 2002739527 AND TRANSACTION_ID = 4 AND FEE_NUMBER IN (5, 6);
COMMIT;

-- 16b. GENERATE the same-day MATURITY fee (type 24, 111.11, 20260306) on txn 4 -> tests the fix with flag ON
--      Run (Ctrl+Enter) -> 1 row. Copy the cell to an empty worksheet, add COMMIT;, F5.
SELECT 'INSERT INTO TRADE.FEE (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002739527)'
                 WHEN 'TYPE'         THEN '24'
                 WHEN 'PAYMENT_DATE' THEN '20260306'
                 WHEN 'AMOUNT'       THEN '111.11'
                 WHEN 'DESCRIPTION'  THEN '''16082182'''
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = 4 AND FEE_NUMBER = 2;' AS STMT
FROM all_tab_columns WHERE owner = 'TRADE' AND table_name = 'FEE';

-- 16c. Flag (expect TRUE)  >>> SCREENSHOT <<<
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 16d. BEFORE  >>> SCREENSHOT BOTH <<<
--  expect txn 4 (one per scenario):
--    444.44    type 24  20260101  16082182  past maturity
--    111.11    type 24  20260306  16082182  SAME-DAY maturity (the fix)
--    555.55    type 24  20261231  16082183  future maturity, linked deposit
--    1090000   type 5   20200203  16082182  premium
--    333.33    type 5   20260306  16082182  same-day non-maturity (trigger)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;               -- expect latest txn 4

-- RUN: ProteusMessageIDs.in = 139788789 ONLY, force start the FXO LN reprocess job.

-- 16e. AFTER  >>> SCREENSHOT ALL <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;               -- expect new txn 5 (txn 4 TERMINATION_LINK = 5)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
--  expect txn 5: 444.44, 111.11 (fix), 555.55 (future linked), 1090000 ; 333.33 gone ; txn 4 empty
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE WHERE DEAL = 2002739527
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) HAVING COUNT(*) > 1;   -- expect 0 rows
