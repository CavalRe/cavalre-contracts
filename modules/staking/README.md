# StakingRewardToken

SR wraps actual staking-token accounts beneath a configured debit group. Configuration consists of absolute `stakingGroup` and `rewardGroup` addresses, a fixed positive half-life, and wrapper metadata. Ledger derives both underlying assets from the groups. The SR wrapper has no principal ledger or principal conversion ratio.

## Implementation status

The direct-account refactor is in progress. Nested SR asset accounting is awaiting design review. The composed creation path currently makes StakingRewardToken exceed the EIP-170 runtime limit; deployment is blocked until creation is separated from runtime accounting. Custom deep transfers still require explicit settlement in their consuming module. Initial reward donations remain under review; the current shared issuance path requires both reward supply and prior backing to be zero at initialization.

## Setup and use

1. Register empty staking and reward groups on the relevant underlying ledgers. The reward backing branch must not lie inside this program's staking group.
2. The SR owner calls `createStakingRewardToken(stakingGroup, rewardGroup, halfLife, metadata)`. It returns the ERC20 wrapper address. The metadata decimals must match the staking token's raw units.
3. User stakes live at `H(stakingGroup, user)`. `stake` and `unstake` transfer the actual underlying tokens between wallet accounts and staking accounts. The existing minimum-amount arguments remain in the ABI; amounts have no principal-share conversion.
4. Wrapper `balanceOf` reads the user's staking account. `totalSupply` reads the staking group's normal aggregate balance, excluding other programs and unstaked tokens.
5. Wrapper transfers directly invoke SR settlement before moving the actual stakes. The SR wrapper emits its own ERC20 mint, burn, and transfer events, while Ledger emits the underlying asset's custody events.

Creation also registers the program's reward backing leaf at `H(rewardGroup, srWrapper)`, creates a ShareToken backed by that leaf, and registers one SR custody leaf at `H(rewardShareToken, srWrapper)`. All outstanding reward shares remain in that custody account. Reward-share supply is the authoritative aggregate outstanding-unit balance; users' reward entitlements remain lazy SR checkpoints.

The reward ShareToken has the reward asset's decimals plus 36, preserving the existing raw `1e36` reward-unit precision. Both decimals and the resulting quantities must fit their Solidity types. Funding first moves and verifies backing, then issues reward shares. SR removes any issuance remainder that cannot be allocated as an integral number of units per raw stake, preserving exact allocation conservation. Claims redeem custody shares; zero-payout claims clear them through an authorized custody burn. Forfeiture uses one combined custody burn without releasing backing.

Metadata uses `TokenMetadata`: name, symbol, decimals, and version. Matching creation requests are idempotent. A different configuration for the same wrapper identity reverts. The staking group must begin empty and cannot be reserved by another program. Reward-share metadata derives a program-specific identity from the SR wrapper address. All creation remains trusted internal library composition; an installed LedgerTokenFactory module is not required by this draft.

Operations move existing Ledger balances. Wrap external or native assets before staking and unwrap them after withdrawal. Ordinary share tokens can supply those balances. Staking and rewards may use the same underlying ledger, with separate account contexts. Nested SR wrappers require the separate accounting decision described above.

## Accounting

The [unit-first derivation](https://caval.re/blog/staking-rewards) defines the accumulators and action rules. Hats denote reward **units**; unhatted rewards are amounts of `R`. In particular, $U_i$ is unclaimed reward-token backing and $\hat U_i$ is outstanding unclaimed units. Neither is cumulative funding $T_i$.

### Stored and derived values

Each holder stores a five-field `Checkpoint`. Aggregate views construct the same shape using ShareToken supply and the four stored aggregate reward fields. For a holder, the accumulators are snapshots of the shared accumulators at that holder's last checkpoint.

| Checkpoint field | Aggregate notation | Holder notation |
| --- | --- | --- |
| `unclaimedUnits` | $\hat U_i$, derived from reward ShareToken supply. | $\hat U_i^j$ |
| `pendingUnits` | $\hat P_i$ | $\hat P_i^j$ |
| `unclaimedAccumulator` | $\phi_i^{\hat U}$ | Saved $\phi_i^{\hat U}$ |
| `pendingAccumulator` | $e^{-rt}\phi_i^{\hat P}$ | Saved $e^{-rt}\phi_i^{\hat P}$ |
| `updatedAt` | Aggregate checkpoint time | Holder checkpoint time |

Here $r=\ln(2)/h$. `pendingAccumulator` stores the decaying form, so the implementation uses elapsed time and never evaluates an ever-growing $e^{rt}$. Aggregate `pendingUnits` is retained for constant-time aggregate pending/available views; the core action amounts do not depend on it.

Ledger supplies actual aggregate stake $S_i$, each staking-account balance $S_i^j$, reward backing $U_i$, and reward ShareToken supply $\hat U_i$. SR stores aggregate pending units, the two accumulators, and their timestamp; each holder retains the five-field checkpoint. Cumulative funding $T_i$ and claims $C_i$ are not stored; reward, claim, and Ledger events supply historical accounting. Available units, per-unit value, and holder token amounts are derived.

`Rewards.unclaimedUnits` and `Rewards.unclaimed` expose current outstanding units and their token value. They replace the former `totalUnits` and `total` field names without changing the return tuple's types or order. The per-user checkpoint fields and SR namespace remain unchanged; the approved Program layout now stores the group configuration and derives aggregate outstanding units from ShareToken supply.

### Time and funding

Between actions, aggregate pending units and the stored pending accumulator decay by $2^{-\Delta t/h}$. Whole half-lives use binary shifts; fractional half-lives use Solady's `expWad`. Each action updates the aggregate checkpoint and only the holders it touches. There are no scheduled periods or loops over holders.

Funding $\Delta T_i$ issues units at the existing token-per-unit value:

$$
\Delta\hat U_i=\Delta T_i\frac{\hat U_i}{U_i}.
$$

If there are no outstanding units, initial issuance is $\Delta T_i\times10^{36}$. This unit scale is an implementation precision choice, independent of token decimals. The implementation floors issuance, then rounds it down to a multiple of the current raw aggregate stake. Both stored accumulators increment by issued units divided by that supply; `unclaimedUnits` and `pendingUnits` increase by the issued units.

Integral unit-per-share increments make issued units exactly equal total holder allocations, including holders not yet checkpointed. Funding too small to increment the accumulators reverts. Rounding issuance down slightly increases existing unit value; quantities that overflow uint256 revert.

### Holder checkpoints

Before changing a holder's stake balance, `currentHolderRewardCheckpoint` reconstructs their rewards using the **old** Ledger staking-account balance:

1. Add that balance times the change in `unclaimedAccumulator` to their saved `unclaimedUnits`.
2. Decay their saved `pendingUnits` and saved `pendingAccumulator` from their checkpoint time to now.
3. Add the old share balance times the difference between the current shared pending accumulator and the decayed saved accumulator to their pending units.
4. Save the current shared accumulators and timestamp.

This reconstructs prior allocations; it does not issue aggregate units again. Independently rounded decay paths can differ, so a negative pending-accumulator difference contributes zero. Holder pending units are bounded by their unclaimed units. Aggregate pending decays independently and is likewise bounded after claims and forfeitures.

### Claim all

After checkpointing, `claim(srToken)` cancels all $\hat A_i^j=\hat U_i^j-\hat P_i^j$ available units and pays

$$
\left\lfloor\hat A_i^j\frac{U_i}{\hat U_i}\right\rfloor.
$$

The holder's unclaimed units become exactly their pending units. Their pending units and stake are unchanged. The same available-unit count is removed from the aggregate, and the payout is transferred from the reward account to the holder. The accumulators receive no allocation increment.

A claim with no available units reverts. Available units whose token value rounds to zero can still be cleared; residual backing benefits the remaining units. Claiming the entire outstanding unit supply drains the remaining reward backing. Claims remain separate from principal withdrawals, so exited holders can claim later.

### Unstake and transfer

For an ordinary exit, remove the fraction of pending units corresponding to the outgoing stake. Its mathematical change is

$$
\Delta\hat P_i^j=\frac{\Delta S_i^j}{S_i^j}\hat P_i^j,
\qquad
\Delta\hat U_i^j=\frac{\hat U_i}{\hat U_i-\hat A_i^j}\Delta\hat P_i^j.
$$

Both changes are negative. The implementation floors the pending-unit removal and rounds the unclaimed-unit cancellation up, applying the same removals to the aggregate. The reward backing stays in its existing account. This preserves the exiting holder's available token value up to rounding and reprices surviving units. Later funding therefore accumulates **units**, not token amounts. No forfeiture account or unallocated-reward balance is needed.

On a full exit by the sole reward-unit holder ($\hat U_i^j=\hat U_i>0$), holder and aggregate pending units become zero; unclaimed units and reward backing remain unchanged. The holder can immediately claim the full remaining reward balance. A partial exit uses ordinary forfeiture. The sole reward-unit holder can differ from the last staker: exited holders can retain unclaimed units, and new stakers may have no reward units yet.

An SR transfer applies the same exit rules to the sender and checkpoints the recipient before moving actual stakes. Funding touches no holder checkpoint; staking, claiming, and unstaking touch one; transfers touch their two endpoints. After complete redemption, later funding uses initial issuance again. Accumulator history and holder snapshots can remain in place without a reset or holder loop.

## Transfers and integration

StakingRewardWrapper inherits ERC20 metadata and allowance handling and overrides balances, supply, transfer, and transferFrom. Its transfers call `StakingRewardToken.transfer(token, from, to, amount)` on Dispatcher. That entry point authenticates the configured wrapper, resolves accounts under its staking group, and settles both holders at their old balances before Ledger posting. Available rewards stay with the sender. Pending forfeiture and the final-holder release use the established equations above. Self and zero transfers do not write reward checkpoints; self transfers still require sufficient stake.

LedgerLib has no SR hook or settlement callback. An internal consuming module must authorize its explicit account context and settle the affected program before posting. Existing internal claim and unstake overloads accept explicit parent and relative accounts within the program's staking subtree. Groups cannot claim descendant entitlements. Public underlying-token transfers cannot spend the staking or reward groups as ordinary debit leaves.

Group-based nested SR composition is not implemented. In particular, the old root-based route for an SR stake/reward asset cannot be reused merely by substituting a group address: reward ownership and settlement at each program boundary must first be specified. Existing tests retain those unresolved cases and the raw-transfer settlement regression.

Aggregate outstanding reward units are not duplicated in SR storage. User reward checkpoints still hold outstanding and pending entitlements and accumulator snapshots. Source and the reward custody account are controlled through authorized SR share operations; no public cancellation endpoint is introduced.
