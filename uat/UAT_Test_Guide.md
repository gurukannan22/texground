# C263-119169 – UAT Test Guide

## 1. Why this change

**Production issue:** when an FX option contract is revised (amended), the processor creates a new Oasys transaction and carries fees from the old transaction to the new one. A **maturity fee whose payment date equals the process date** was not carried over and was removed from the old transaction, so it was lost (missing on the new transaction and in downstream messages).

**Root cause:** in `AbstractActionHandler.applyEvent`, past-dated fees are moved and future-dated maturity fees (payment date **after** the process date) are copied to the new transaction, then `removeFutureFee` removes fees dated **on or after** the process date from the old transaction. A maturity fee dated **on** the process date fell between the two rules.

**Fix:** `addAndRemovePastFeeToNewTxn` now also moves **same-day maturity fees** (type 24, payment date = process date) to the new transaction before `removeFutureFee` runs. Non-maturity fees are not affected.

**Feature flag:** `REFERENCE_DATA.CODE`, TYPE = `SAME_DAY_FEE_MIG_C263_119169`, CODE = `Include-C263-119169`. `EXTERNAL_CODE = TRUE` enables the fix; `FALSE` keeps the old behaviour.

## 2. Test scenarios

| # | Scenario | Flag | Expected after contract revision |
|---|---|---|---|
| 1 | Maturity fee, payment date **before** process date | ON | Carried to the new transaction |
| 2 | Maturity fee, payment date **after** process date | ON | Carried to the new transaction |
| 3 | Maturity fee, payment date **equal to** process date | ON | **Moved to the new transaction (not lost)** |
| 4 | Non-maturity fee, payment date equal to process date | ON | Not moved by the fix (unchanged behaviour) |
| 5 | Maturity fee, payment date equal to process date | OFF | Not carried (old behaviour) |

## 3. Test data needed

An **FX option deal (product class 33, not a term deposit)** booked through Proteus, whose **latest transaction** has a **maturity fee (type 24) with payment date = UAT process date**, and an **amendment** (contract revision) for that trade.

Ways to get it in UAT:
- Book/amend through the upstream system (Proteus) so the amendment flows in normally, **or**
- Reprocess an existing amendment message for a qualifying deal via the reprocess job (section 5).

Queries `Q3` and `Q4` in `UAT_Test_Queries.sql` find a qualifying deal and its amendment message.

## 4. Steps – Flag ON

1. **Q1** – confirm the flag is `TRUE`. Screenshot.
2. **Q2** – note the UAT process date. Screenshot.
3. **Q3** – find a qualifying deal (latest transaction has a maturity fee due on the process date). Pick one deal. Screenshot.
4. **Q4** – find the amendment message for that deal's trade. Screenshot.
5. **Q5** – fees on the deal **before** the revision. Screenshot.
6. **Q6** – transactions on the deal **before** the revision (note the latest transaction number = old txn). Screenshot.
7. Trigger the contract revision (section 5). Screenshot the job output (SUCCESS, exit code 0).
8. **Q7** – message status = `MESSAGE_PROCESSING_COMPLETED`. Screenshot.
9. **Q6** again – a new transaction exists; old txn `TERMINATION_LINK` = new txn, new txn `ORIGINATION_LINK` = old txn. Screenshot.
10. **Q8** – the same-day maturity fee (scenario 3) is on the **new** transaction. Screenshot.
11. **Q5** again – fees **after** the revision; check scenarios 1–4 against section 2. Screenshot.
12. **Q9** – no duplicate fees (0 rows). Screenshot.

## 5. Triggering the revision (reprocess job)

1. Put the amendment `MESSAGE_ID` from **Q4** into the reprocessor input file `~/ftp/tp/adhoc/tpfx/Reprocess/ProteusMessageIDs.in` (one ID per line).
2. Force start the Proteus reprocess job for the trade's region (e.g. London: `263_CBNA_PROCESSOR_JAVA_FXO_LN_REPROCESSMESSAGE_R8`, `-Region~LDN_FXO`).
3. Check Standard Output: `Working on MessageID: <id>`, `Total No Of Message Processed: 1`, status SUCCESS, exit code 0.

## 6. Steps – Flag OFF (regression)

1. Set the flag to `FALSE` (configuration change, `CFG1` in the queries file). Run **Q1** to confirm. Screenshot.
2. Repeat section 4 steps 2–12 on a **different** qualifying deal.
3. Expected: the new transaction is created, but the same-day maturity fee is **not** on it (**Q8** returns no row for the new transaction) – the original production behaviour.
4. Set the flag back to `TRUE` (`CFG2`). Run **Q1** to confirm. Screenshot.

## 7. Pass criteria

- Flag ON: same-day maturity fee present on the new transaction with the same type, amount, payment date, currency and description as before; past and future maturity fees carried as before; non-maturity same-day fee not moved; no duplicates; job SUCCESS.
- Flag OFF: same-day maturity fee not carried to the new transaction (old behaviour); other fees as before.

## 8. Out of scope

- `TRS_Terms` strategy trades (different code path).
- FX term deposits (amendments do not create a new transaction for term deposits, C263-35091).
- Same-day **non-maturity** fees (unchanged behaviour).
