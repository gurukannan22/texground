-- UAT test deal setup - Step 2: find a revision message for deal 2002738453 (contract 24355195). Read-only.

-- 2a. Feature flag (expect TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 2b. All messages for the contract, with event type, version and region checks
SELECT MESSAGE_ID, CONTRACT_REF, STATUS, LAST_UPDATED_TIME_STAMP,
       DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>Amend')        AS AMEND,
       DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>PartialUnwind') AS PUNWIND,
       DBMS_LOB.INSTR(XML_MESSAGE, 'termDeposit')                  AS TD,
       DBMS_LOB.INSTR(XML_MESSAGE, 'TRS_Terms')                    AS TRS,
       DBMS_LOB.INSTR(XML_MESSAGE, 'CTLON')                        AS LDN,
       DBMS_LOB.INSTR(XML_MESSAGE, 'CTNY')                         AS NY,
       DBMS_LOB.GETLENGTH(XML_MESSAGE)                             AS LEN
FROM TRADE.TPE_MESSAGE
WHERE CONTRACT_REF = '24355195'
ORDER BY MESSAGE_ID;

-- 2c. Event type + version text of each message (copy cells to Notepad++ if needed)
SELECT MESSAGE_ID,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 200, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType') - 20, 1)) AS EVENT_TXT,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 200, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:version>') - 20, 1))  AS VERSION_TXT,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 200, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'portfolioLegalVehicle') - 20, 1)) AS ENTITY_TXT
FROM TRADE.TPE_MESSAGE
WHERE CONTRACT_REF = '24355195'
ORDER BY MESSAGE_ID;
