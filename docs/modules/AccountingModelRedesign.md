# Accounting Model Redesign Notes

## Purpose

This document summarizes a design discussion about simplifying and strengthening CavalRe's core ledger model.

Main goals:

- remove asymmetric behavior around a special `Total` account
- preserve strict double-entry invariants
- keep a clear interpretation of root balances in ERC20 terms
- improve auditability without sacrificing accounting correctness

This is a historical design note capturing the discussion that led to the current 2-column model. Some references below describe the pre-refactor state intentionally.

## Quick Ledger Primer (for readers new to `LedgerLib`)

CavalRe organizes accounts in a tree:

- leaf accounts hold balances used by users/tokens
- group accounts aggregate their descendants
- each account has a normal side: `debit` or `credit`

At the time of this discussion, `LedgerLib` stored one balance per account (`mapping(address => uint256) balance`) and used account type plus transfer logic to propagate updates up the tree.

That pre-refactor code also carried asymmetry:

- a special `TOTAL_ADDRESS`
- helper logic like `accountTypeRootAddress(...)`

Those pieces work, but they signal model friction.

## Problem Statement

Desired properties:

- account model should be symmetric for debit and credit branches
- root should have a clean, intuitive meaning
- same-type internal reallocations should cancel early (not necessarily at root)
- no special-case "one side has an extra total bucket" behavior

## Proposed Core Shift: Two Balances Per Account

Instead of one balance, track two:

- `debits[account]`
- `credits[account]`

Posting rule:

- if account is debit-normal, propagate updates through `debits` lineage
- if account is credit-normal, propagate updates through `credits` lineage
- posting polarity (debit operation vs credit operation) changes delta direction, not which side is used

### Why this matters

Under this model:

- `debit -> debit` transfers cancel on debit side at their lowest common ancestor (LCA)
- `credit -> credit` transfers cancel on credit side at their LCA
- same-parent transfers can cancel immediately at that parent
- root only "feels" net cross-side flows

This gives a clean, symmetric propagation story.

## Root Meaning in New Model

Target invariant:

- `root.debits == root.credits`

In ERC20 interpretation (for a token tree):

- `root.debits == root.credits == totalSupply`

So root is not "mystery aggregate." It becomes an explicit reconciliation anchor:

- equal sides prove double-entry balance
- shared value equals ledger-represented token supply

This is the conceptual replacement for separate asymmetric `Total` handling.

## Balance Discipline by Account Type

Proposed per-account inequalities:

- debit-normal account: `debits[a] >= credits[a]`
- credit-normal account: `credits[a] >= debits[a]`

Derived balance:

- debit-normal: `balance(a) = debits[a] - credits[a]`
- credit-normal: `balance(a) = credits[a] - debits[a]`

These constraints make "normal side" explicit and machine-checkable.

## Intermediate (Rejected) Model: Classic Gross Columns

A considered intermediate model was closer to traditional hand-ledger posting:

- every debit posting only increases debit column
- every credit posting only increases credit column
- columns never decrement

Consequence:

- root keeps growing forever on both sides
- invariant `root.debits == root.credits` still holds
- but shared value becomes cumulative turnover, not live supply

This is useful for audit trails, but not ideal if root must represent current token supply.

## Hybrid Idea: Four Columns

To combine supply semantics with stronger auditability, a hybrid was proposed with four monotonic accumulators:

- debit-account debit mutations
- debit-account credit mutations
- credit-account debit mutations
- credit-account credit mutations

Equivalent shorthand per account:

- `dd`, `dc`, `cd`, `cc`

Derived live balances:

- debit-normal live balance from `dd - dc`
- credit-normal live balance from `cc - cd`

### Intended benefit

- keep clean live accounting semantics
- keep rich gross-flow history for forensic/audit analysis

### Key guardrail

Type-domain exclusivity should be strict:

- debit-normal accounts mutate only debit-domain columns (`dd`, `dc`)
- credit-normal accounts mutate only credit-domain columns (`cd`, `cc`)

Without this, interpretation becomes ambiguous quickly.

## Pros and Cons of Moving to Four Columns

### Pros

- stronger onchain auditability (gross inflow/outflow by type and polarity)
- easier statement derivations and reconciliations
- better introspection for unusual flows
- preserves double-entry clarity if invariants are enforced

### Cons

- more storage and gas (extra SLOAD/SSTORE on hot paths)
- larger bug surface (wrong-column routing, missed propagation)
- more complex APIs (what to expose by default vs audit views)
- more invariants to test and reason about

## Relationship to Financial Statement Generation

Discussion also touched how this could support onchain statements:

- balance sheet from live balances
- income statement via account-role classification and period closes
- cashflow statement via cash-touching entries and flow classification

Important point: statement generation requires metadata and posting taxonomy beyond raw columns. Column design helps, but classification policy is equally important.

## Historical Insight Carried Forward

A prior model used a strong routing rule:

- every transaction must touch either retained earnings (`E`) or cash (`C`)

So opaque `A -> B` movement became:

- `A -> E -> B` (performance bridge), or
- `A -> C -> B` (cash bridge)

This forced interpretability for financial statement extraction. That idea remains compatible with the new ledger direction, with careful handling of pure reclassification cases.

## Current Direction

Most aligned direction from discussion:

1. remove asymmetric `Total` handling
2. adopt symmetric debit/credit-side propagation
3. preserve root invariant `root.debits == root.credits == supply`
4. evaluate whether full 4-column onchain audit state is worth gas/storage cost

No code change is included in this note. This document captures conceptual agreement and tradeoffs before implementation.
