-- Add a FUTURE-dated NON-maturity fee (type 5, 777.77, 20261231) on txn 4 of deal 2002739527
-- Expected after the amend (flag ON or OFF): NOT moved to the new txn and removed from the old txn.
--   shouldMoveFeeToNewTxn -> false (future date)
--   addFutureDatedMaturityFeeToNewTxn -> false (type is not 24 / MATURITY)
--   removeFutureFee -> deletes it (payment date >= process date)
-- Run (Ctrl+Enter) -> 1 row. Copy the cell to an empty worksheet, add COMMIT;, F5.
SELECT 'INSERT INTO TRADE.FEE (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'FEE_NUMBER'   THEN '(SELECT MAX(FEE_NUMBER) + 1 FROM TRADE.FEE WHERE DEAL = 2002739527)'
                 WHEN 'TYPE'         THEN '5'
                 WHEN 'PAYMENT_DATE' THEN '20261231'
                 WHEN 'AMOUNT'       THEN '777.77'
                 WHEN 'DESCRIPTION'  THEN '''16082182'''
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.FEE WHERE DEAL = 2002739527 AND TRANSACTION_ID = 4 AND FEE_NUMBER = 2;' AS STMT
FROM all_tab_columns WHERE owner = 'TRADE' AND table_name = 'FEE';
