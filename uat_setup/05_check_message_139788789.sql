-- UAT test deal setup - Step 5: check amend message 139788789 (deal 2002739527, contract 16082182). Read-only.
-- Expect: AMEND > 0, TD = 0, TRS = 0, one of LDN / NY > 0, VER8 >= 1 (version must be >= 8 stored in map)
SELECT MESSAGE_ID,
       DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>Amend') AS AMEND,
       DBMS_LOB.INSTR(XML_MESSAGE, 'termDeposit')           AS TD,
       DBMS_LOB.INSTR(XML_MESSAGE, 'TRS_Terms')             AS TRS,
       DBMS_LOB.INSTR(XML_MESSAGE, 'CTLON')                 AS LDN,
       DBMS_LOB.INSTR(XML_MESSAGE, 'CTNY')                  AS NY,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>8<')        AS VER8,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>')          AS VER_TAGS,
       DBMS_LOB.GETLENGTH(XML_MESSAGE)                      AS LEN
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 139788789;

-- 5b. Version and entity text (copy cells to Notepad++ if VER8 = 0)
SELECT DBMS_LOB.SUBSTR(XML_MESSAGE, 1500, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'versionedTradeId') - 100, 1)) AS TRADE_IDS,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 300, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'portfolioLegalVehicle') - 50, 1)) AS ENTITY_TXT
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 139788789;
