-- =====================================================================
-- C263-119169 TEST EVIDENCE - run in this order, screenshot each step
-- Deal 2001371316 | old txn 5 -> new txn 6 | amend message 386121612
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1. PRE-CONDITIONS  (evidence section "1. Pre-conditions")
-- ---------------------------------------------------------------------

-- 1a. Feature flag ON (expect EXTERNAL_CODE = TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE
FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 1b. Process date (expect 20230314)
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;

-- ---------------------------------------------------------------------
-- STEP 2. TEST DATA SETUP  (evidence section "2. Test Data Setup")
-- ---------------------------------------------------------------------

-- 2a. Transaction map row (expect 18607953 / 8 -> 2001371316 / 5)
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID, GROUP_ID, PRODUCT_NUMBER, TRADE_EVENT
FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE OASYS_DEAL = 2001371316;

-- 2b. Amend message checks (expect EVT > 0, TD = 0, TRS = 0, VER9 >= 1)
SELECT MESSAGE_ID,
       DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>Amend') AS EVT,
       DBMS_LOB.INSTR(XML_MESSAGE, 'termDeposit')           AS TD,
       DBMS_LOB.INSTR(XML_MESSAGE, 'TRS_Terms')             AS TRS,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>9<')        AS VER9,
       STATUS
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;

-- ---------------------------------------------------------------------
-- STEP 3. BEFORE SNAPSHOT  (evidence section "3. Before")
-- ---------------------------------------------------------------------

-- 3a. All fees on the deal (expect txn 3: 1 fee; txn 5: 5 fees)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 3b. Transactions (expect txn 5 latest, TERMINATION_LINK null, no txn 6)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- STEP 4. RUN THE JOB  (evidence section "4. Execution")
--   - ProteusMessageIDs.in = 386121612 (screenshot)
--   - Force start 263_CBNA_PROCESSOR_JAVA_FXO_LN_REPROCESSMESSAGE_R8
--   - Screenshot job output: SUCCESS, exit 0, MessageID 386121612
-- ---------------------------------------------------------------------

-- 4a. Message processed (expect MESSAGE_PROCESSING_COMPLETED, LAST_UPDATED today)
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;

-- ---------------------------------------------------------------------
-- STEP 5. AFTER - NEW TRANSACTION  (evidence section "5. Revision created")
-- ---------------------------------------------------------------------

-- 5a. Transactions (expect txn 5 TERMINATION_LINK = 6; new txn 6 ORIGINATION_LINK = 5)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316 AND TRANSACTION_ID >= 5
ORDER BY TRANSACTION_ID;

-- 5b. Transaction map (expect new row: version 9 -> txn 6, TRADE_EVENT AMEND)
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID, TRADE_EVENT
FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE OASYS_DEAL = 2001371316
ORDER BY TPE_TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- STEP 6. AFTER - ONE QUERY PER SCENARIO  (evidence section "6. Scenario results")
-- ---------------------------------------------------------------------

-- S1. Payment date BEFORE process date (444.44, 20220101) -> expect txn 6
SELECT 'S1 PAST' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 444.44;

-- S2. Payment date AFTER process date (222.22, 20231231) -> expect txn 6
SELECT 'S2 FUTURE' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 222.22;

-- S3. Payment date = process date, MATURITY (111.11, 20230314) -> expect txn 6   <-- THE FIX
SELECT 'S3 SAME-DAY MATURITY' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 111.11;

-- S4. Same-day NON-maturity (type 5, 333.33) -> expect 0 rows (fix is maturity-only)
SELECT 'S4 SAME-DAY NON-MATURITY' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND ROUND(AMOUNT,2) = 333.33;

-- S5. Old txn 5 has no fees left -> expect 0 rows
SELECT 'S5 OLD TXN EMPTY' AS SCENARIO, DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE
FROM TRADE.FEE WHERE DEAL = 2001371316 AND TRANSACTION_ID = 5;

-- ---------------------------------------------------------------------
-- STEP 7. AFTER - FULL PICTURE + SANITY  (evidence section "7. Final state")
-- ---------------------------------------------------------------------

-- 7a. All fees after (expect txn 3: 1 fee; txn 6: 444.44, 111.11, 222.22 + rebuilt premium)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 7b. No duplicate fees (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE
WHERE DEAL = 2001371316
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2)
HAVING COUNT(*) > 1;
