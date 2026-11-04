-- UAT future-dated test - PREPARE deal 2002732532 / amend message 153680732 (contract 24201656, London)
-- UAT process date = 20260306. Stored version = 6, message version = 4 -> raise message to 7.
-- All 4 version tags in the message belong to the trade itself (lifecycleGroupID, InternalTradeID,
-- FoxTradeKey, LegId) - no linked-trade version blocks - so all 4 are changed.

-- 10a. Raise message version 4 -> 7 (expect 1 row updated)
UPDATE TRADE.TPE_MESSAGE
SET XML_MESSAGE = REPLACE(XML_MESSAGE, '<fpml:version>4<', '<fpml:version>7<')
WHERE MESSAGE_ID = 153680732;
COMMIT;

-- 10b. Verify (expect V4 = 0, V7 = 4, LEN = 21429)
SELECT REGEXP_COUNT(XML_MESSAGE, '<fpml:version>4<') AS V4,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>7<') AS V7,
       DBMS_LOB.GETLENGTH(XML_MESSAGE) AS LEN
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 153680732;

-- 10c. GENERATE the trigger fee INSERT: same-day NON-maturity (type 5) on txn 3, 888.88, 20260306
--      (copy of fee 1 on txn 3). This makes the amend detect a change and create txn 4.
--      Run (Ctrl+Enter) -> 1 row. Copy the cell into an empty worksheet, add COMMIT;, F5.
SELECT 'INSERT INTO TRADE.FEE (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002732532)'
                 WHEN 'TYPE'         THEN '5'
                 WHEN 'PAYMENT_DATE' THEN '20260306'
                 WHEN 'AMOUNT'       THEN '888.88'
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.FEE WHERE DEAL = 2002732532 AND TRANSACTION_ID = 3 AND FEE_NUMBER = 1;' AS STMT
FROM all_tab_columns
WHERE owner = 'TRADE' AND table_name = 'FEE';

-- 10d. BEFORE - fees  >>> SCREENSHOT <<<
--      Expect txn 2: 140937.5 (linked trade 24201655)
--             txn 3: 136093.75 (type 5, 20260406), 53997.84 (type 24, 20260406 = FUTURE), 888.88 (type 5, 20260306)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002732532 ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 10e. BEFORE - transactions (expect txn 1, 2, 3; txn 3 latest, no termination link)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2002732532 ORDER BY TRANSACTION_ID;

-- >>> RUN: ProteusMessageIDs.in = 153680732, force start the FXO LN reprocess job (UAT_R8) <<<

-- 10f. AFTER - transactions (expect new txn 4; txn 3 TERMINATION_LINK = 4)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE WHERE DEAL = 2002732532 ORDER BY TRANSACTION_ID;

-- 10g. AFTER - fees (expect 53997.84 future maturity fee on txn 4, exactly once; nothing left on txn 3;
--      txn 2 linked-trade fee unchanged)  >>> SCREENSHOT <<<
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE WHERE DEAL = 2002732532 ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 10h. AFTER - duplicates (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE WHERE DEAL = 2002732532
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2)
HAVING COUNT(*) > 1;

-- 10i. AFTER - map (expect new row 24201656 version 7 -> txn 4, AMEND)
SELECT TPE_DEAL, TPE_TRANSACTION_ID AS VERSION, OASYS_TRANSACTION_ID, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2002732532 ORDER BY CREATED_TIME_STAMP;

-- ROLLBACK of the message change (only if needed): version 7 -> 4
-- UPDATE TRADE.TPE_MESSAGE SET XML_MESSAGE = REPLACE(XML_MESSAGE, '<fpml:version>7<', '<fpml:version>4<')
-- WHERE MESSAGE_ID = 153680732; COMMIT;
