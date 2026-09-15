# StakingRewardToken

An optional MIT Dispatcher module that adds the original pending/available reward model to Ledger receipt tokens. Each SR token has one reward ledger `R` and an immutable half-life `h`, in seconds. Its receipt metadata supplies the staking ledger `S` and fixed backing account `T`.

The receipt represents principal. Reward units are separate, nontransferable accounting entries. Funding allocates pending reward units to holders **at funding time**; elapsed time makes those units available. New holders do not acquire previously allocated rewards.

## Setup and use

1. Install `StakingRewardToken` alongside Ledger, LedgerView, and LedgerTokenFactory.
2. Register an empty debit leaf `T` on the `S` ledger and create a receipt token referencing its absolute address.
3. The SR module owner calls `configureStakingRewardToken(receipt, R, h)`. The receipt supply and `T` balance must both be zero. Configuration cannot subsequently change, and SR programs cannot share reserved backing accounts.
4. Holders call `stake(receipt, amountS, minimumReceipts)` and `unstake(receipt, receipts, minimumS)`.
5. Anyone can call `reward(receipt, amountR)` when receipt supply is positive. Holders call `claim(receipt, amountR)`, or pass `type(uint256).max` to claim all available units.

All token amounts in these operations use the respective token's raw decimals. Deposits, rewards, redemptions, and claims move existing **Ledger balances**. Wrap external/native assets through Ledger before using them here; unwrap claimed assets through Ledger afterward. `S` and `R` may be the same ledger. Normal receipt tokens can serve as either asset.

Principal receipts mint pro rata to the existing backing balance, with decimal normalization on the first deposit. Caller-specified minima protect deposit and redemption quotes. A direct donation to `T` increases principal value per receipt. A direct donation to the funded reward account increases existing reward-unit value; use `reward` to allocate newly funded pending units.

`stakingRewardToken` returns receipt metadata, reward configuration, reserve balance, and current aggregate rewards. `rewardsOf` takes a token-local holder key and returns current reward units and token amounts. Views project time decay without writing storage.

## Accounting

Let `U` be total reward units, `P` pending units, `B` funded R balance, `L` receipt supply, and `u`, `p`, `l` the corresponding holder quantities. Let `I` and `J` be cumulative total and decaying pending unit indices.

Between actions, over elapsed time `dt`:

```text
d = 2^(-dt / h)
P <- P * d
J <- J * d
```

Whole half-lives use binary shifts; fractional half-lives use Solady's `expWad`. Each action updates aggregate state and only the holders it touches. There are no scheduled periods or loops over holders.

Funding `b` R issues units at the existing R/unit price:

```text
q = b * U / B                 if U > 0
q = b * 10^36                otherwise
i = floor(q / L)
q = i * L
U <- U + q; P <- P + q
I <- I + i; J <- J + i
```

Integral unit-per-receipt indices make issued units exactly equal total holder allocations, including holders not yet checkpointed. Funding too small to increment the index reverts. Rounding issuance down slightly increases existing unit value. `10^36` is internal unit precision, not a token-decimal assumption; quantities that overflow uint256 revert.

A holder checkpoint uses its saved indices and time:

```text
u <- u + l * (I - I_saved)
p <- p * d + l * (J - J_saved * d)
I_saved <- I; J_saved <- J
```

Decay uses finite precision. Negative pending-index differences caused by independently rounded decay paths contribute zero, and pending cannot exceed total units. Aggregate pending is independently rounded. Available token value is `floor((u - p) * B / U)`.

A specified-amount claim burns `ceil(amountR * U / B)` available units. A claim-all burns all available units and pays their floored R value, allowing removal of unredeemable unit dust.

On an exit of fraction `f` of a holder's receipts:

```text
F = floor(p * f)
A = u - p
Q = ceil(F * U / (U - A))
u <- u - Q; p <- p - F
U <- U - Q; P <- P - F
```

This preserves the exiting holder's available R value up to rounding. Retained R backs fewer units, benefiting surviving reward-unit holders, including exited holders with unclaimed rewards. Later funding must therefore accumulate **units**, not R amounts.

If no other reward units would survive a full pending exit, earned R remains claimable and the rest moves to a separate forfeited-reward account. The module owner can explicitly allocate that reserve to current holders using `recycleRewards`. New deposits do not automatically receive it. Zero-value unit dust is retired so it cannot block subsequent funding.

## Transfers and integration

Receipt transfers act as a proportional reward exit for the sender and entry for the receiver. Available rewards stay with the sender; proportional pending rewards are forfeited. The receiver earns future funding. Self-transfers and zero transfers do not forfeit rewards. Moving receipts between two distinct accounts controlled by the same person still constitutes an exit/entry.

LedgerLib invokes the optional `beforeLedgerTransfer` Dispatcher selector before changing balances. The SR module authenticates the Dispatcher self-call and checkpoints both affected debit accounts. This covers ERC20 transfer/transferFrom, direct Ledger transfers, and internal LedgerLib transfers, including nested holder accounts. Nested-account applications can use the library with the corresponding token-local holder key to claim or redeem under their own authorization rules.

Backing and reward custody accounts reject unauthorized debits. Receipt mint/burn and module custody movements use one-use transient authorizations tied to exact Ledger transfers. SR state has its own ERC-7201 namespace; existing Ledger and Dispatcher storage layouts are unchanged.

**Upgrade requirement:** all modules that transfer through LedgerLib must be rebuilt with the hook-enabled library and deployed together with the SR module. Installing SR beside older, inlined LedgerLib code leaves transfer paths without checkpoints or custody checks. The hook must remain registered while SR programs are active; Dispatcher/module owners retain their existing upgrade authority.

Funding policy, fee routing, treasury sales, and Multiswap pool selection remain application concerns outside this module.
