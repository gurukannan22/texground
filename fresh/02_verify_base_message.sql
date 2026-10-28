-- FRESH START - Step 2: verify the base message after pasting 398871121_base.xml (F11 to commit)
-- Expect: MAT_POS > 0, VER_POS > 0, LEN = 15195
SELECT DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:maturityDate>2021-07-16') AS MAT_POS,
       DBMS_LOB.INSTR(XML_MESSAGE, '<fpml:version>3') AS VER_POS,
       DBMS_LOB.GETLENGTH(XML_MESSAGE) AS LEN
FROM TRADE.TPE_MESSAGE
WHERE MESSAGE_ID = 398871121;
