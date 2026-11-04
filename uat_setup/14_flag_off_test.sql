-- =====================================================================
-- UAT FLAG OFF TEST - deal 2002739527, amend message 139788789 (London)
-- Latest txn = 2 (already holds 111.11 same-day maturity, 444.44 past, premium 1090000)
-- Expected with flag OFF: new txn 3, same-day maturity fee 111.11 LOST (old behaviour)
-- Run in order. Do NOT combine with the future-dated test.
-- =====================================================================

-- STEP 1. GENERATE the trigger fee INSERT (333.33, type 5, same day) on txn 2
--         Run (Ctrl+Enter) -> 1 row. Copy the cell to an empty worksheet, add COMMIT;, F5.
--         Expect "1 row inserted." and "Commit complete."
SELECT 'INSERT INTO TRADE.FEE (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002739527)'
                 WHEN 'TYPE'         THEN '5'
                 WHEN 'PAYMENT_DATE' THEN '20260306'
                 WHEN 'AMOUNT'       THEN '333.33'
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = (SELECT MAX(TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2002739527) AND ROWNUM = 1;' AS STMT
FROM all_tab_columns WHERE owner = 'TRADE' AND table_name = 'FEE';

-- STEP 2. Set flag OFF (expect 1 row updated)
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'FALSE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;

-- STEP 3. PRE-CONDITIONS  >>> SCREENSHOT <<<
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';                         -- expect FALSE
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;                            -- expect 20260306

-- STEP 4. BEFORE  >>> SCREENSHOT BOTH <<<
-- 4a. Fees (expect on txn 2: premium 1090000, 444.44, 111.11 (20260306), 333.33 (type 5, 20260306))
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
-- 4b. Transactions (expect txn 1, 2; txn 2 latest, TERMINATION_LINK null)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

-- STEP 5. RUN: ProteusMessageIDs.in = 139788789, force start the FXO LN reprocess job.
--         Screenshot job output (SUCCESS, exit 0, MessageID 139788789).

-- STEP 6. AFTER  >>> SCREENSHOT ALL <<<
-- 6a. Transactions (expect new txn 3; txn 2 TERMINATION_LINK = 3, txn 3 ORIGINATION_LINK = 2)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;
-- 6b. Fees (expect txn 3: premium 1090000, 444.44. 111.11 and 333.33 NOT present anywhere)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
-- 6c. Same-day maturity fee check (expect 0 rows = fee lost with flag OFF)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2002739527 AND ROUND(AMOUNT,2) = 111.11;
-- 6d. Duplicates (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE WHERE DEAL = 2002739527
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) HAVING COUNT(*) > 1;

-- STEP 7. SET FLAG BACK ON - DO THIS STRAIGHT AFTER THE RUN  >>> SCREENSHOT <<<
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'TRUE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';                         -- expect TRUE
