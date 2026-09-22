# Staking rewards validation

Validated the public Ledger transfer regression fixes against `9f5b9d18ca68a6c084b53892ea80189e01c996fb`, which includes the nested-SR creation guard and consolidated LedgerTokenFactory. The original accounting baseline was `677321cf20df67783ec04b0e282bd84df6c300cd`. Validation uses Solidity 0.8.26, Cancun and optimizer 200. No deployment, compiler configuration or code-size-limit change was made.

## Commands and results

| Command/check | Result |
| --- | --- |
| Baseline `forge test` | 257 passed, 8 failed |
| `forge test --match-path 'tests/**'` | 281 passed, 0 failed |
| StakingRewardTokenTest suite | 59 passed, 0 failed |
| `forge test --match-contract StakingRewardTokenTest` | Passed, including 256-run fuzz cases |
| Independent eager reference | 256 cases, 80 randomized actions each; no accumulator logic in reference |
| Compiled production runtime and initcode sizes | Below deployment limits under production compiler settings |
| `forge fmt --check` on changed Solidity files | Passed |
| `forge doc` | Passed; unrelated generated-page changes trimmed; relevant source links point to main |
| Project SUMMARY link check | All non-dependency targets exist |
| `git diff --check` | Passed |
| Ledger Store, SR Store/Program/Checkpoint, namespace comparison | Unchanged from baseline |
| cavalre-multiswap scope | No changes made |

The original staking failures covered internal settlement, two nested-SR scenarios, and the 30,090-byte runtime. Internal settlement and deployment size remain covered. Nested SR is now rejected at creation for both stake and reward assets, including reverse creation order and SR wrappers registered as external roots. All six new rejection tests fail against the pre-guard implementation because the invalid creation succeeds, and pass with the guard. Ordinary account nesting and independent programs sharing assets and reward groups remain supported.

## Deployable sizes

| Contract | Runtime bytes | Initcode bytes |
| --- | ---: | ---: |
| Ledger | 18,631 | 19,400 |
| StakingRewardToken | 17,599 | 17,642 |
| LedgerTokenFactory (internal, share and SR creation) | 23,098 | 23,141 |
| StakingRewardWrapper | 3,422 | 4,240 |

The existing LedgerTokenFactory and SR runtime implementations are instantiated and registered through Dispatcher in the tests. Runtime-size assertions enforce the standard 24,576-byte limit; initcode is below 49,152 bytes. Foundry warnings about oversized **test harnesses** do not concern these deployable implementations. Build output also includes dependency lint warnings and two OpenZeppelin AST-source notices. Foundry's optional signature-cache write outside the sandbox warns on some runs; test execution and its results are unaffected.

## Public transfer regressions resolved

The four remaining baseline failures exposed two missing checks in the authenticated public Ledger callback: both parents must equal the token root, and a self-transfer must have sufficient sender balance before the internal no-op. The callback now also validates debit leaves before checking the balance. Internal Ledger postings retain their existing behavior.

All four original tests passed after the production fix, before any test edits. They are retained and strengthened with exact custom-error payloads, allowance rollback, unchanged balances, and checks for both invalid parent endpoints. Three were renamed for clarity:

- `tests/examples/LedgerERC20.t.sol::testCanonicalSelfTransferBalanceAndCallbackAuthentication`: rejects unfunded self-transfers and transferFrom, preserves allowance, permits a zero self-transfer event, and authenticates event callbacks.
- `tests/modules/Ledger.t.sol::testPublicTransferRejectsForeignParents`: rejects foreign source or destination parents without changing balances or supply.
- `tests/modules/LedgerCustody.t.sol::testPublicCustodyRestrictionsAndSelfTransferAllowance`: rejects group endpoints and nested parents, including a zero self-transfer, while preserving custody balances and enforcing self-transfer allowance behavior.
- `tests/modules/ShareToken.t.sol::testShareTokenCustodyProjectionAndPublicRestrictions`: retains custody projection and redemption coverage, rejects excessive self-transfers and transferFrom with allowance rollback, and permits a funded self-transfer.

## Arithmetic and access coverage

The article's exited-holder, partial-unstake, sole-unit-owner versus final-staker, partial/full transfer, mixed-position and continued-funding scenarios pass. Coverage includes claims after exit, restart, self/zero storage immutability, transferFrom allowance handling, full-supply transfers, reserved custody, nested-SR rejection, internal account postings, and no reward-share postings during forfeiture/transfer.

The eager reference updates all three test holders directly on funding, vesting and redistribution. Whole-half-life decay is evaluated by exact shifts independently of production checkpoint reconstruction. Its rounding bound is expressed in internal units and derived from stake-weighted allocation/decay truncation and action count, not an arbitrary token tolerance. Separate fractional-time tests compare checkpoint schedules. Conservation tests account exactly for holder outstanding units plus the exposed allocation residual, reward-share supply/custody, backing and cumulative claims. Final exits and claims clear all backing even with indivisible allocation residuals.

Allocation residuals use the existing non-holder program checkpoint, not an appended storage field. Their final-recipient policy, quantitative bounds, redemption rounding and supported token assumptions are documented in [the staking module](../../modules/staking/README.md). In particular, backing donations explicitly change the live share ratio, mismatched empty states reject funding, and rebasing/transfer-tax/custody-loss normalization is not implemented.

## Deferred integration

cavalre-multiswap remains unchanged, including its pre-existing work. A separate task must update its contracts dependency, register SR creation on the existing token factory and install the SR runtime settlement selector, regenerate ABIs/bindings for the appended configuration return field and Forfeited field semantics, keep SR programs unnested, remove duplicate settlement, and validate frontend and indexer behavior. Contracts were not deployed.
