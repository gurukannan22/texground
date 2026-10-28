Copy everything below the line into Copilot Chat (Agent mode, tp-javabatch-cbna open). Send Claude screenshots of the answer.

---

In com.citi.tp.applications.fxotradeprocessor.handlers.action.AbstractActionHandler.applyEvent (lines ~442-521),
the fee carry-over code (addAndRemovePastFeeToNewTxn, addFutureDatedMaturityFeeToNewTxn, removeFutureFee) uses
oldTxn = deal.getTransactionByKey(latestTxn) and a new transaction object "transactionDataObj".
Answer from code only, quoting file names and line numbers:

1. Where is transactionDataObj created, and how is its TRANSACTION_ID assigned? When is it a NEW transaction id
   (oldTxn id + 1) versus the SAME id as oldTxn?
2. Which TradeEventType values / event handlers (e.g. AmendEventHandler, Increase, Rollover, Novation, Exercise,
   Termination) are called from applyEvent, and which of them create a new Oasys transaction (txn N+1) on an
   existing deal? Show the code.
3. When the same trade message is reprocessed with the same version (no event), the fees on the existing
   transaction whose DESCRIPTION = contract ref are deleted and rebuilt from the XML. Show the code that deletes /
   rebuilds fees in that case.
4. For an FX_OPTION termDeposit (Proteus FpML, eventType currently "TRADE", isCorrection=false), list exactly which
   XML elements/values must be set (eventType / tradeEvent / contractState / sequenceNumber / version / any amend
   or rollover element) so that applyEvent creates Oasys txn 2 from txn 1 and runs the fee carry-over methods.
5. Is there an existing sample XML or unit test (src/test/resources, *.xml) for such an amend/rollover event on a
   term deposit? Give the file path.
