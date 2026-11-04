-- UAT test deal setup - Step 3: find a UAT deal that already has an AMEND message
-- (FX option, Proteus, not term deposit, not TRS, message for the deal's LATEST txn). Read-only.
-- Limited to the last 2 years and 20 rows to keep it fast. If it runs > 2 min, cancel and tell Claude.
SELECT t.MESSAGE_ID, t.CONTRACT_REF, m.OASYS_DEAL, m.OASYS_TRANSACTION_ID AS LATEST_TXN,
       m.TPE_TRANSACTION_ID AS STORED_VERSION, m.B2B_LEG_ID, t.LAST_UPDATED_TIME_STAMP
FROM TRADE.TPE_MESSAGE t
JOIN TRADE.TPE_DEAL_TRANSACTION_MAP m
  ON t.CONTRACT_REF = TO_CHAR(m.TPE_DEAL)
WHERE t.LAST_UPDATED_TIME_STAMP > SYSDATE - 730
  AND m.PRODUCT_CLASS = 33
  AND m.TRADE_ENTRY_SYSTEM = 'PROTEUS'
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                WHERE x.DEAL = m.OASYS_DEAL)
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'citimlEventType>Amend') > 0
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'termDeposit') = 0
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'TRS_Terms') = 0
  AND ROWNUM <= 20;
