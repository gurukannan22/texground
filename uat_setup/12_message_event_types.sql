-- Show the event type of each message for a contract, straight from the XML. Read-only.
-- Contract 24201656 (deal 2002732532): expect 153680732 = Amend, 153680733 = Exercise (not Amend)
SELECT MESSAGE_ID, CONTRACT_REF,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 80,
         DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>')) AS EVENT_TYPE
FROM TRADE.TPE_MESSAGE
WHERE CONTRACT_REF = '24201656'
ORDER BY MESSAGE_ID;
