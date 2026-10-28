-- Step 7: GENERATE the map-row INSERT for deal 2001371316 (copies an existing map row, overrides key fields)
-- Values from amend message 386121612:
--   InternalTradeID 18607953 (trade id) | lifecycleGroupID 17937600 (group) | structureGroupID 35532324 (product no)
--   LegId 0 | message version 9  -> stored version set to 8 so the message (9) is NEWER
--   Oasys deal 2001371316, latest txn 5 (old txn)
SELECT 'INSERT INTO TRADE.TPE_DEAL_TRANSACTION_MAP (' ||
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id) || ') SELECT ' ||
       LISTAGG(CASE column_name
                 WHEN 'TPE_DEAL'             THEN CASE WHEN data_type LIKE '%CHAR%' THEN '''18607953''' ELSE '18607953' END
                 WHEN 'TPE_TRANSACTION_ID'   THEN '8'
                 WHEN 'OASYS_DEAL'           THEN '2001371316'
                 WHEN 'OASYS_TRANSACTION_ID' THEN '5'
                 WHEN 'GROUP_ID'             THEN CASE WHEN data_type LIKE '%CHAR%' THEN '''17937600''' ELSE '17937600' END
                 WHEN 'PRODUCT_NUMBER'       THEN CASE WHEN data_type LIKE '%CHAR%' THEN '''35532324''' ELSE '35532324' END
                 WHEN 'B2B_LEG_ID'           THEN CASE WHEN data_type LIKE '%CHAR%' THEN '''0''' ELSE '0' END
                 WHEN 'PRODUCT_CLASS'        THEN '33'
                 ELSE column_name
               END, ', ') WITHIN GROUP (ORDER BY column_id) ||
       ' FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2001389343 AND TO_CHAR(TPE_DEAL) = ''19038479'' AND TPE_TRANSACTION_ID = 3;' AS STMT
FROM all_tab_columns
WHERE owner = 'TRADE' AND table_name = 'TPE_DEAL_TRANSACTION_MAP';

-- HOW TO USE: run (Ctrl+Enter) -> 1 row. Copy the cell into a new worksheet, add  COMMIT;  press F5.
-- Expect "1 row inserted." + "Commit complete."

-- 7b. Verify (expect 1 row: 18607953 / 8 / 2001371316 / 5 / group 17937600)
SELECT * FROM TRADE.TPE_DEAL_TRANSACTION_MAP WHERE OASYS_DEAL = 2001371316;
