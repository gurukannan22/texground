-- =====================================================================
-- C263-119169 – UAT test queries (read-only, except CFG1/CFG2 flag config)
-- Replace :deal and :message_id with the values found in Q3 / Q4.
-- =====================================================================

-- Q1. Feature flag value (TRUE = fix enabled)
SELECT TYPE, CODE, EXTERNAL_CODE
FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- Q2. UAT process date
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;

-- Q3. Qualifying deals: FX option (Proteus) whose LATEST transaction has a
--     MATURITY fee (type 24) with payment date = process date
SELECT m.OASYS_DEAL, m.OASYS_TRANSACTION_ID, m.TPE_DEAL AS CONTRACT_REF,
       f.FEE_NUMBER, f.TYPE, ROUND(f.AMOUNT,2) AS AMOUNT, f.PAYMENT_DATE, f.CURRENCY
FROM TRADE.TPE_DEAL_TRANSACTION_MAP m
JOIN TRADE.FEE f
  ON f.DEAL = m.OASYS_DEAL
 AND f.TRANSACTION_ID = m.OASYS_TRANSACTION_ID
WHERE m.PRODUCT_CLASS = 33
  AND m.TRADE_ENTRY_SYSTEM = 'PROTEUS'
  AND f.TYPE = 24
  AND f.PAYMENT_DATE = (SELECT MAX(CURRENT_PROCESS_DATE) FROM REFERENCE_DATA.PROCESS_DATE)
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                WHERE x.DEAL = m.OASYS_DEAL)
ORDER BY m.OASYS_DEAL;

-- Q4. Amendment message for the deal's trade (latest first)
SELECT t.MESSAGE_ID, t.CONTRACT_REF, t.STATUS, t.LAST_UPDATED_TIME_STAMP,
       m.OASYS_DEAL, m.OASYS_TRANSACTION_ID
FROM TRADE.TPE_MESSAGE t
JOIN TRADE.TPE_DEAL_TRANSACTION_MAP m
  ON t.CONTRACT_REF = TO_CHAR(m.TPE_DEAL)
WHERE m.OASYS_DEAL = :deal
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                WHERE x.DEAL = m.OASYS_DEAL)
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'citimlEventType>Amend') > 0
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'termDeposit') = 0
ORDER BY t.MESSAGE_ID DESC;

-- Q5. All fees on the deal (run before and after)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, ROUND(AMOUNT,2) AS AMOUNT,
       PAYMENT_DATE, CURRENCY, DESCRIPTION
FROM TRADE.FEE
WHERE DEAL = :deal
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- Q6. Transactions on the deal (run before and after)
SELECT DEAL, TRANSACTION_ID, TERMINATION_LINK, ORIGINATION_LINK, ENTRY_DATE
FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = :deal
ORDER BY TRANSACTION_ID;

-- Q7. Message processed
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = :message_id;

-- Q8. Same-day maturity fees on the deal, by transaction
--     Flag ON: row on the NEW (latest) transaction. Flag OFF: no row on the new transaction.
SELECT f.DEAL, f.TRANSACTION_ID, f.FEE_NUMBER, f.TYPE, ROUND(f.AMOUNT,2) AS AMOUNT,
       f.PAYMENT_DATE, f.CURRENCY, f.DESCRIPTION,
       CASE WHEN f.TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                     WHERE x.DEAL = f.DEAL)
            THEN 'NEW TXN' ELSE 'OLD TXN' END AS ON_TXN
FROM TRADE.FEE f
WHERE f.DEAL = :deal
  AND f.TYPE = 24
  AND f.PAYMENT_DATE = (SELECT MAX(CURRENT_PROCESS_DATE) FROM REFERENCE_DATA.PROCESS_DATE)
ORDER BY f.TRANSACTION_ID;

-- Q9. Duplicate fees (expect 0 rows)
SELECT TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2) AS AMOUNT, COUNT(*)
FROM TRADE.FEE
WHERE DEAL = :deal
GROUP BY TRANSACTION_ID, TYPE, PAYMENT_DATE, ROUND(AMOUNT,2)
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- Feature flag configuration (only for the flag OFF regression run)
-- ---------------------------------------------------------------------
-- CFG1. Disable the fix
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'FALSE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;

-- CFG2. Re-enable the fix (always run after the flag OFF test)
UPDATE REFERENCE_DATA.CODE SET EXTERNAL_CODE = 'TRUE'
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169' AND CODE = 'Include-C263-119169';
COMMIT;
