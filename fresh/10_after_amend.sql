-- Step 10: AFTER the amend job run (flag ON)  >>> SCREENSHOT EACH FOR EVIDENCE <<<
-- Expected results are from the code trace (Copilot, AbstractActionHandler / AmendEventHandler).

-- 10a. Fees after the job. EXPECTED (flag ON):
--   txn 3 fee -54294.54 (other trade)            -> unchanged on txn 3
--   txn 5                                         -> NO fees left
--   txn 6: 444.44   MATURITY 20220101 (past)      -> moved from txn 5   (Scenario 1)
--   txn 6: 111.11   MATURITY 20230314 (same-day)  -> moved from txn 5   (Scenario 3 = THE FIX)
--   txn 6: 222.22   MATURITY 20231231 (future)    -> moved from txn 5   (Scenario 2)
--   txn 6: option premium (type 5) rebuilt from the message (amount may differ, ~237152.8x)
--   333.33 type 5 same-day                         -> deleted (fix applies to MATURITY only)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001371316
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 10b. Transaction map. EXPECTED: new row 18607953 / TPE_TRANSACTION_ID 9 -> OASYS_TRANSACTION_ID 6, TRADE_EVENT AMEND
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE OASYS_DEAL = 2001371316
ORDER BY CREATED_TIME_STAMP;

-- 10c. New Oasys transaction 6 exists (EXPECTED: rows for txn 5 and 6)
SELECT * FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316 AND TRANSACTION_ID IN (5, 6);

-- 10d. Message status (EXPECTED: MESSAGE_PROCESSING_COMPLETED, updated today)
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;

-- 10e. No duplicate fees (EXPECTED: 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, AMOUNT, COUNT(*)
FROM TRADE.FEE
WHERE DEAL = 2001371316
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, AMOUNT
HAVING COUNT(*) > 1;
