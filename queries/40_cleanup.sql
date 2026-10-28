-- Step 40: cleanup after testing
-- FIRST: paste 398871121_original.xml back into XML_MESSAGE for message 398871121, press F11.

-- 40a. Verify original XML is back (expect MAT_POS > 0, VER3_POS = 0, LEN = 15195)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:maturityDate>2021-07-16') AS MAT_POS,
       DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:version>3') AS VER3_POS,
       DBMS_LOB.GETLENGTH(XML_MESSAGE) AS LEN
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 398871121;

-- 40b. Restore the maturity fee date to the original 20210716 (expect 1 row updated)
UPDATE TRADE.FEE
SET PAYMENT_DATE = 20210716
WHERE DEAL = 2001389343
  AND TRANSACTION_ID = 1
  AND PAYMENT_DATE = 20230314;
COMMIT;

-- 40c. Final state for the evidence doc (expect fee 1 = 20210416, other fee = 20210716)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- Note: the map row TPE_DEAL 19038479 / TPE_TRANSACTION_ID 3 (created by Run 2) is left in place.
-- Mention it in the doc; do not delete map rows without the team's OK.
-- Also restore ProteusMessageIDs.in to 2001520760 via Tectia.
