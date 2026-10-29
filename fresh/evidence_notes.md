# C263-119169 – Test Evidence Notes

Copy each note under its screenshot in the evidence document.

---

## Overall Summary (top of document)

> Fix for C263-119169: during a contract revision, a maturity fee whose payment date equals the process date was not carried to the new transaction and was lost. The fix moves same-day maturity fees to the new transaction, controlled by feature flag SAME_DAY_FEE_MIG_C263_119169 / Include-C263-119169.
> Tested in TPFXDEV with build 1.0.0-main-2175 on deal 2001371316 (FX option, Proteus, London) by reprocessing amendment message 386121612 with the flag ON and OFF.
> Result: Flag ON – same-day maturity fee retained on the new transaction (PASS). Flag OFF – same-day maturity fee lost, reproducing the production issue (PASS).

---

## 6. Feature Flag ON (Fix enabled)

**Purpose**
> This run processes a contract revision (amendment) with the feature flag ON to confirm that maturity fees due on the process date are moved to the new transaction and not lost.

### 6.1 Pre-conditions

**Flag query (TRUE)**
> Feature flag SAME_DAY_FEE_MIG_C263_119169 / Include-C263-119169 = TRUE (fix enabled).

**Process date**
> Dev process date = 20230314. Fees with this payment date are same-day fees.

**Build**
> TPFXDEV is running build 1.0.0-main-2175 (current, deployed 28-Oct-2026), which includes the C263-119169 change.

**PaymentEnumeration**
> Fee type 24 = MATURITY (PaymentEnumeration.MATURITY).

**Deal selection (1c)**
> Test deal 2001371316 selected: FX option (Proteus, London) deal whose latest transaction (txn 5) holds a maturity fee (111.11) due on the process date 20230314, with an amendment message pending.

**Message selection (1d)**
> Amendment message 386121612 (contract 18607953) selected for reprocessing — latest Amend message for the trade on the deal's latest transaction (txn 5).

### 6.2 Before Job Run

**Fees before (2a)**
> Before the run, transaction 5 (latest) holds:
> • 444.44, maturity, 20220101 – past-dated
> • 111.11, maturity, 20230314 – same-day (payment date = process date)
> • 222.22, maturity, 20231231 – future-dated
> • 237152.81, option premium
> • 333.33, non-maturity (type 5), 20230314 – same-day
> Transaction 3 holds an unrelated fee (−54294.54).

**Transactions before (2b)**
> Transaction 5 is the latest live transaction (no termination link). Transaction 6 does not exist yet.

**Expected results**

| Fee | Payment date | Expected after revision |
|---|---|---|
| 444.44 maturity | 20220101 (past) | Moved to new txn 6 |
| 222.22 maturity | 20231231 (future) | Moved to new txn 6 |
| **111.11 maturity** | **20230314 (same day)** | **Moved to new txn 6 (the fix)** |
| 333.33 type 5 | 20230314 (same day) | Not moved (fix is maturity-only) |
| Option premium | – | Rebuilt on txn 6 from the message |

### 6.3 Execution

**ProteusMessageIDs.in**
> Reprocessor input file ProteusMessageIDs.in set to message 386121612.

**Autosys job output**
> Job 263_CBNA_PROCESSOR_JAVA_FXO_LN_REPROCESSMESSAGE_R8 force started on 29-Oct-2026 00:23 (server time), Region LDN_FXO, with the feature flag ON. Status SUCCESS, exit code 0, message 386121612 processed (1 message).

**Message status (3a)**
> Message 386121612 processed successfully (MESSAGE_PROCESSING_COMPLETED).

### 6.4 After Job Run

**New transaction (4a)**
> The amendment created new transaction 6 from transaction 5 (txn 5 TERMINATION_LINK = 6, txn 6 ORIGINATION_LINK = 5).

**S1 – past**
> Scenario 1 – payment date before process date: maturity fee 444.44 (20220101) carried to new transaction 6. PASS

**S2 – future**
> Scenario 2 – payment date after process date: maturity fee 222.22 (20231231) carried to new transaction 6. PASS

**S3 – same-day maturity**
> Scenario 3 – payment date equal to process date: same-day maturity fee 111.11 (20230314) moved to new transaction 6 and not lost. This is the C263-119169 fix. PASS

**S4 – same-day non-maturity (0 rows)**
> Negative check – same-day non-maturity fee 333.33 (type 5) is not moved by the fix (fix applies to maturity fees only). PASS

**S5 – old transaction (0 rows)**
> Old transaction 5 has no fees left after the revision — all maturity fees moved to transaction 6, none left behind. PASS

**All fees after (6a)**
> After the amendment, all maturity fees (past, same-day, future) moved from transaction 5 to new transaction 6. The same-day maturity fee 111.11 (payment date = process date 20230314) is retained on transaction 6 — the fix for C263-119169. The option premium is rebuilt on transaction 6 from the message. The same-day non-maturity fee is not moved, as designed.

**Duplicates (6b, 0 rows)**
> No duplicate fees on the deal after the move. PASS

### 6.5 Flag ON Summary

| Scenario | Expected | Actual | Result |
|---|---|---|---|
| Payment date before process date | Carried to new txn | 444.44 on txn 6 | Pass |
| Payment date after process date | Carried to new txn | 222.22 on txn 6 | Pass |
| **Payment date = process date** | **Moved to new txn, not lost** | **111.11 on txn 6** | **Pass** |
| Same-day non-maturity | Not moved | Not on txn 6 | Pass |
| Contract revision | New txn created | Txn 6 created from txn 5 | Pass |
| Old transaction | No fees left | 0 fees on txn 5 | Pass |
| Duplicates | None | 0 rows | Pass |
| Job execution | SUCCESS | SUCCESS, exit 0 | Pass |

---

## 7. Feature Flag OFF (Regression – behaviour without the fix)

**Purpose**
> This run repeats the same contract revision with the feature flag turned OFF to confirm that, without the fix, the same-day maturity fee is lost (production behaviour), and that the fix is controlled by the feature flag.

### 7.1 Pre-conditions

**Flag query (FALSE)**
> Feature flag SAME_DAY_FEE_MIG_C263_119169 / Include-C263-119169 set to FALSE (fix disabled).

**Process date**
> Dev process date = 20230314. Fees with this payment date are same-day fees.

**Deal selection (2c)**
> Test deal 2001371316 selected: FX option (Proteus, London) deal whose latest transaction (txn 6) holds a maturity fee (111.11) due on the process date 20230314, with an amendment message pending.

**Message selection (2d)**
> Amendment message 386121612 (contract 18607953) selected for reprocessing — latest Amend message for the trade on the deal's latest transaction (txn 6).

### 7.2 Before Job Run

**Fees before (3a)**
> Before the run, transaction 6 (latest) holds:
> • 444.44, maturity, 20220101 – past-dated
> • 111.11, maturity, 20230314 – same-day (payment date = process date)
> • 222.22, maturity, 20231231 – future-dated
> • 237152.82, option premium
> • 333.33, non-maturity (type 5), 20230314 – same-day
> Transaction 3 holds an unrelated fee (−54294.54).

**Transactions before (3b)**
> Transaction 6 is the latest live transaction (no termination link). Transaction 7 does not exist yet.

### 7.3 Execution

**ProteusMessageIDs.in**
> Reprocessor input file ProteusMessageIDs.in set to message 386121612.

**Autosys job output**
> Job 263_CBNA_PROCESSOR_JAVA_FXO_LN_REPROCESSMESSAGE_R8 force started on 29-Oct-2026 01:13 (server time) with the feature flag OFF. Status SUCCESS, exit code 0, message 386121612 processed (1 message).

### 7.4 After Job Run

**New transaction (5a)**
> The amendment created new transaction 7 from transaction 6 (txn 6 TERMINATION_LINK = 7, txn 7 ORIGINATION_LINK = 6).

**S1 – past (5b)**
> Past-dated maturity fee 444.44 (20220101) carried to new transaction 7 — unchanged behaviour.

**S2 – future (5c)**
> Future-dated maturity fee 222.22 (20231231) carried to new transaction 7 — unchanged behaviour.

**S3 – same-day maturity (5d, 0 rows)**
> Same-day maturity fee 111.11 (payment date = process date 20230314) not found on any transaction after the revision — fee lost. This reproduces the production issue when the fix is disabled.

**All fees after (5e)**
> With the feature flag OFF, the same-day maturity fee 111.11 is not carried to new transaction 7 and is lost. Past (444.44) and future (222.22) maturity fees are carried as before. This reproduces the production issue and confirms the fix is controlled by the feature flag.

### 7.5 Post-test

**Flag query (TRUE)**
> Feature flag restored to TRUE after testing.

### 7.6 Flag OFF Summary

| Fee | Payment date | Expected (flag OFF) | Actual | Result |
|---|---|---|---|---|
| 444.44 maturity | 20220101 (past) | Carried to txn 7 | On txn 7 | Pass |
| 222.22 maturity | 20231231 (future) | Carried to txn 7 | On txn 7 | Pass |
| **111.11 maturity** | **20230314 (same day)** | **Lost (old behaviour)** | **Not found** | **Pass (bug reproduced)** |
| Contract revision | – | New txn created | Txn 7 created | Pass |
| Job execution | – | SUCCESS | SUCCESS, exit 0 | Pass |

---

## 8. Final Summary (end of document)

| Scenario | Flag | Expected | Actual | Result |
|---|---|---|---|---|
| Payment date before process date | ON | Carried to new txn | 444.44 on txn 6 | Pass |
| Payment date after process date | ON | Carried to new txn | 222.22 on txn 6 | Pass |
| **Payment date = process date** | **ON** | **Moved to new txn** | **111.11 on txn 6** | **Pass** |
| Same-day non-maturity | ON | Not moved | Not on txn 6 | Pass |
| Payment date = process date | OFF | Fee lost (old behaviour) | 111.11 missing on txn 7 | Pass |
| Job execution | ON / OFF | SUCCESS | SUCCESS, exit 0 | Pass |
