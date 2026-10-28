-- Step 41: scenario setup on txn 1 of deal 2001389343 (one fee per JIRA scenario)
-- Message to use: the v3 XML BUT with maturityDate / terminationDate back to 2021-07-16
-- (version must stay 3, because the map now stores version 3).
-- Distinct amounts make each test fee easy to track before/after.

-- 41a. Check FEE columns/keys first (look for an ID / surrogate key column)
SELECT column_name, data_type, nullable
FROM all_tab_columns
WHERE owner = 'TRADE' AND table_name = 'FEE'
ORDER BY column_id;

-- 41b. Reset the XML-built maturity fee to its original past date
UPDATE TRADE.FEE SET PAYMENT_DATE = 20210716
WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1 AND PAYMENT_DATE = 20230314;
COMMIT;

-- 41c. Insert test fees by copying an existing fee row (keeps all other columns valid)
--   A: maturity (24), SAME-DAY 20230314, amount 111.11  -> the fix
--   B: maturity (24), FUTURE   20231231, amount 222.22  -> future-dated scenario
--   C: non-maturity (5), SAME-DAY 20230314, amount 333.33 -> must NOT be moved by the fix
DECLARE
  r TRADE.FEE%ROWTYPE;
  n NUMBER;
BEGIN
  SELECT * INTO r FROM TRADE.FEE
   WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1 AND PAYMENT_DATE = 20210716 AND ROWNUM = 1;
  SELECT MAX(FEE_NUMBER) INTO n FROM TRADE.FEE WHERE DEAL = 2001389343 AND TRANSACTION_ID = 1;

  r.FEE_NUMBER := n + 1; r.TYPE := 24; r.PAYMENT_DATE := 20230314; r.AMOUNT := 111.11;
  INSERT INTO TRADE.FEE VALUES r;
  r.FEE_NUMBER := n + 2; r.TYPE := 24; r.PAYMENT_DATE := 20231231; r.AMOUNT := 222.22;
  INSERT INTO TRADE.FEE VALUES r;
  r.FEE_NUMBER := n + 3; r.TYPE := 5;  r.PAYMENT_DATE := 20230314; r.AMOUNT := 333.33;
  INSERT INTO TRADE.FEE VALUES r;
  COMMIT;
END;
/

-- 41d. BEFORE snapshot (screenshot for the doc)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- EXPECTED AFTER the job (flag OFF run = old behaviour, flag ON run = fix):
--   fee           | flag OFF            | flag ON
--   past 20210416 | kept                | kept
--   A 111.11 same-day maturity | LOST (prod bug) | KEPT  <-- the fix
--   B 222.22 future maturity   | kept            | kept
--   C 333.33 same-day type 5   | same as OFF     | same as OFF (not touched by fix)
