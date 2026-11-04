# C263-119169 – Which deal can test this fix?

The fix runs only when a **contract revision** creates a **new transaction** on an existing deal.
So the test deal must meet all of these:

## 1. Right kind of deal
- FX option (product class **33**)
- Booked through **Proteus**
- **Not** a term deposit (amendments on term deposits don't create a new transaction)
- **Not** TRS_Terms strategy (uses a different code path)

## 2. Deal already exists
- The deal has a row in `TPE_DEAL_TRANSACTION_MAP` pointing to its **latest** transaction
- The fees to test are on that **latest** transaction

## 3. A revision message
- An **Amend** (or partial unwind) message for the trade
- Its version is **equal to or higher** than the version stored for the trade
- It has a real change, so a **new transaction** is created
  (re-sending the same booking just rebuilds the same transaction – fees are not moved)

## 4. Fees on the latest transaction (compared with the process date)
| Fee | Tests |
|---|---|
| Maturity fee, payment date **= process date** | **The fix (must have)** |
| Maturity fee, payment date **before** process date | Past-dated case |
| Maturity fee, payment date **after** process date | Future-dated case |
| Non-maturity fee, payment date = process date | Fix does not touch it |

## 5. Environment
- Feature flag **TRUE** to test the fix, **FALSE** to see the old behaviour
- Build with the fix (PR #41) deployed
- Know the process date (UAT: **20260306**)

## In one line
> An FX option deal from Proteus, with a maturity fee due on the process date on its latest transaction, that gets an amendment creating a new transaction.
