-- Step 11: PRE-RUN CHECKS (no changes, read-only). Run each, note the result.

-- 11a. Flag ON (expect EXTERNAL_CODE = TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 11b. Process date (expect 20230314)
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;

-- 11c. Message event + version checks (expect: EVT>0, ORIG>0, TD=0, TRS=0, VER9>=1, PREM_NEW=6, PREM_OLD=0)
SELECT DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType>Amend')      AS EVT,
       DBMS_LOB.INSTR(XML_MESSAGE, 'originatingEvent>Amend')     AS ORIG,
       DBMS_LOB.INSTR(XML_MESSAGE, 'termDeposit')                AS TD,
       DBMS_LOB.INSTR(XML_MESSAGE, 'TRS_Terms')                  AS TRS,
       REGEXP_COUNT(XML_MESSAGE, '<fpml:version>9<')             AS VER9,
       REGEXP_COUNT(XML_MESSAGE, '237152\.82')                   AS PREM_NEW,
       REGEXP_COUNT(XML_MESSAGE, '237152\.81')                   AS PREM_OLD,
       STATUS
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 386121612;

-- 11d. Event / strategy text (copy cells to Notepad++ if EVT or ORIG = 0)
SELECT DBMS_LOB.SUBSTR(XML_MESSAGE, 300, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'citimlEventType') - 50, 1)) AS EVENT_TXT,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 300, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'originatingEvent') - 50, 1)) AS ORIG_TXT,
       DBMS_LOB.SUBSTR(XML_MESSAGE, 300, GREATEST(DBMS_LOB.INSTR(XML_MESSAGE, 'strategyName') - 50, 1)) AS STRATEGY_TXT
FROM TRADE.TPE_MESSAGE WHERE MESSAGE_ID = 386121612;

-- 11e. Map row (expect 1 row: 18607953 / 8 / 2001371316 / 5)
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID, GROUP_ID, PRODUCT_NUMBER, B2B_LEG_ID, PRODUCT_CLASS
FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2001371316;

-- 11f. Which TRADE tables hold the Oasys transactions? (to confirm txn 5 exists and is the latest)
SELECT table_name FROM all_tables
WHERE owner = 'TRADE' AND (table_name LIKE '%TRANSACTION%' OR table_name LIKE '%DEAL%')
ORDER BY table_name;
