# Recursive Ledger custody integration

Fresh-deployment foundation; no deployment or migration is included.

## cavalre-contracts

Parent arguments and registration return values are absolute accounting addresses.
Use `H(g,r)` recursively. Direct ERC20 holder keys remain the relative children of
the token root. Wrappers read both custody aggregates and project events through
that same direct child. Public transfers require direct debit leaves at both
endpoints and reject credit accounts, including Source; they do not authorize
descendant withdrawals. Internal share issue/redeem/cancel and SR claim/unstake
accept explicit account context. SR `rewardsOfAccount` exposes nested
reward reads. Ledger's `Store.custody` replaces `Store.ledger` at the same field
position. Registered accounts point to their absolute direct-child custodian;
the ledger is derived from that custodian's packed parent. Ledger roots identify
themselves by their flags and need no custody entry. Unregistered effective leaves
use explicit parent context without a stored entry. SR storage, namespaces and
packed field widths/order are unchanged; the packed parent lane contains the
absolute accounting parent. ShareTokenLib adds a separate `cavalre.storage.ShareToken` namespace
for immutable token-to-backing bindings; share roots pack `ROOT_ADDRESS`.
SR validates debit leaves for funding, shares and reward positions; a displayed
group custody balance cannot claim rewards belonging to its descendants.

The authenticated public transfer callback rejects either parent unless it equals
the token root, before resolving account flags. Self-transfers still require the
sender's balance to cover the amount, including when called through transferFrom.
A rejected transfer preserves allowances. A valid self-transfer emits Transfer
and leaves balances unchanged; transferFrom also consumes finite allowance. These
checks apply to ordinary wrappers, ShareToken and the canonical ERC20 surface.

Internal postings retain their existing leaf-side rules. No new group solvency
constraint is imposed: if a group's normal balance is negative, its unsigned net
balance view reverts on checked subtraction, as before. Regression coverage keeps
that internal behavior distinct from the positive mixed-custody projection tests.

## cavalre-multiswap follow-up (not changed here)

- SR tokens now deploy StakingRewardWrapper, inheriting ERC20Wrapper and overriding
  both transfers to call `StakingRewardToken.transfer(token, from, to, amount)`.
  The SR module authenticates the wrapper and settles rewards before posting.
  SR address predictions require that wrapper's creation bytecode. Register SR creation on the
  existing LedgerTokenFactory and install the SR runtime module; all internal postings settle
  affected programs through the Dispatcher-only settleStakeTransfer selector.
  Refresh the Configuration return tuple for allocationRemainderUnits. SR creation
  rejects SR stake/reward assets, including nesting introduced in reverse creation order.
- Any direct `LedgerLib.Store.ledger` reads must use `LedgerLib.ledger(absolute)`;
  the stored mapping is now `custody`. The getter preserves its address-based
  results for registered accounts, roots and unregistered addresses.
- Update the contracts dependency and callers of
  `LedgerLib.transfer(ledger, fromFlags, fromRelative, toFlags, toRelative, amount)`.
  Resolve effective endpoint flags once and reuse them for validation and posting.
  The flags replace the parent arguments; unregistered leaves require effective
  metadata rather than zero stored flags. Ledger postings settle affected SR
  programs automatically; remove duplicate settlement in consuming modules.
- Replace token-local parent derivations in PoolLib, PoolStateLib, DepositLib,
  StakeLib, LiquidityLib/views and MultiswapLib with recursive absolute parents.
  Update TypeScript accounting-address helpers and tree consumers accordingly.
- Keep wallet holder queries distinct from internal leaf queries. A pool's direct
  child holder displays subtree normal balance; its gross reserves, surplus,
  protocol credits and stake leaves remain internal Ledger views.
- Adopt current ShareTokenLib/ShareTokenView APIs, including address-based
  `isShareToken(token)` / `backingAccount(token)`. Conversion quotes use
  `convertToShares(token, backing)` and `convertToBacking(token, shares)`.
  Use the factory view's
  `predictERC20TokenAddress(...)` and `predictShareTokenAddress(...)` for address
  prediction. Share registration now stores backing separately from Ledger flags.
- Use the plural public factory methods `createInternalTokens(TokenMetadata[])`
  and `createShareTokens(ShareTokenConfig[])`. Each share config pairs
  `backingAccount` with `metadata`; both calls return address and flags arrays.
- Remove the packed-address argument from any direct `LedgerLib.addLedger` calls;
  registration always sets the parent to `ROOT_ADDRESS`.
- Share `issue(token, parent, relative, backing)` and
  `redeem(token, parent, relative, shares)` each have one implementation and no
  callback/data arguments. Add and verify backing before issue; release and verify
  backing after redeem, atomically. Preserve exact backing/supply-delta checks in
  the consuming module. Issue prices against current backing minus the addition.
- Pass explicit parent/relative contexts to share and internal staking-account operations;
  wrapper allowances never authorize spending descendant custody.
- Public ERC20 transfers cannot mint or burn through credit accounts. Keep credit
  postings inside authorized module operations for issuance, redemption and settlement.
- Update event indexers and tests for custodian identities, C-to-C reversal, and
  retained internal self-transfer events. Preserve root supply semantics instead
  of summing net custody balances or inferring supply solely from projected logs.
- Re-run deposit/refund/claim, liquidity, settlement, staking, ABI and frontend
  integration tests in that repository as its separate task.
