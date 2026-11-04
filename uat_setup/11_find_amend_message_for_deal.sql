-- Find the AMEND message to reprocess for a deal (distinct, latest txn only). Read-only.
-- Replace the deal number:
--   2002732532 -> expect 153680732 (contract 24201656, txn 3)   [future-dated test]
--   2002739527 -> expect 139788789 (contract 16082182)          [same-day / flag OFF test]
SELECT DISTINCT t.MESSAGE_ID, t.CONTRACT_REF, t.STATUS, t.LAST_UPDATED_TIME_STAMP,
       m.OASYS_DEAL, m.OASYS_TRANSACTION_ID
FROM TRADE.TPE_MESSAGE t
JOIN TRADE.TPE_DEAL_TRANSACTION_MAP m
  ON t.CONTRACT_REF = TO_CHAR(m.TPE_DEAL)
WHERE m.OASYS_DEAL = 2002732532
  AND m.OASYS_TRANSACTION_ID = (SELECT MAX(x.TRANSACTION_ID) FROM TRADE.TRANSACTION_TABLE x
                                WHERE x.DEAL = m.OASYS_DEAL)
  AND DBMS_LOB.INSTR(t.XML_MESSAGE, 'citimlEventType>Amend') > 0
ORDER BY t.MESSAGE_ID DESC;
