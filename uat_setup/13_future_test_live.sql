-- =====================================================================
-- UAT FUTURE-DATED FEE TEST - run in order while sharing screen
-- UAT process date = 20260306. Flag must be TRUE.
-- =====================================================================

-- STEP 1. Pre-checks  >>> SCREENSHOT <<<
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';                       -- expect TRUE
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;                          -- expect 20260306

-- STEP 2. Look for a NON-exercised deal with a real future maturity fee on its latest txn
--         (if this returns a row, use that deal instead of 2002739527 and tell Claude)
SELECT m.OASYS_DEAL, m.OASYS_TRANSACTION_ID, m.TPE_DEAL AS CONTRACT_REF,
       f.FEE_NUMBER, f.TYPE, ROUND(f.AMOUNT,2) AS AMOUNT, f.PAYMENT_DATE, f.CURRENCY
FROM TRADE.TPE_DEAL_TRANSACTION_MAP m
JOIN TRADE.FEE f ON f.DEAL = m.OASYS_DEAL AND f.TRANSACTION_ID = m.OASYS_TRANSACTION_ID
WHERE m.PRODUCT_CLASS = 33 AND m.TRADE_ENTRY_SYSTEM = 'PROTEUS'
  AND m.B2B_LEG_ID = 0 AND m.TRADE_EVENT = 'AMEND'
  AND f.TYPE = 24
  AND f.PAYMENT_DATE > (SELECT MAX(CURRENT_PROCESS_DATE) FROM REFERENCE_DATA.PROCESS_DATE)
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x WHERE x.DEAL = m.OASYS_DEAL)
  AND NOT EXISTS (SELECT 1 FROM TRADE.TPE_DEAL_TRANSACTION_MAP e
                  WHERE e.OASYS_DEAL = m.OASYS_DEAL AND e.TRADE_EVENT IN ('EXERCISE','UNWIND','TERMINATE'))
ORDER BY m.OASYS_DEAL;

-- ---------------------------------------------------------------------
-- If STEP 2 returns 0 rows: use deal 2002739527 (amend 139788789 already created a new txn once)
-- ---------------------------------------------------------------------

-- STEP 3. Deal 2002739527 - current state (expect latest txn 2)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

-- STEP 4. Does amend message 139788789 carry a linked trade? (LINKED_POS > 0 -> read the id in LINKED_TXT)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, 'LinkedTradeId') AS LINKED_POS,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 300, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'LinkedTradeId') - 100, 1)) AS LINKED_TXT
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 139788789;

-- STEP 5. GENERATE test-fee INSERTs on the latest txn of 2002739527
--   Replace LINKED_ID with the id from STEP 4 (if LINKED_POS = 0, delete that row from the WITH list).
--   555.55 type 24 20261231 desc LINKED_ID -> future maturity, linked trade (expected: carried to new txn)
--   222.22 type 24 20261231 desc 16082182  -> future maturity, own contract  (expected: rebuilt only if in message)
--   333.33 type 5  20260306 desc 16082182  -> same-day non-maturity, makes the amend create a new txn
--   Run (Ctrl+Enter), copy all rows into an empty worksheet, add COMMIT;, select all, F5.
WITH p AS (
  SELECT 1 seq, '24' t, '20261231' d, '555.55' a, 'LINKED_ID' s FROM dual UNION ALL
  SELECT 2,     '24',   '20261231',   '222.22',   '16082182'   FROM dual UNION ALL
  SELECT 3,     '5',    '20260306',   '333.33',   '16082182'   FROM dual
),
c AS (
  SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) AS cols,
         LISTAGG(CASE column_name
                   WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002739527)'
                   WHEN 'TYPE'         THEN '#T#'
                   WHEN 'PAYMENT_DATE' THEN '#D#'
                   WHEN 'AMOUNT'       THEN '#A#'
                   WHEN 'DESCRIPTION'  THEN '''#S#'''
                   ELSE column_name
                 END, ', ') WITHIN GROUP (ORDER BY column_id) AS vals
  FROM all_tab_columns WHERE owner = 'TRADE' AND table_name = 'FEE'
)
SELECT 'INSERT INTO TRADE.FEE (' || c.cols || ') SELECT '
       || REPLACE(REPLACE(REPLACE(REPLACE(c.vals, '#T#', p.t), '#D#', p.d), '#A#', p.a), '#S#', p.s)
       || ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = '
       || '(SELECT MAX(TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2002739527) AND ROWNUM = 1;' AS STMT
FROM p, c ORDER BY p.seq;

-- STEP 6. BEFORE  >>> SCREENSHOT BOTH <<<
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

-- STEP 7. RUN: ProteusMessageIDs.in = 139788789, force start the FXO LN reprocess job. Screenshot job output.

-- STEP 8. AFTER  >>> SCREENSHOT ALL <<<
-- 8a. Transactions (expect new txn 3; txn 2 TERMINATION_LINK = 3)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;
-- 8b. Fees (expect 555.55 on txn 3; past fees 444.44 / 111.11 / premium on txn 3; 333.33 gone)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
-- 8c. Duplicates (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE WHERE DEAL = 2002739527
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) HAVING COUNT(*) > 1;
-- 8d. Map (expect a row 16082182 -> txn 3, AMEND, created today)
SELECT TPE_DEAL, TPE_TRANSACTION_ID AS VERSION, OASYS_TRANSACTION_ID, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2002739527 ORDER BY CREATED_TIME_STAMP;
