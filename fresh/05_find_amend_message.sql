-- Step 5: find an existing Proteus AMEND message for an FX option that is NOT a term deposit
-- (Copilot: only AmendEventHandler creates Oasys txn N+1, and it returns early for termDeposit on FX_OPTION)
-- Stops after 20 matches. If it runs > 2 minutes, cancel and tell Claude.
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE
WHERE DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>Amend') > 0
  AND DBMS_LOB.INSTR(XML_MESSAGE, 'messageIdScheme="Proteus"') > 0
  AND DBMS_LOB.INSTR(XML_MESSAGE, 'termDeposit') = 0
  AND ROWNUM <= 20;

-- Step 5b: for ONE contract ref from 5 (replace 12345678), see its Oasys deal and transactions
-- Good candidate: map shows 2+ OASYS_TRANSACTION_IDs (an amend already created txn 2 once)
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID, PRODUCT_CLASS, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE TPE_DEAL = '12345678'
ORDER BY CREATED_TIME_STAMP;
