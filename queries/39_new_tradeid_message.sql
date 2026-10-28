-- Step 39: message with a NEW trade ID in the SAME lifecycle group -> should allocate Oasys txn 2
-- XML edit (in a copy: 398871121_v4.xml, made from v3):
--   line ~53: <fpml:tradeId tradeIdScheme="InternalTradeID">19038479</fpml:tradeId>
--          -> <fpml:tradeId tradeIdScheme="InternalTradeID">19038480</fpml:tradeId>
--   keep lifecycleGroupID 18350316, versions, maturityDate 2023-03-14 unchanged
-- Paste v4 into XML_MESSAGE for message 398871121 and commit (F11), then run:

-- 39a. Verify the XML (expect all three > 0, LEN about 15195)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, '"InternalTradeID">19038480') AS NEW_ID_POS,
       DBMS_LOB.INSTR(XML_MESSAGE, '"lifecycleGroupID">18350316') AS GROUP_POS,
       DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:maturityDate>2023-03-14') AS MAT_POS,
       DBMS_LOB.GETLENGTH(XML_MESSAGE) AS LEN
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 398871121;

-- 39b. Confirm txn 1 still has the same-day fee (expect fee 1 = 20210416, fee 4 = 20230314)
SELECT DEAL, TRANSACTION_ID, FEE_NUMBER, TYPE, AMOUNT, PAYMENT_DATE, CURRENCY, FX_RATE
FROM TRADE.FEE
WHERE DEAL = 2001389343
ORDER BY TRANSACTION_ID, FEE_NUMBER;

-- After the job run, use queries/36_verify_after_run2.sql
-- (36b now expects a new row: TPE_DEAL 19038480 -> OASYS_TRANSACTION_ID 2)
