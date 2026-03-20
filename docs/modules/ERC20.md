# ERC20.sol

`modules/ERC20.sol` exposes the ERC20 surface for the canonical root at `address(this)`.

## Scope

- canonical-root metadata (`name`, `symbol`, `decimals`)
- canonical-root balances and total supply
- standard ERC20 transfers
- allowances / approvals

## Key Model

- runtime address is the Router address via `delegatecall`
- canonical root must already be registered via `initializeLedger(...)`
- metadata, balances, total supply, and transfer posting come from `LedgerLib`
- allowance state lives in `ERC20Lib`
- ERC20 events are emitted through `ILedger.Transfer` / `ILedger.Approval`

## Relationship To Ledger

`ERC20` is intentionally separate from `Ledger`:

- `Ledger` owns root registration, account trees, and posting logic
- `ERC20` owns only the canonical-root ERC20 surface

This keeps canonical-root ERC20 behavior out of `LedgerLib` while preserving `address(this)` as the canonical token address.

## Relationship To ERC20Wrapper

- canonical root uses `modules/ERC20.sol` if ERC20 exposure is desired
- canonical root may also be wrapped explicitly via `createWrapper(...)`
- internal roots are self-wrapped at creation
- native and external roots may be wrapped later via `createWrapper(...)`

So:

- `ERC20` = canonical-root surface
- `ERC20Wrapper` = non-canonical-root surface

## Testing

```bash
forge test --match-path tests/modules/ERC20.t.sol
```
