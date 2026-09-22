# Staking rewards

SR is one position: actual principal in a staking subtree, eligibility for future funding, and pending reward entitlement. Available rewards stay separately claimable by their owner, including after a complete exit. There are no epochs, locks, maturity dates or promised APR. Each program fixes one reward asset and one positive vesting half-life.

The specification is [Staking Rewards: Allocation, Vesting, and Forfeiture, corrected revision cd55afd](https://github.com/CavalRe/cavalre-multiswap/blob/cd55afd540bdf847bbb3373cc380c24429727c8d/apps/site/blog/2026-09-14-staking-rewards.md).

## Configuration and deployment

Install the existing `LedgerTokenFactory` and `StakingRewardToken` through the Dispatcher alongside Ledger and LedgerView. The existing factory creates internal tokens, share tokens and SR programs; no additional factory module is needed. Keeping creation there also keeps wrapper/share deployment bytecode out of runtime accounting. `IStakingRewardToken` describes the combined Dispatcher API, and `ILedgerTokenFactory` also exposes the creation entry point.

The owner calls `createStakingRewardToken(stakingGroup, rewardGroup, halfLife, metadata)` with absolute registered debit groups. The staking group must be empty and exclusive to this program. Reward backing cannot lie within that same staking subtree. Metadata decimals match the underlying stake ledger. Matching creation is idempotent; a conflicting configuration reverts.

Creation deploys a StakingRewardWrapper, creates a reward backing leaf at `H(rewardGroup, srWrapper)`, and creates a ShareToken backed by that leaf. Its decimals are reward decimals plus 36. All reward shares remain in the single custody leaf `H(rewardShareToken, srWrapper)` until claims burn them. Share supply is authoritative aggregate outstanding units; SR does not store a second unit supply. SR wraps actual staking balances and introduces no principal receipt ledger.

## Balances and notation

| Article quantity | Authoritative representation |
| --- | --- |
| `S_i^j`, eligible holder stake | Actual debit leaf balance beneath `stakingGroup` |
| `S_i`, total eligible stake | Staking group's Ledger balance |
| `U_i`, unclaimed reward backing | Reward backing leaf's Ledger balance |
| `hatU_i`, outstanding reward units | Reward ShareToken supply |
| `hatU_i^j`, holder outstanding units | Lazy holder checkpoint plus allocation accumulator delta |
| `hatP_i^j`, holder pending units | Decayed checkpoint plus pending accumulator delta |
| `hatA_i^j`, holder available units | `hatU_i^j - hatP_i^j` |

Units convert at `U_i / hatU_i`. Funding and claims preserve this ratio in exact arithmetic. Transfers and forfeitures change neither quantity. The cumulative allocation accumulator is history, not another unit supply. Both accumulators retain their history through empty programs and restarts.

`Checkpoint` stores outstanding units, pending units, two accumulator snapshots and time. `Program` stores aggregate pending units, the cumulative outstanding-allocation accumulator, the stored decaying pending-allocation accumulator, and time, alongside immutable configuration. No storage fields, namespaces or packed layouts were changed for this implementation.

The program's existing checkpoint mapping also holds an allocation-residual balance at the **staking-group address**. A group is not a holder: all holder operations reject it. Only that checkpoint's `unclaimedUnits` field is used. It receives integer division residuals, never proportional allocations, and clears on final unstake. `Configuration.allocationRemainderUnits` exposes this balance. The exact outstanding-unit identity is:

```text
reward ShareToken supply = sum(holder outstanding units) + allocation residual units
```

This sum is a test invariant, never a production loop.

## Action ordering

Every affected program advances shared elapsed-time decay, reconstructs affected holders with their old stakes, applies entitlement changes, and saves snapshots before the principal posting. Account ancestry determines which programs are affected; there is no scan of users, programs or funding history.

- **Stake:** checkpoint the receiving leaf before adding principal. New stake receives only subsequent allocations.
- **Fund:** require positive total stake. Issue `F * hatU_i / U_i` shares, or `F * 1e36` when backing and units are both zero. Add issued units as aggregate pending and increment both accumulators by issued units divided by eligible stake. Funding touches no holders.
- **Vest:** pending decays by `2^(-dt / halfLife)`; outstanding units do not decay. Whole half-lives use binary shifts; a fractional half-life uses Solady `expWad`. Stored decaying accumulators avoid exponentials of absolute timestamps. New funding does not restart older vesting.
- **Claim:** redeem all available units, with no partial-claim amount. Principal and holder pending units are unchanged. Backing and ShareToken supply fall together; full redemption clears the backing exactly. Claims and unstaking are separate operations.
- **Unstake with remaining stake:** compute `F_units = x * holderPending / holderStakeBefore` once. Remove that same quantity from holder outstanding and pending units. Increment both accumulators by `F_units / remainingStake`. Credit the actor's retained stake before saving snapshots. Available entitlement stays unchanged. A sole staker's partial exit returns all forfeiture to their retained stake without accelerating vesting.
- **Final unstake:** test zero remaining eligible stake. Make the final staker's pending units available and assign the recorded allocation residual to that position. Do not alter any earlier exited holder's available rewards. Do not increment either allocation accumulator, burn shares or move backing.
- **Transfer:** checkpoint both endpoints. Compute `M_units = x * senderPending / senderStakeBefore` once; subtract it from sender outstanding and pending units and add it to recipient outstanding and pending units. Available balances stay unchanged; unrelated holders receive nothing. No allocation increment or final-staker release occurs, even for a full-supply transfer.

Transfers and ordinary forfeitures never mint, burn or transfer reward custody shares. The only Ledger postings for those actions are principal movements. A full transfer moves all sender pending units exactly. Both ERC20 transfer methods use the same settlement path. Self and zero transfers preserve reward storage while retaining events, balance checks and allowance semantics.

## Rounding and empty states

Raw reward units have `1e36` precision per raw reward-token unit at initialization. Full-precision integer multiplication/division floors partial quantities. Checked overflow reverts; decimals plus 36 must fit uint8, decimal scaling and all uint256 arithmetic must fit.

Funding uses the ShareToken's floored proportional issuance quote **without** cancelling an allocation remainder. If issued units are `Q` and stake is `S`, accumulator increments are `Q / S`, holder allocations sum to `S * (Q / S)`, and the residual `Q % S` stays recorded in the program checkpoint. Funding too small to produce a positive increment reverts atomically.

Forfeiture uses the same rule after debiting the exact computed forfeiture: allocate `S_remaining * floor(F_units / S_remaining)` and retain `F_units % S_remaining` in the program checkpoint. No residual goes to an exited or zero-stake holder. On final unstake the last eligible position receives the residual, analogous to the final-recipient residual rule in existing distribution accounting. A sole-staker partial exit credits the residual directly to that sole recipient's retained stake and keeps its complete pending balance.

Each allocation residual is strictly less than its raw eligible-stake denominator. Its token value is bounded by that denominator times `U_i / hatU_i`; the bound is not an unconditional promise of less than one token atom for arbitrarily large stakes. Choose stake/reward magnitudes appropriate to the 1e36 unit precision. Residuals remain fully backed, cannot be claimed twice, and cannot prevent complete redemption or restart. Their aggregate amount is visible, rather than silently repricing existing units.

Claim payouts floor to raw token atoms, leaving less than one token atom in backing per partial redemption. As in ShareToken redemption, that remainder benefits remaining shares; the final share redemption takes the exact remaining backing. A claim whose entire available entitlement rounds to zero clears those available units through custody cancellation. This is the explicit redemption rounding policy, not forfeiture repricing. Proportional issuance itself can floor by less than one internal unit.

Decay and separate accumulator paths round independently. Negative pending-accumulator deltas caused by precision loss clamp to zero; holder pending is bounded by holder outstanding. Aggregate pending is an independently decayed estimate and can differ from the sum of lazily reconstructed pending balances in final precision digits. Available **units** are always the exact holder difference. Token views independently floor the three conversions, so displayed pending plus available can be one raw atom below displayed unclaimed. The reference tests bound internal-unit errors from allocation quantization and the count of independently rounded decay paths; token-level timing tests allow one raw atom for fractional exponential approximation.

## Reward-token assumptions

Funding and claims move existing Ledger balances; wrap supported external/native assets first and unwrap payouts separately. The fixed-price economic derivation assumes backing changes only through funding and claims. Transfer-tax, rebasing and external custody losses are not normalized by this module.

An authorized internal donation to a live reward backing leaf explicitly raises backing per reward share; future funding uses that live ratio. Public wrappers cannot target that internal leaf. A donation before any units exist produces a mismatched zero state, and ShareToken rejects funding rather than gifting that backing to the next staker. This module exposes no donation-recovery or admin sweep. Consumers must preserve exact backing changes, authorizations and solvency. Tests cover the live donation behavior separately from the fixed-backing model.

## Internal postings and nested SR

`LedgerLib.transfer` walks each endpoint's registered ancestors. For each affected staking group it calls `settleStakeTransfer` through the Dispatcher exactly once, before either principal balance changes. Only the Dispatcher itself can call this selector. Public wrapper authentication and consuming-module authorization remain unchanged. Ledger/Share storage layouts remain unchanged.

A same-program posting carries pending entitlement; leaving a program is an unstake; entering one checkpoints the receiver. Crossing nested or sibling programs applies those rules independently to each affected program. Credit leaves cannot participate in eligible staking balances. All internal consumers must use LedgerLib postings, never edit balance mappings directly. A deployment containing SR programs must retain its settlement selector.

For an SR asset, use its **existing staking subtree**, not accounts beneath its wrapper address. To stake SR again, create an empty nested staking group inside the outer program's staking group. To fund rewards with SR, place the new program's reward group there. The nearest enclosing staking program supplies the wallet-account parent. Principal moves between actual leaves, and the enclosing program's pending entitlement follows that movement. Available outer-program rewards stay on the economic leaf where they vested and can be claimed through an authorized explicit-account consumer.

Wrapper balances and ERC20 events project through each program's direct child custodian. A displayed custody-group balance never authorizes spending or claiming descendant positions. Internal `claim`/`unstake` overloads require the consuming module to authorize the explicit leaf and payout recipient. No public arbitrary-account mutation endpoint was added.

## Validation and downstream integration

Tests include all article examples, transferFrom, full-supply transfers, mixed positions, self/zero storage immutability, re-entry, claims after exit, restart, long inactivity, small integer residuals, custody restrictions, nested stake/reward assets, internal postings and absence of reward-share postings on transfers/forfeiture. An independent eager reference visits three holders over 80 randomized actions; production code uses only shared accumulators and affected-holder checkpoints. Separate fuzz tests check exact supply/custody/backing conservation through repeated claims and final redemption.

Deployment checks assert standard 24,576-byte runtime limits for the runtime module and existing token factory under Solidity 0.8.26, Cancun, optimizer 200. No code-size limit or compiler setting is relaxed.

Deferred to a separate cavalre-multiswap task: update the contracts dependency, register the SR creation selector on the existing token factory and install the SR runtime settlement selector, refresh ABIs/bindings for the appended configuration return field and changed Forfeited event field meaning, update address predictions for current wrapper bytecode, use actual nested staking groups, and remove any duplicate consumer settlement. Revalidate staking, reward funding/claims, indexers and frontend wallet flows there. No files in that repository are changed by this implementation.
