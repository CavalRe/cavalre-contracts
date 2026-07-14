# LedgerERC20.sol

`examples/LedgerERC20.sol` exposes the ERC20 surface for the canonical root at `address(this)`.

## Scope

- canonical-root metadata (`name`, `symbol`, `decimals`)
- canonical-root balances and total supply
- standard ERC20 transfers
- allowances / approvals

## Key Model

- runtime address is the Dispatcher address via `delegatecall`
- canonical root must already be registered via `initializeLedger(...)`
- metadata, balances, and total supply come from `LedgerLib`
- transfers route through `Ledger.transfer(...)`, not raw `LedgerLib.transfer(...)`
- allowance state lives in `LedgerERC20Lib`
- allowance approvals emit `ILedger.Approval`
- transfer-side Ledger accounting emits `ILedger.Credit` / `ILedger.Debit`
- canonical ERC20 transfers therefore inherit the same source-polarity gate as other user-facing transfer paths

## Zero Address Balance

`address(0)` is a real depth-2 Ledger account under each root: `Zero Address`.
It is the default credit source/sink used for mint-like and burn-like ledger
movement. For that reason, `balanceOf(address(0))` on the ERC20 surface reports
the Ledger balance of that account instead of forcing the vanilla ERC20
compatibility value `0`.

## Relationship To Ledger

`LedgerERC20` is intentionally separate from `Ledger`:

- `Ledger` owns root registration, account trees, and posting logic
- `LedgerERC20` owns only the canonical-root ERC20 surface

This keeps canonical-root ERC20 behavior out of `LedgerLib` while preserving `address(this)` as the canonical token address.

## Relationship To ERC20Wrapper

- canonical root uses `examples/LedgerERC20.sol` if ERC20 exposure is desired
- internal roots are self-wrapped at creation
- claim roots are self-wrapped at creation
- native and external roots are registered ledger roots without self-wrapped ERC20 surfaces

So:

- `LedgerERC20` = canonical-root surface
- `ERC20Wrapper` = self-wrapped internal/claim-token surface

## Testing

```bash
forge test --match-path tests/examples/LedgerERC20.t.sol
```
