-- UAT future-dated test - deal 2002732532, amend message 153680732 (contract 24201656, London). Read-only.
-- Stored version for 24201656 is 6 (EXERCISE). This amend message is version 4, so it would be treated as OLD.
-- Before deciding on a version bump, look at every versionedTradeId block in the message.

-- 9a. How many version tags of each value
SELECT REGEXP_COUNT(XML_MESSAGE, '<fpml:version>4<') AS V4,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>6<') AS V6,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>7<') AS V7,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>')   AS ALL_VER,
       DBMS_LOB.GETLENGTH(XML_MESSAGE)               AS LEN
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 153680732;

-- 9b. The trade ID blocks (copy the cell into Notepad++ and send a photo)
SELECT DBMS_LOB.SUBSTR(XML_MESSAGE, 3000,
         GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'versionedTradeId') - 100, 1)) AS TRADE_IDS
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 153680732;
