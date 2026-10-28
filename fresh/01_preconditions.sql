-- FRESH START - Step 1: pre-conditions (run each, screenshot each)

-- 1a. Feature flag value (expect EXTERNAL_CODE = TRUE)
SELECT TYPE, CODE, EXTERNAL_CODE
FROM REFERENCE_DATA.CODE
WHERE TYPE = 'SAME_DAY_FEE_MIG_C263_119169';

-- 1b. Dev process date (expect 20230314)
SELECT * FROM REFERENCE_DATA.PROCESS_DATE;
