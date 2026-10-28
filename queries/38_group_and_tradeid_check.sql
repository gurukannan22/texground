-- Step 38: check the group / trade IDs the processor matches on
-- The code reuses an Oasys txn when a map row has the same GROUP_ID + TPE_DEAL (trade ID) + B2B_LEG_ID.
-- It allocates a NEW Oasys txn (max + 1) only when the trade ID is new within the group.

-- 38a. Map rows for the deal, with group and leg (expect GROUP_ID = 18350316 for both)
SELECT TPE_DEAL, TPE_TRANSACTION_ID, OASYS_DEAL, OASYS_TRANSACTION_ID,
       GROUP_ID, B2B_LEG_ID, PRODUCT_CLASS, PRODUCT_NUMBER, TRADE_EVENT, CREATED_TIME_STAMP
FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE OASYS_DEAL = 2001389343
ORDER BY CREATED_TIME_STAMP;

-- 38b. Is a candidate new trade ID free? (expect 0 rows before we use it)
SELECT * FROM TRADE.TPE_DEAL_TRANSACTION_MAP
WHERE TPE_DEAL = '19038480';
