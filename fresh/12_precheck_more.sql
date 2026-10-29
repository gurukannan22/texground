-- Step 12: two more pre-run checks (read-only)

-- 12a. originatingEvent: where is it and what value? (Copilot: must be 'Amendment' for TradeActionType.AMENDMENT)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, 'originatingEvent')          AS ORIG_POS,
       DBMS_LOB.INSTR(XML_MESSAGE, 'nonpublicExecutionReport')  AS NPER_POS,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 400, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'originatingEvent') - 150, 1)) AS ORIG_TXT,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 400, 1) AS MSG_START
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 386121612;

-- 12b. Oasys transactions for the deal (expect txns up to 5, nothing above 5)
SELECT * FROM TRADE.TRANSACTION_TABLE
WHERE DEAL = 2001371316
ORDER BY 2;
