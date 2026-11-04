-- UAT future-dated fee test - deal 2002739527, amend message 139788789, process date 20260306
-- Old txn = current latest (expect txn 2). New txn after the run = txn 3.

-- 7a. Current state (expect latest txn 2; map row version 8 -> txn 2)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

SELECT TPE_DEAL, TPE_TRANSACTION_ID AS VERSION, OASYS_TRANSACTION_ID, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2002739527 ORDER BY CREATED_TIME_STAMP;

-- 7b. Does the amend message carry a linked trade? (expect LINKED_POS > 0; read LINKED_TXT for the linked trade id)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, 'LinkedTradeId') AS LINKED_POS,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 400, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'LinkedTradeId') - 150, 1)) AS LINKED_TXT
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 139788789;

-- 7c. GENERATE test-fee INSERTs on the latest txn (copies of an existing fee on that txn).
--     Replace LINKED_ID below with the linked trade id from 7b before running.
--   555.55  type 24  20261231  desc = LINKED_ID  -> future maturity, LINKED trade  (expected: carried to new txn)
--   666.66  type 24  20261231  desc = 16082182   -> future maturity, OWN contract  (expected: rebuilt from message only)
--   777.77  type 24  20260306  desc = 16082182   -> same-day maturity (fix, regression check)
--   888.88  type 5   20260306  desc = 16082182   -> same-day non-maturity (makes the amend create a new txn)
--   Run (Ctrl+Enter) -> 4 rows. Copy, paste into an empty worksheet, add COMMIT;, select all, F5.
WITH p AS (
  SELECT 1 seq, '24' t, '20261231' d, '555.55' a, 'LINKED_ID' s FROM dual UNION ALL
  SELECT 2,     '24',   '20261231',   '666.66',   '16082182'   FROM dual UNION ALL
  SELECT 3,     '24',   '20260306',   '777.77',   '16082182'   FROM dual UNION ALL
  SELECT 4,     '5',    '20260306',   '888.88',   '16082182'   FROM dual
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
  FROM all_tab_columns
  WHERE owner = 'TRADE' AND table_name = 'FEE'
)
SELECT 'INSERT INTO TRADE.FEE (' || c.cols || ') SELECT '
       || REPLACE(REPLACE(REPLACE(REPLACE(c.vals, '#T#', p.t), '#D#', p.d), '#A#', p.a), '#S#', p.s)
       || ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = '
       || '(SELECT MAX(TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2002739527) AND ROWNUM = 1;' AS STMT
FROM p, c
ORDER BY p.seq;

-- 7d. BEFORE snapshot  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- Then: ProteusMessageIDs.in = 139788789, run the LN reprocess job.

-- 7e. AFTER: transactions (expect new txn 3, txn 2 TERMINATION_LINK = 3)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID;

-- 7f. AFTER: fees (expect 555.55 and 777.77 on txn 3)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002739527 ORDER BY TRANSACTION_ID, FEE_NUMBER;
