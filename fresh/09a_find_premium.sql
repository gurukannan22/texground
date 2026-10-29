-- Step 9a (retry): show the premium paymentAmount block in amend message 386121612
SELECT DBMS_LOB.SUBSTR(XML_MESSAGE, 500,
         DBMS_LOB.INSTR(XML_MESSAGE, 'paymentAmount', DBMS_LOB.INSTR(XML_MESSAGE, 'fpml:premium'))) AS PREMIUM_AMOUNT
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;
