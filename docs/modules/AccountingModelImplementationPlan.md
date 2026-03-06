# Accounting Model Implementation Plan (BS-Only, 2 Columns)

## Scope Lock

- no onchain income statement tracking
- no onchain cashflow statement tracking
- use 2-column state (`debits`, `credits`)
- preserve public UX (`balanceOf`, `totalSupply`) where possible

## Primary Risks

- storage layout change in `LedgerLib.Store` affects all balance code paths
- removal of `TOTAL` touches mint/burn/wrap/unwrap/reallocate routing
- invariants must be re-established with new semantics before optimization

## Target Invariants

- root equality: `root.debits == root.credits`
- ERC20 interpretation: `root.debits == root.credits == totalSupply`
- debit-normal account: `debits[a] >= credits[a]`
- credit-normal account: `credits[a] >= debits[a]`
- transfer remains double-entry balanced

## Phase 1: Storage + Balance Primitives

Files:

- `libraries/LedgerLib.sol`

Changes:

- replace `mapping(address => uint256) balance` with:
  - `mapping(address => uint256) debits`
  - `mapping(address => uint256) credits`
- update `balanceOf(address)` to return net by account type:
  - debit-normal: `debits - credits`
  - credit-normal: `credits - debits`
  - root: either side (must be equal)
- update `hasBalance(address)` to check either column

Exit criteria:

- compiles with no unreachable old `balance` references

## Phase 2: Remove `TOTAL` Asymmetry

Files:

- `libraries/LedgerLib.sol`
- `modules/Ledger.sol`
- `interfaces/ILedger.sol` (only if needed; avoid signature changes)

Changes:

- remove `TOTAL_ADDRESS` usage and `accountTypeRootAddress(...)`
- in `addLedger(...)`, stop creating `"Total"` branch
- route reserve/root registrations directly off root model
- rewrite:
  - `totalSupply(address token)`
  - router-root balance queries
  to use root-side semantics instead of `TOTAL` pathing

Exit criteria:

- no code path depends on `toAddress(token, TOTAL_ADDRESS)`

## Phase 3: Posting Engine Rewrite

Files:

- `libraries/LedgerLib.sol`

Changes:

- rewrite `debit(...)` and `credit(...)`:
  - choose propagation side from leaf account type:
    - debit-normal leaf -> mutate `debits`
    - credit-normal leaf -> mutate `credits`
  - operation polarity sets delta sign (`+`/`-`) on chosen side
  - walk ancestors and update root
  - underflow checks on decrements
- keep `transfer(...)` shape (`credit leg` + `debit leg`) for initial correctness

Exit criteria:

- transfer, mint, burn paths pass core balance invariants

## Phase 4: Flow Routing Updates

Files:

- `libraries/LedgerLib.sol`
- `modules/Ledger.sol`

Changes:

- update `reallocate(...)` to direct-root routing
- update wrap/unwrap/mint/burn parent assumptions that previously used `TOTAL`
- preserve wrapper-facing behavior while separating root registration from optional native/external wrapper creation

Exit criteria:

- wrap/unwrap/mint/burn integration tests pass under new routing

## Phase 5: Tests + Invariant Coverage

Files:

- `tests/modules/Ledger.t.sol`
- any helper test contracts/selectors impacted by removed constants/helpers

Changes:

- replace `TOTAL_ADDRESS` setup/expectations with root-based equivalents
- add focused invariant tests:
  - root equality
  - supply equality with root columns
  - account-type inequality constraints
  - same-type transfer conservation
  - cross-type transfer conservation

Commands:

```bash
forge test --match-path tests/modules/Ledger.t.sol
forge test
```

Exit criteria:

- ledger module tests green
- full suite green

## Non-Goals (for this iteration)

- 4-column onchain audit model
- onchain IS/CF statement generation
- LCA optimization for early-cancel propagation (can be follow-up)
- new external API for raw `debits`/`credits` columns

## Open Decision

- Keep raw columns internal-only for now (recommended), or expose read APIs now.

## Progress Checklist

- [ ] Phase 1 complete
- [ ] Phase 2 complete
- [ ] Phase 3 complete
- [ ] Phase 4 complete
- [ ] Phase 5 complete
