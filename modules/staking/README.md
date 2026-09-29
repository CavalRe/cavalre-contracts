# Staking rewards

SR tokens are self-wrapped internal ledger roots. A holder's direct debit leaf is eligible stake; there is no deposit into a separate staking group and no public `stake` or `unstake` function. Pool reserves, Surplus, reward backing, and other nested leaves do not earn rewards. Groups and credit accounts never own reward checkpoints.

The wrapper forwards ERC20 transfers to the authenticated `StakingRewards` module. `StakingRewardsLib` performs settlement and accounting. Ledger remains generic: no SR imports, discovery, or hooks. Allowances remain in the wrapper; checkpoints remain in Dispatcher storage.

Pending rewards vest with a half-life. Transfers, burns, and movements out of an eligible holder forfeit proportional pending rewards to remaining eligible stake, excluding incoming tokens. Available rewards stay with the original holder. The final eligible exit releases remaining pending and allocation residuals to the outgoing holder, including when tokens remain in pool reserves. One program has one fixed reward asset. No locks, epochs, or promised APR are introduced.

## Configuration and deployment

Install `LedgerTokenFactory`, `StakingRewards`, Ledger, LedgerView, and TreeView through Dispatcher. The owner calls `createStakingRewardToken(rewardGroup, halfLife, metadata)`. Creation deploys the wrapper, registers its address as an Internal ledger root and creates:

| Account | Kind | Purpose |
| --- | --- | --- |
| `token / Source` | Credit leaf | Offset non-staked balances |
| `token / Stake` | Credit leaf | Total eligible stake |
| `token / Rewards` | Debit group | Container for program reward backing |
| `rewardGroup / token` | Debit leaf | This program's funded reward backing |

`rewardGroup` must be a registered debit group below a ledger root. The standard Rewards group is created before validating this input. Self-rewarding tokens therefore pass `H(predictedToken, H("Rewards"))`; creation and validation remain atomic, with no zero-address sentinel or separate configuration phase. `H(parent, relative)` is Ledger's address derivation: the low 160 bits of the hash of the two packed addresses. `H(name)` is the low 160 bits of the hash of the name bytes. The token prediction uses CREATE2 with the existing metadata salt and `StakingRewardsToken` creation bytecode.

The reward asset may be this SR token or another SR token. Create a self-rewarding USD.cav first, then create CAV using USD.cav's Rewards group. Backing stays below a group and never earns recursively. Shared reward groups still have a distinct backing leaf for each program. Existing non-SR reward ledgers remain supported, including wrapped external/native assets. The reward decimals plus 36 must fit uint8.

Creation fixes metadata, reward group, and a positive half-life. Matching creation is idempotent; conflicting configuration or an occupied predicted address reverts. Each root has exactly one program. The former staking-group creation selector is removed.

A reward ShareToken is backed by the reward leaf. Its decimals are reward decimals plus 36. All issued reward units remain in its single custody leaf `H(rewardShareToken, token)` until claims burn them. This auxiliary ledger measures reward entitlements, not a second copy of stake.

## Balances and checkpoints

| Quantity | Authoritative representation |
| --- | --- |
| Holder eligible stake | Direct debit leaf under the SR root; stored depth 3, with global Root at depth 1 |
| Total eligible stake | Normal credit balance of `token / Stake` |
| ERC20 supply | Ledger's total debit supply, including ineligible balances |
| ERC20 holder balance | Existing direct-custodian projection; displaying a group does not authorize spending it |
| Funded unclaimed rewards | Reward backing leaf |
| Outstanding reward units | Reward ShareToken supply |
| Holder pending/available entitlement | Checkpoint plus accumulator deltas; not user reward-ledger leaves |

`Checkpoint`, `Program`, `Store`, and ERC-7201 layouts remain unchanged. The existing `Program.stakingGroup` slot now holds the token root; the similarly named configuration field is a compatibility alias, not an independently configurable group. `Configuration.totalSupply` reports all tokens and `stakedBalance` reports only eligible stake. The root-keyed checkpoint records allocation residual units and is never a holder.

Existing deployed subtree programs are not migrated by this change. Runtime rejects such configurations rather than interpreting their old group balances as the new root model. Wrapper bytecode and the factory ABI change; integrations must update predictions and selectors.

## Explicit accounting operations

Authorized application modules call `StakingRewardsLib.transfer(token, fromParent, from, toParent, to, amount)`. This operation resolves both accounts, settles eligible positions, posts the movement, and maintains Stake/Source offsets. It accepts explicit accounts for application-owned reserves and credit endpoints for issuance/redemption. Consumers own authorization and any asset backing or slippage checks. Calling generic Ledger directly is not SR-safe and remains a trusted-consumer error; Ledger does not enforce SR policy.

| Movement | Eligible stake | Reward handling |
| --- | --- | --- |
| Direct holder to direct holder | Unchanged | Settle sender exit/forfeiture, then recipient's old balance |
| Holder to reserve/backing | Decreases | Settle exit; preserve available rewards |
| Reserve/backing to holder | Increases | Checkpoint holder before entry |
| Between ineligible accounts | Unchanged | No holder settlement |
| Credit to holder / holder to credit | Increases / decreases | Entry / exit settlement |

Credit reclassification uses ordinary Ledger credit-to-credit postings. It preserves total supply and follows the existing credit-account event projection. A direct posting against Stake is counted once. The wrapper does not emit a duplicate event: Ledger requests the ERC20 event through its existing wrapper callback.

- **Fund:** Move existing reward tokens to `rewardGroup / token`. If the reward asset is SR, use its SR transfer path. Funding from a holder settles exit first, then allocation uses the receiving program's remaining eligible stake. Funding with no eligible recipients reverts atomically. Issue reward units and allocate through the existing accumulators; division residuals remain at the root checkpoint.
- **Claim:** Settle the claimant, redeem all available units, and pay from reward backing. Pending remains with the claimant. An SR payout checkpoints the recipient before adding eligible stake. Claims may target application-owned accounts through an authorized consumer; those accounts do not earn. Public calls only access the caller's direct root leaf.
- **Transfer/exit:** Apply proportional forfeiture and redistribution using pre-movement balances. The recipient's old balance participates; the incoming amount does not. Final eligible exit releases pending and recorded residuals to the sender. No reward units are created or burned by a transfer or ordinary forfeiture.
- **Self/zero transfer:** Preserve reward state, still enforce account restrictions, balance/allowance rules, and emit the ERC20 event.

The existing `reward(token, parent, amount)` and `claim(token, parent)` overloads accept only the reward ledger root. They do not authorize nested custody just because the caller's address matches a child key. The plain overloads select that root automatically. The old public stake/unstake functions and events are removed; application issuance, redemption, and reserve movements express eligibility changes.

## Rounding and empty states

Raw reward units have `1e36` precision per raw reward-token unit at initialization. Full-precision integer multiplication/division floors partial quantities. Checked overflow reverts; decimals plus 36 must fit uint8, decimal scaling and all uint256 arithmetic must fit.

Funding uses the ShareToken's floored proportional issuance quote **without** cancelling an allocation remainder. If issued units are `Q` and stake is `S`, accumulator increments are `Q / S`, holder allocations sum to `S * (Q / S)`, and the residual `Q % S` stays recorded in the program checkpoint. Funding too small to produce a positive increment reverts atomically.

Forfeiture uses the same rule after debiting the exact computed forfeiture: allocate `S_remaining * floor(F_units / S_remaining)` and retain `F_units % S_remaining` in the program checkpoint. No residual goes to an exited or zero-stake holder. On final unstake or full-supply transfer the outgoing position receives the residual, analogous to the final-recipient residual rule in existing distribution accounting. A sole-staker partial exit or transfer credits the residual directly to that sole recipient's retained stake and keeps its complete pending balance.

Each allocation residual is strictly less than its raw eligible-stake denominator. Its token value is bounded by that denominator times `U_i / hatU_i`; the bound is not an unconditional promise of less than one token atom for arbitrarily large stakes. Choose stake/reward magnitudes appropriate to the 1e36 unit precision. Residuals remain fully backed, cannot be claimed twice, and cannot prevent complete redemption or restart. Their aggregate amount is visible, rather than silently repricing existing units.

Claim payouts floor to raw token atoms, leaving less than one token atom in backing per partial redemption. As in ShareToken redemption, that remainder benefits remaining shares; the final share redemption takes the exact remaining backing. A claim whose entire available entitlement rounds to zero clears those available units through custody cancellation. This is the explicit redemption rounding policy, not forfeiture repricing. Proportional issuance itself can floor by less than one internal unit.

Decay and separate accumulator paths round independently. Negative pending-accumulator deltas caused by precision loss clamp to zero; holder pending is bounded by holder outstanding. Aggregate pending is an independently decayed estimate and can differ from the sum of lazily reconstructed pending balances in final precision digits. Available **units** are always the exact holder difference. Token views independently floor the three conversions, so displayed pending plus available can be one raw atom below displayed unclaimed. The reference tests bound internal-unit errors from allocation quantization and the count of independently rounded decay paths; token-level timing tests allow one raw atom for fractional exponential approximation.

## Reward-token assumptions

Funding and claims move existing Ledger balances; wrap supported external/native assets first and unwrap payouts separately. The fixed-price economic derivation assumes backing changes only through funding and claims. Transfer-tax, rebasing and external custody losses are not normalized by this module.

An authorized internal donation to a live reward backing leaf explicitly raises backing per reward share; future funding uses that live ratio. Public wrappers cannot target that internal leaf. A donation before any units exist produces a mismatched zero state, and ShareToken rejects funding rather than gifting that backing to the next staker. This module exposes no donation-recovery or admin sweep. Consumers must preserve exact backing changes, authorizations and solvency. Tests cover the live donation behavior separately from the fixed-backing model.

## Validation and downstream integration

Tests retain the funding, half-life, forfeiture, continued-funding, final-holder, rounding, and randomized eager-reference examples. Former withdrawals now move tokens to ineligible pool reserves. Coverage includes separate total/eligible supply, offset conservation, removed selectors, zero/self transfers, authorization, same-token and cross-SR funding/claims, non-earning pool/reward backing, and no Ledger hooks.

Deployment checks enforce the standard 24,576-byte runtime limit for the SR module and token factory with the existing compiler settings. No work in cavalre-multiswap is included. Its later integration must replace removed factory/runtime selectors and explicitly route SR balance mutations through this library; quote/custody redesign is not part of this change.
