-- FRESH START - Step 3: set up one test fee per scenario on txn 1, then take BEFORE snapshot
-- Run 3a, 3b, 3c in order. If 3b errors, send the error and STOP.

-- 3a. Put the XML-built maturity fee back to its original past date (expect 1 row updated)
UPDATE TRADE.FEE SET PAYMENT_DATE = 20210716
WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1 AND PAYMENT_DATE = 20230314;
COMMIT;

-- 3b. Add test fees (copied from the existing 705.05 fee so all other columns stay valid)
--   amount 111.11 : maturity (24), payment date = process date 20230314  -> SCENARIO 3 (same-day, the fix)
--   amount 222.22 : maturity (24), payment date 20231231 (future)        -> SCENARIO 2 (future-dated)
--   amount 333.33 : type 5 (non-maturity), payment date 20230314         -> negative check (fix must not touch it)
DECLARE
  r TRADE.FEE%ROWTYPE;
  n NUMBER;
BEGIN
  SELECT * INTO r FROM TRADE.FEE
   WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1 AND AMOUNT = 705.05 AND ROWNUM = 1;
  SELECT MAX(FEE_NUMBER) INTO n FROM TRADE.FEE WHERE DEAL = 2001389343;

  r.FEE_NUMBER := n + 1; r.TYPE := 24; r.PAYMENT_DATE := 20230314; r.AMOUNT := 111.11;
  INSERT INTO TRADE.FEE VALUES r;
  r.FEE_NUMBER := n + 2; r.TYPE := 24; r.PAYMENT_DATE := 20231231; r.AMOUNT := 222.22;
  INSERT INTO TRADE.FEE VALUES r;
  r.FEE_NUMBER := n + 3; r.TYPE := 5;  r.PAYMENT_DATE := 20230314; r.AMOUNT := 333.33;
  INSERT INTO TRADE.FEE VALUES r;
  COMMIT;
END;
/

-- 3c. BEFORE snapshot  >>> SCREENSHOT FOR EVIDENCE <<<
-- Expect 5 rows on txn 1:
--   20210416 (past) | 705.05 20210716 (past) | 111.11 20230314 (same-day) | 222.22 20231231 (future) | 333.33 type 5 20230314
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;
