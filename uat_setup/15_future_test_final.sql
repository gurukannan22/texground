-- =====================================================================
-- UAT FUTURE-DATED FEE TEST (FINAL) - deal 2002739527, amend message 139788789 (London)
-- Flag must be TRUE. UAT process date = 20260306. Run BEFORE the flag OFF test (file 14).
--
-- Rule from code (AbstractActionHandler.addFutureDatedMaturityFeeToNewTxn :369-400, :375-376):
--   a fee on the old txn is MOVED to the new txn when ALL of:
--     TYPE = 24 (MATURITY), PAYMENT_DATE > processDate (strictly),
--     DESCRIPTION not null AND DESCRIPTION <> the amended trade's own id (tradeMessage.getTradeID())
--   (C263-46813: linked Depo maturity fee on an option contract revision)
--   A future maturity fee whose DESCRIPTION = own trade id is deleted by removeFutureFee (:420, >= processDate).
--   This method is NOT behind the C263-119169 flag (existing behaviour).
-- =====================================================================

-- STEP 1. Pre-checks  >>> SCREENSHOT <<<
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';                         -- expect TRUE
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;                            -- expect 20260306
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;                      -- expect latest = txn 2

-- STEP 2. GENERATE test-fee INSERTs on the latest txn (copies of an existing fee there)
--   555.55  type 24  20261231  desc 16082183 -> future MATURITY fee of a linked (Depo) contract  -> expect MOVED to new txn
--   222.22  type 24  20261231  desc 16082182 -> future MATURITY fee of the option's own contract -> expect DELETED (existing)
--   333.33  type 5   20260306  desc 16082182 -> same-day non-maturity trigger (amend detects a change -> new txn)
--   Run (Ctrl+Enter) -> 3 rows. Copy all, paste into an empty worksheet, add COMMIT;, select all, F5.
WITH p AS (
  SELECT 1 seq, '24' t, '20261231' d, '555.55' a, '16082183' s FROM dual UNION ALL
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

-- STEP 3. BEFORE  >>> SCREENSHOT BOTH <<<
-- expect on txn 2: premium 1090000, 444.44 (20260101), 111.11 (20260306), 555.55 (20261231, desc 16082183),
--                  222.22 (20261231, desc 16082182), 333.33 (type 5, 20260306)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

-- STEP 4. RUN: ProteusMessageIDs.in = 139788789, force start the FXO LN reprocess job.
--         Screenshot job output (SUCCESS, exit 0, Total No Of Message Processed: 1).

-- STEP 5. AFTER  >>> SCREENSHOT ALL <<<
-- 5a. Transactions (expect new txn 3; txn 2 TERMINATION_LINK = 3, txn 3 ORIGINATION_LINK = 2)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;
-- 5b. Future-dated maturity fees (expect: 555.55 on txn 3 exactly once; 222.22 not present)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, DESCRIPTION
FROM TRADE.FEE
WHERE DEAL = 2002739527 AND TYPE = 24
  AND PAYMENT_DATE > (SELECT MAX(CURRENT_PROCESS_DATE) FROM REFERENCE_DATA.PROCESS_DATE)
ORDER BY TRANSACTION_ID, FEE_NUMBER;
-- 5c. All fees (expect txn 3: 1090000, 444.44, 111.11, 555.55; txn 2: nothing; 222.22 and 333.33 gone)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
-- 5d. Duplicates (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE WHERE DEAL = 2002739527
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) HAVING COUNT(*) > 1;
