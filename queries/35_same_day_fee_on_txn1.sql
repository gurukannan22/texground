-- Step 35: make the maturity fee on txn 1 a same-day fee (like prod), then confirm the flag
-- Current state: txn 1 fee 3 = 705.05, PAYMENT_DATE 20210716 (rebuilt by the first reprocess)

-- 35a. Update the fee (expect: 1 row updated)
UPDATE TRADE.FEE
SET PAYMENT_DATE = 20230314
WHERE DEAL = 2001389343
  AND TRANSACTION_ID = 1
  AND FEE_NUMBER = 3;
COMMIT;

-- 35b. Confirm fees (expect: fee 1 = 20210416, fee 3 = 20230314, both on txn 1)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE,
       CURRENCY, DESCRIPTION, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- 35c. Confirm flag is still ON (expect EXTERNAL_CODE = TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE
FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';
