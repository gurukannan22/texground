Paste everything below the line into Copilot Chat (Agent mode, tp-javabatch-cbna open, main branch).
Send Claude screenshots of the full answer.

---

In com.citi.tp.applications.fxotradeprocessor.handlers.action.AbstractActionHandler, answer from the code only,
quoting file name and line numbers. Say "not found" rather than guess.

1. Show the full body of addFutureDatedMaturityFeeToNewTxn (and any helper it calls). List EVERY condition a fee
   must meet to be copied to the new transaction: fee TYPE, PAYMENT_DATE vs processDate (>, >=), DESCRIPTION /
   contract ref / linked trade checks, isLinkedTradeIsExist, strategy, anything else.
2. Show the full body of removeFutureFee. Which fees does it remove from the old transaction (>= or > processDate)?
3. During an AMEND that creates a new transaction, which method builds fees on the new transaction FROM THE MESSAGE
   (e.g. option premium / maturity fee from FpML)? Show it. Which fee types and dates does it create?
4. Scenario on one FX option deal (single leg, not term deposit, not TRS), process date 20260306, amend creates txn N+1.
   Fees on old txn N:
     A) TYPE 24, PAYMENT_DATE 20261231, DESCRIPTION = this trade's own contract ref, NOT present in the amend message
     B) TYPE 24, PAYMENT_DATE 20261231, DESCRIPTION = a different contract ref (linked trade), NOT in the message
     C) TYPE 24, PAYMENT_DATE 20261231, DESCRIPTION = own contract ref, AND present in the amend message
   For each of A, B, C: does it end up on txn N+1, stay on txn N, or get deleted? Could it be duplicated on txn N+1?
   Name the method and line responsible.
5. For case B, does DESCRIPTION have to match a real linked trade id that exists in TPE_DEAL_TRANSACTION_MAP or in the
   message (e.g. LinkedTradeId), or does any different value work?
