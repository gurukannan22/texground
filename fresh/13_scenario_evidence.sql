-- =====================================================================
-- C263-119169 TEST EVIDENCE - run in this order, screenshot each step
-- Test deal 2001371316 (FX option, London) | amend message 386121612
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1. PRE-CONDITIONS  (doc: "1. Pre-conditions")
-- ---------------------------------------------------------------------

-- 1a. Feature flag ON (expect EXTERNAL_CODE = TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE
FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 1b. Process date (expect 20230314)
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;

-- 1c. Test deal selection: FX option (Proteus, London) deals whose LATEST transaction
--     has a MATURITY fee (type 24) due on the process date and an AMEND message
--     (expect deal 2001371316, txn 5, message 386121612)
SELECT m.OASYS_DEAL, m.OASYS_TRANSACTION_ID, m.TPE_DEAL, m.PRODUCT_CLASS,
       f.FEE_NUMBER, f.TYPE, ROUND(f.AMOUNT,2) AS AMOUNT, f.PAYMENT_DATE,
       t.MESSAGE_ID AS AMEND_MESSAGE_ID
FROM TRADE.TPE_DEAL_TRANSACTION_MAP m
JOIN TRADE.FEE f
  ON f.DEAL = m.OASYS_DEAL
 AND f.TRANSACTION_ID = m.OASYS_TRANSACTION_ID
JOIN TRADE.TPE_MESSAGE t
  ON t.CONTRACT_REF = TO_CHAR(m.TPE_DEAL)
WHERE m.PRODUCT_CLASS = 33
  AND m.TRADE_ENTRY_SYSTEM = 'PROTEUS'
  AND f.TYPE = 24
  AND f.PAYMENT_DATE = (SELECT MAX(CURRENT_PROCESS_DATE) FROM REFERENCE_DATA.PROCESS_DATE)
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                WHERE x.DEAL = m.OASYS_DEAL)
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'citimlEventType>Amend') > 0
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'termDeposit') = 0
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'CTLON') > 0;

-- ---------------------------------------------------------------------
-- STEP 2. BEFORE  (doc: "2. Before")
-- ---------------------------------------------------------------------

-- 2a. Fees on the deal (expect txn 3: 1 fee; txn 5: 5 fees incl. 444.44 / 111.11 / 222.22 / 333.33)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 2b. Transactions (expect txn 5 latest, TERMINATION_LINK null, no txn 6)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- STEP 3. EXECUTION  (doc: "3. Execution")
--   - ProteusMessageIDs.in = 386121612 (screenshot)
--   - Force start 263_CBNA_PROCESSOR_JAVA_FXO_LN_REPROCESSMESSAGE_R8
--   - Screenshot job output: SUCCESS, exit 0, MessageID 386121612
-- ---------------------------------------------------------------------

-- 3a. Message processed (expect MESSAGE_PROCESSING_COMPLETED, LAST_UPDATED today)
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;

-- ---------------------------------------------------------------------
-- STEP 4. AFTER - NEW TRANSACTION  (doc: "4. Contract revision")
-- ---------------------------------------------------------------------

-- 4a. Transactions (expect txn 5 TERMINATION_LINK = 6; new txn 6 ORIGINATION_LINK = 5)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316 AND TRANSACTION_ID >= 5
ORDER BY TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- STEP 5. AFTER - ONE QUERY PER SCENARIO  (doc: "5. Scenario results")
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
-- STEP 6. FINAL STATE  (doc: "6. Final state")
-- ---------------------------------------------------------------------

-- 6a. All fees after (expect txn 3: 1 fee; txn 6: 444.44, 111.11, 222.22 + rebuilt premium)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 6b. No duplicate fees (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE
WHERE DEAL = 2001371316
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2)
HAVING COUNT(*) > 1;
