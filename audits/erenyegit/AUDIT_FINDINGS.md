# Audit Findings (erenyegit)

Short audit notes for issues noticed while reviewing `cavalre-contracts`. Intended as actionable pointers (not a full audit).

---

## Finding 1 — Router `receive()` can revert (missing `handleNative`)

- **Severity**: Critical
- **Where**: `modules/Router.sol` (`receive()` → `INativeHandler(address(this)).handleNative(...)`)
- **Impact**: Sending ETH to the Router address reverts if no module implements/registers `handleNative()`. If native deposits are expected, this is a DoS on ETH reception.
- **Recommendation**: Implement + register `handleNative()` in an appropriate module (e.g. Ledger), or remove/disable `receive()` and document that the Router must not receive ETH directly.

---

## Finding 2 — `ILedger.addSubAccount` boolean parameter name is misleading

- **Severity**: High
- **Where**: `interfaces/ILedger.sol` (`addSubAccount`)
- **Impact**: The interface named the boolean `isInternal`, but the implementation uses it as the credit/debit-side flag for the double-entry tree. Integrators could pass the wrong value and register accounts on the wrong side.
- **Recommendation**: Rename the parameter to `isCredit` and add NatSpec clarifying semantics.
- **Status**: Fixed in PR #18.

---

## Finding 3 — `subAccountIndex` (1-based) vs `subAccount` (0-based) mismatch

- **Severity**: Medium
- **Where**: `libraries/LedgerLib.sol`
- **Impact**: `subAccountIndex` is stored/returned as 1-based, while array access is 0-based. Combining them without `-1` leads to off-by-one errors.
- **Recommendation**: Make indexing consistent (prefer 0-based) or explicitly document the 1-based behavior and provide a safe helper.

---

## Finding 4 — `ERC20Wrapper.mint/burn` only emit events

- **Severity**: Low
- **Where**: `modules/Ledger.sol` (`ERC20Wrapper.mint`, `ERC20Wrapper.burn`)
- **Impact**: These functions emit ERC-20 `Transfer` events but do not mutate balances. Correct behavior relies on Ledger state changes happening elsewhere, then calling these to mirror events.
- **Recommendation**: Add NatSpec clarifying that these are event-only hooks and must be paired with Ledger balance mutations.

---

## Finding 5 — `addExternalToken` makes external metadata calls

- **Severity**: Low
- **Where**: `libraries/LedgerLib.sol` (`addExternalToken`)
- **Impact**: Calls `IERC20Metadata(token).name()/symbol()/decimals()`. A malicious token could behave unexpectedly (incl. reentrancy into the router via callbacks).
- **Recommendation**: Only add trusted tokens; consider a simple “malicious token metadata” test and/or defensive patterns if desired.

