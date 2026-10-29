-- =====================================================================
-- C263-119169 FLAG OFF RUN - proves the bug without the fix
-- Deal 2001371316 | old txn 6 -> new txn 7 | amend message 386121612
-- EXPECTED: same-day maturity fee 111.11 is LOST (prod bug reproduced)
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1. SET FLAG OFF   (doc: "Flag OFF - Pre-conditions")
-- ---------------------------------------------------------------------
-- 1a. Turn flag OFF (expect 1 row updated)
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'FALSE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;

-- 1b. Verify (expect EXTERNAL_CODE = FALSE)  >>> SCREENSHOT <<<
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 1c. Process date (expect 20230314)  >>> SCREENSHOT <<<
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;

-- ---------------------------------------------------------------------
-- STEP 2. PREPARE (no screenshot needed)
-- ---------------------------------------------------------------------
-- 2a. Message version 9 -> 10 (stored version is now 9, message must be newer)
--     Check first: expect V9 = 4, V10 = 0
SELECT REGEXP_COUNT(XML_MESSAGE, '<fpml:version>9<')  AS V9,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>10<') AS V10
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 386121612;

UPDATE TRADE.TPE_MESSAGE
SET XML_MESSAGE = REPLACE(XML_MESSAGE, '<fpml:version>9<', '<fpml:version>10<')
WHERE MESSAGE_ID = 386121612;
COMMIT;
-- re-run the check: expect V9 = 0, V10 = 4

-- 2b. GENERATE insert for same-day non-maturity fee 333.33 on txn 6 (same as flag ON run)
--     Run (Ctrl+Enter) -> 1 row. Copy cell to empty worksheet, add COMMIT; F5.
SELECT 'INSERT INTO TRADE.FEE (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2001371316)'
                 WHEN 'TYPE'         THEN '5'
                 WHEN 'PAYMENT_DATE' THEN '20230314'
                 WHEN 'AMOUNT'       THEN '333.33'
                 WHEN 'DESCRIPTION'  THEN '''18607953'''
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.FEE WHERE DEAL = 2001371316 AND TRANSACTION_ID = 6 AND ROUND(AMOUNT,2) = 111.11;' AS STMT
FROM all_tab_columns
WHERE owner = 'TRADE' AND table_name = 'FEE';

-- ---------------------------------------------------------------------
-- STEP 3. BEFORE   (doc: "Flag OFF - Before")
-- ---------------------------------------------------------------------
-- 3a. Fees (expect txn 3: 1 fee; txn 6: 111.11, 444.44, 222.22, 237152.82, 333.33)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 3b. Transactions (expect txn 6 latest, TERMINATION_LINK null, no txn 7)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2001371316 AND TRANSACTION_ID >= 5
ORDER BY TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- STEP 4. RUN THE JOB  (doc: "Flag OFF - Execution")
--   ProteusMessageIDs.in still = 386121612. Force start FXO_LN reprocess job.
--   Screenshot job output (SUCCESS, exit 0).
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- STEP 5. AFTER   (doc: "Flag OFF - Results")
-- ---------------------------------------------------------------------
-- 5a. New txn 7 (expect txn 6 TERMINATION_LINK = 7; txn 7 ORIGINATION_LINK = 6)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2001371316 AND TRANSACTION_ID >= 6
ORDER BY TRANSACTION_ID;

-- 5b. S1 past 444.44 -> expect txn 7
SELECT 'OFF S1 PAST' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 444.44;

-- 5c. S2 future 222.22 -> expect txn 7
SELECT 'OFF S2 FUTURE' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 222.22;

-- 5d. S3 same-day maturity 111.11 -> expect 0 ROWS (fee lost = prod bug without the fix)
SELECT 'OFF S3 SAME-DAY MATURITY' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 111.11;

-- 5e. All fees after
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- ---------------------------------------------------------------------
-- STEP 6. SET FLAG BACK ON (expect 1 row updated, then TRUE)
-- ---------------------------------------------------------------------
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'TRUE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';
