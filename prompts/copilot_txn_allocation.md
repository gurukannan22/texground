Copy everything below the line into Copilot Chat (with the tp-javabatch-cbna project open).
Paste Copilot's full answer back to Claude.

---

I am testing a fix in com.citi.tp.applications.fxotradeprocessor.handlers.action.AbstractActionHandler
(method addAndRemovePastFeeToNewTxn, called from applyEvent). For an FXO Proteus termDeposit trade,
I need to make the processor create a NEW Oasys transaction (txn 2) on an existing Oasys deal, so
that applyEvent runs with oldTxn = txn 1. Answer the questions below using only the code in this
repo. For each answer, quote the exact code lines with file name and line numbers. Do not guess;
say "not found" if you cannot find it.

1. AbstractActionHandler: show the declaration and default value of the field isLatestTxn, and every
   place it is set (setLatestTxn calls), including in setTransactionIDForGroupID and loadTCDealData.
   In the "Allocate New Transaction" else-branches of setTransactionIDForGroupID, what is isLatestTxn
   left as?

2. Show the full body of isTxnExist(), isDealExist(), and isApplyEvent(TradeMessageInfo). Explain what
   each one checks.

3. Show the full body of applyAction(...) and the code at lines ~440-460 that uses
   "!(isDealExist() && isTxnExist())" and "if (isDealExist() && isTxnExist())". Trace which branch
   runs, and whether applyEvent is called, in this scenario:
   - map rows exist with the same GROUP_ID (lifecycleGroupID) as the message,
   - but no map row has the message's trade ID (T_E_DEAL) + B2B leg ID,
   - so setTransactionIDForGroupID allocates latestTxn = max + 1.

4. TradeMessageInfo.setTradeIDAndVersion() and any related setters: show the full method. For each
   field (tradeID, tradeVersion, groupID, b2bLegID, productID), list which FpML element and which
   tradeIdScheme value it is read from (e.g. versionedTradeId with scheme "InternalTradeID",
   "lifecycleGroupID", "LegId", partyTradeIdentifier tradeId with PRODUCT_NUMBER_ATTRIBUTE).
   Show the values of the constants GROUP_ID_ATTRIBUTE, B2B_LEG_ID_ATTRIBUTE,
   PRODUCT_NUMBER_ATTRIBUTE and any TRADE_ID / version scheme constants in
   com.citi.tp.applications.fxotradeprocessor.utils.Constants.

5. loadTCDealData(TradeMessageInfo): show the full method. How does it find the existing Oasys deal
   (by group ID, trade ID, product number?) and which map rows does it pass to
   setTransactionIDForGroupID?

6. When a NEW Oasys transaction is allocated, which code inserts the new row in
   TPE_DEAL_TRANSACTION_MAP, and which code decides the oldTxn passed to applyEvent
   (deal.getLatestTxn or similar)? Show it.

7. Is there any other check that would reject or skip a message whose trade ID is new but whose
   group ID already exists (duplicate checks, contractState, eventType, sequenceNumber,
   isCorrection, IsFINAmend, TRS strategy, product class FX_OPTION vs termDeposit)? List them with
   code.

8. In applyEvent, show the full code from the start of the method to the call of
   addAndRemovePastFeeToNewTxn, addFutureDatedMaturityFeeToNewTxn and removeFutureFee, and the full
   body of addAndRemovePastFeeToNewTxn, shouldMoveSameDayMaturityFee (or equivalent) and
   copyFeeToTransaction. Also show how fees are built for the NEW txn from the message (which method
   creates Fee rows from termDeposit maturityDate/principal).

9. Find the unit test(s) covering the SAME_DAY fee feature flag (e.g. AbstractActionHandlerTest
   around line 251). List the test method names and what each asserts.

Finish with a short summary: "To make the processor allocate Oasys txn 2 and run applyEvent, the
message must have: ..." listing the exact XML elements/values that must change or stay the same.
