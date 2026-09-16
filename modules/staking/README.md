# StakingRewardToken

An optional MIT Dispatcher module that creates staking-reward tokens with the original pending/available reward model. Each SR token owns its configuration: staking ledger `S`, reward ledger `R`, fixed staking account `T`, and half-life `h` in seconds.

The SR token represents principal shares. It is an internal Ledger token with an ERC20 wrapper; no Ledger receipt token is required. Reward units are separate, nontransferable accounting entries. Funding allocates pending reward units to holders **at funding time**; elapsed time makes those units available. New holders do not acquire previously allocated rewards.

## Setup and use

1. Install `StakingRewardToken` alongside Ledger and LedgerView. Register the `S` and `R` ledgers using the usual asset setup.
2. Register an empty debit leaf `T` on the `S` ledger.
3. The SR module owner calls `createStakingRewardToken(S, R, T, h, metadata)`, passing `T` as an absolute account address. The module creates the internal token and ERC20 wrapper and returns its address and flags. It reuses the generic internal-token factory library; an installed LedgerTokenFactory module is not required.
4. Holders call `stake(srToken, amountS, minimumShares)` and `unstake(srToken, shares, minimumS)`.
5. Anyone can call `reward(srToken, amountR)` when SR supply is positive. Holders call `claim(srToken)` to redeem all available reward units; there is no amount parameter.

Metadata uses the shared `TokenMetadata` shape: name, symbol, decimals, and version. Identical creation requests return the same token without resetting balances or rewards. A different configuration for the same token identity reverts. Initial supply and `T` balance must be zero, and SR programs cannot share reserved staking accounts. `T`, `R`, and `h` are stored in SR state; `S` is validated against and read from `T`'s Ledger registration.

All token amounts in these operations use the respective token's raw decimals. Deposits, rewards, redemptions, and claims move existing **Ledger balances**. Wrap external/native assets through Ledger before using them here; unwrap claimed assets through Ledger afterward. `S` and `R` may be the same ledger. Normal receipt tokens can serve as either asset.

Principal shares mint pro rata to the existing staking balance, with decimal normalization on the first deposit. Caller-specified minima protect deposit and redemption quotes. A direct donation to `T` increases principal value per share. A direct donation to the funded reward account increases existing reward-unit value; use `reward` to allocate newly funded pending units.

`stakingRewardToken` returns the SR token address, supply, staking ledger/account/balance, reward configuration, and current aggregate rewards. All balances use the respective token's raw decimals, matching transaction amounts and reward views. `rewardsOf` takes a token-local holder key and returns current reward units and token amounts. Views project time decay without writing storage.

## Accounting

The [unit-first derivation](https://caval.re/blog/staking-rewards) defines the accumulators and action rules. Hats denote reward **units**; unhatted rewards are amounts of `R`. In particular, $U_i$ is unclaimed reward-token backing and $\hat U_i$ is outstanding unclaimed units. Neither is cumulative funding $T_i$.

### Stored and derived values

Each program and each holder use the same five-field `Checkpoint`. For a holder, the accumulators are snapshots of the shared accumulators at that holder's last checkpoint.

| Checkpoint field | Aggregate notation | Holder notation |
| --- | --- | --- |
| `unclaimedUnits` | $\hat U_i$ | $\hat U_i^j$ |
| `pendingUnits` | $\hat P_i$ | $\hat P_i^j$ |
| `unclaimedAccumulator` | $\phi_i^{\hat U}$ | Saved $\phi_i^{\hat U}$ |
| `pendingAccumulator` | $e^{-rt}\phi_i^{\hat P}$ | Saved $e^{-rt}\phi_i^{\hat P}$ |
| `updatedAt` | Aggregate checkpoint time | Holder checkpoint time |

Here $r=\ln(2)/h$. `pendingAccumulator` stores the decaying form, so the implementation uses elapsed time and never evaluates an ever-growing $e^{rt}$. Aggregate `pendingUnits` is retained for constant-time aggregate pending/available views; the core action amounts do not depend on it.

Ledger supplies the SR share supply $S_i$, holder share balance $S_i^j$, staked principal, and reward backing $U_i$. Outstanding reward units and the other checkpoint fields remain in the SR namespace. Cumulative funding $T_i$ and claims $C_i$ are not stored; reward, claim, and Ledger events supply historical accounting. Available units, per-unit value, and holder token amounts are derived.

`Rewards.unclaimedUnits` and `Rewards.unclaimed` expose current outstanding units and their token value. They replace the former `totalUnits` and `total` field names without changing the return tuple's types or order. The checkpoint renames also preserve the existing storage field widths, order, and namespace.

### Time and funding

Between actions, aggregate pending units and the stored pending accumulator decay by $2^{-\Delta t/h}$. Whole half-lives use binary shifts; fractional half-lives use Solady's `expWad`. Each action updates the aggregate checkpoint and only the holders it touches. There are no scheduled periods or loops over holders.

Funding $\Delta T_i$ issues units at the existing token-per-unit value:

$$
\Delta\hat U_i=\Delta T_i\frac{\hat U_i}{U_i}.
$$

If there are no outstanding units, initial issuance is $\Delta T_i\times10^{36}$. This unit scale is an implementation precision choice, independent of token decimals. The implementation floors issuance, then rounds it down to a multiple of the current raw SR supply. Both stored accumulators increment by issued units divided by that supply; `unclaimedUnits` and `pendingUnits` increase by the issued units.

Integral unit-per-share increments make issued units exactly equal total holder allocations, including holders not yet checkpointed. Funding too small to increment the accumulators reverts. Rounding issuance down slightly increases existing unit value; quantities that overflow uint256 revert.

### Holder checkpoints

Before changing a holder's share balance, `currentHolderRewardCheckpoint` reconstructs their rewards using the **old** Ledger share balance:

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

For an ordinary exit, remove the fraction of pending units corresponding to the outgoing shares. Its mathematical change is

$$
\Delta\hat P_i^j=\frac{\Delta S_i^j}{S_i^j}\hat P_i^j,
\qquad
\Delta\hat U_i^j=\frac{\hat U_i}{\hat U_i-\hat A_i^j}\Delta\hat P_i^j.
$$

Both changes are negative. The implementation floors the pending-unit removal and rounds the unclaimed-unit cancellation up, applying the same removals to the aggregate. The reward backing stays in its existing account. This preserves the exiting holder's available token value up to rounding and reprices surviving units. Later funding therefore accumulates **units**, not token amounts. No forfeiture account or unallocated-reward balance is needed.

On a full exit by the sole reward-unit holder ($\hat U_i^j=\hat U_i>0$), holder and aggregate pending units become zero; unclaimed units and reward backing remain unchanged. The holder can immediately claim the full remaining reward balance. A partial exit uses ordinary forfeiture. The sole reward-unit holder can differ from the last staker: exited holders can retain unclaimed units, and new stakers may have no reward units yet.

An SR transfer applies the same exit rules to the sender and checkpoints the recipient before moving shares. Funding touches no holder checkpoint; staking, claiming, and unstaking touch one; transfers touch their two endpoints. After complete redemption, later funding uses initial issuance again. Accumulator history and holder snapshots can remain in place without a reset or holder loop.

## Transfers and integration

SR transfers act as a proportional reward exit for the sender and entry for the receiver. Available rewards stay with the sender; proportional pending rewards are forfeited, with the same final-holder exception for a full transfer. The receiver earns future funding. Self-transfers and zero transfers do not forfeit rewards. Moving SR shares between two distinct accounts controlled by the same person still constitutes an exit/entry.

The default `LedgerLib.transfer` invokes the optional `beforeLedgerTransfer` Dispatcher selector before changing balances. The SR module authenticates the Dispatcher self-call, rejects protected custody debits and SR supply changes, and runs `settleTransferRewards`. This covers ERC20 transfer/transferFrom, direct Ledger transfers, and internal LedgerLib transfers, including nested holder accounts.

SR operations supply `settleTransferRewards` directly to the internal Ledger transfer overload. Their asset movements and share mint/burn use the same Ledger validation, accounting, and events, with no Dispatcher round trip or transient transfer authorization. The callback also settles the underlying program when `S` or `R` is another SR token. The callback overload is for trusted module code; it is not exposed through the Ledger ABI.

`settleTransferRewards` updates aggregate state and checkpoints each affected debit holder at its old balance. `settleHolderRewards` applies any outgoing shares using that same balance read, including pending forfeiture or the final-holder release. Claims use the same checkpoint with zero outgoing shares.

Nested-account applications can use the library with the corresponding token-local holder key to claim or redeem under their own authorization rules. SR state has its own ERC-7201 namespace; Ledger and Dispatcher storage layouts are unchanged.

**Upgrade requirement:** all modules that transfer through LedgerLib must be rebuilt with the hook-enabled library and deployed together with the SR module. Installing SR beside older, inlined LedgerLib code leaves transfer paths without checkpoints or custody checks. The hook must remain registered while SR programs are active; Dispatcher/module owners retain their existing upgrade authority.

The claim ABI is now `claim(address)`. When replacing an installed version, remove the old module through Dispatcher before registering the replacement so `claim(address,uint256)` is removed with its old manifest. Clients must use the new claim signature and reward field names.

Funding policy, fee routing, treasury sales, and Multiswap pool selection remain application concerns outside this module.
