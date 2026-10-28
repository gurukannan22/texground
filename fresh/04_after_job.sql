-- FRESH START - Step 4: AFTER the job run (flag ON)  >>> SCREENSHOT EACH FOR EVIDENCE <<<

-- 4a. Fees after the job
-- EXPECTED (flag ON = fix working):
--   -12500  20210416  past-dated        -> present
--   705.05  20210716  past-dated        -> present
--   111.11  20230314  same-day maturity -> PRESENT (moved, not lost)  <-- THE FIX
--   222.22  20231231  future maturity   -> present
--   333.33  20230314  type 5            -> not moved by the fix
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 4b. Message processed again (expect MESSAGE_PROCESSING_COMPLETED, updated today)
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 398871121;

-- 4c. No duplicate fees (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, AMOUNT, COUNT(*)
FROM TRADE.FEE
WHERE DEAL = 2001389343
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, AMOUNT
HAVING COUNT(*) > 1;
