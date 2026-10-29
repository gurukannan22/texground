-- Step 9: change the premium in amend message 386121612 so AmendEventHandler sees a change (-> new txn 6)
-- Premium = 237152.81 (matches existing premium fee type 5 on txn 5). Change to 237152.82.
-- Reversible: REPLACE '237152.82' -> '237152.81'

-- 9a. Count occurrences (expect HITS = 2: <fpml:amount> and <fpml:value> in the premium block)
SELECT REGEXP_COUNT(XML_MESSAGE, '237152\.81') AS HITS
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;

-- 9b. Change premium 237152.81 -> 237152.82 (expect 1 row updated)
UPDATE TRADE.TPE_MESSAGE
SET XML_MESSAGE = REPLACE(XML_MESSAGE, '237152.81', '237152.82')
WHERE MESSAGE_ID = 386121612;
COMMIT;

-- 9c. Verify (expect OLD_HITS = 0, NEW_HITS = same number as 9a)
SELECT REGEXP_COUNT(XML_MESSAGE, '237152\.81') AS OLD_HITS,
       REGEXP_COUNT(XML_MESSAGE, '237152\.82') AS NEW_HITS
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 386121612;
