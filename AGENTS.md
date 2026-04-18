# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Protocol

**Be extremely concise.** Minimize tokens while maximizing information density. Sacrifice complete sentences, articles (a/an/the), and grammatical formality for brevity and clarity. Use fragments, bullet points, technical shorthand. Examples:

- ❌ "I will now proceed to build the project using forge build"
- ✅ "Building with `forge build`"
- ❌ "The test has failed because there is a type mismatch error"
- ✅ "Test failed: type mismatch"
- ❌ "I have successfully completed the implementation of the new feature"
- ✅ "Feature implemented"

Apply this throughout responses—explanations, status updates, error descriptions. Every word should earn its token cost.

- Keep `AGENTS.md` in active context for full session; re-open before substantial edits if context may have drifted.
- Surface blockers/risks first; include file paths + line numbers when citing issues.
- If unsure, ask one precise question rather than many.
- Pause to confirm intent before assumptions; do not guess.
- For reviews, clarify scope first.
- NEVER change storage layout (`Store` structs/slots, ERC-7201 positions, packed storage) without explicit user permission.
- Onchain state rule: persist only mutations required for protocol functionality/correctness; prefer deriving analytics/reporting/audit views offchain.
- Local variable naming: underscore suffix by default. Exception allowed for `*Context memory ctx` / `*Cache memory c`.
- Style target: minimalist, consistent patterns, minimal locals/helpers, avoid redundant recomputation.
- Section comment style: `// -- Section Name --` (avoid boxed multi-line separators).
- For commit msg/body requests: first inspect current changes with `git status --short`, `git diff --stat HEAD`, and `git diff --unified=0 HEAD`; `git diff HEAD` excludes untracked files, so include relevant untracked files shown by status and inspect their contents before drafting. Include only changes present in current tracked diff + relevant untracked files, never prior commits or broader session history. Return commit message + body in one single copy-pasteable fenced `text` block by default.

## Updating This File

After completing **major tasks**, reflect on whether CLAUDE.md should be updated. Only update for:

- **Fundamental architecture changes** (e.g., new core module, storage pattern changes, major refactors)
- **Critical tips/best practices** that future agents should know (e.g., non-obvious gotchas, essential workflows)

Be **conservative**—don't update for routine bug fixes, minor features, or task-specific details. This file should contain timeless, foundational knowledge.

When updating: maintain concise style, add to appropriate section, avoid redundancy.

## Project Overview

CavalRe: modular, accounting-driven smart contracts for onchain capital markets. Router-Module pattern with delegatecall-based upgradability + hierarchical double-entry ledger.

## Development Commands

```bash
# Build
forge build

# Test
forge test                                      # all tests
forge test --match-path tests/modules/Ledger.t.sol  # specific file
forge test --match-test testFunctionName       # specific test
forge test --gas-report                        # with gas report
forge test -vvv                                # verbose traces

# Format
forge fmt

# Documentation (outputs to docs/api/)
forge doc

# Clean
forge clean
```

## Architecture

### Core Module Pattern

**Router.sol** - Immutable entrypoint. Maps function selectors → module addresses, delegatecalls on each call. Enables upgradability with constant Router address.

**Module.sol** - Abstract base for all modules:

- `__self` immutable - detects delegatecall context
- `enforceIsDelegated()` / `enforceNotDelegated()` - guards
- `enforceIsOwner()` - access control via ModuleLib storage
- `selectors()` - must implement to register commands

**Registration flow**: Module implements `selectors()` → returns function selectors array → Router maps selector → module address. On call: Router looks up selector, delegatecalls to module.

### Ledger Module

`modules/Ledger.sol` - Hierarchical double-entry accounting:

- **Account hierarchy**: Tree structure, parent-child via `LedgerLib.Store`
- **Debit vs Credit**: Flagged via FLAG_IS_CREDIT
- **Group vs Leaf**: Groups (containers) or leaves (actual balances)
- **Internal vs External**: Internal (created) or external (wrapped ERC20s)
- **Registration**: Roots/subaccounts carry `FLAG_IS_REGISTERED`
- **Address encoding**: `keccak256(abi.encodePacked(parent, child))` via `LedgerLib.toAddress()`

Special addresses / roots:

- `NATIVE_ADDRESS` - native token (ETH)
- each root auto-registers a default source leaf whose address is derived from the configured source name

**ERC20Wrapper**: Internal roots are self-wrapped at creation. Native/external roots may optionally get ERC20-compatible wrappers later via `createWrapper`. Wrapper surfaces delegate balance/allowance/transfers to Ledger via Router.

**ERC20 Module**: `modules/ERC20.sol` exposes ERC20 API for canonical root at `address(this)`. Metadata/supply/balances route through `LedgerLib`; allowances live in `ERC20Lib`; transfers route through `Ledger.transfer(...)`.

**Tree Module**: `modules/Tree.sol` owns topology/debug reads (`root`, `parent`, `flags`, `effectiveFlags`, `subAccounts`, `debugTree(s)`) so `Ledger` can stay focused on accounting state and mutations.

### Storage Pattern

ERC-7201 namespaced storage avoids collisions:

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.ModuleName")) - 1)) & ~bytes32(uint256(0xff));
```

Each library (ModuleLib, LedgerLib, RouterLib): `Store` struct + `store()` function for isolated storage slot.

### FloatLib - Custom Fixed-Point Math

`libraries/FloatLib.sol` - Custom fixed-point:

- **Type**: `Float` wraps `int256`
- **Structure**: signed base-10 exponent packed with a 72-bit mantissa
- **Precision**: 21 significant digits
- **Normalization**: Mantissa magnitude normalized to `[10^20, 10^21 - 1]`
- **Constants**: ONE, TWO, ..., TEN predefined

Enables precise arithmetic across decimal scales—critical for multi-decimal tokens in accounting.

## Project Structure

```
cavalre-contracts/
├── modules/              # Core upgradeable modules
│   ├── ERC20.sol         # Canonical-root ERC20 surface
│   ├── Module.sol        # Abstract base for all modules
│   ├── Router.sol        # Immutable delegatecall dispatcher
│   ├── Ledger.sol        # Hierarchical accounting + ERC20Wrapper
│   └── Tree.sol          # Topology/debug surface
├── libraries/            # Stateless libraries and namespaced storage
│   ├── ERC20Lib.sol      # Canonical-root ERC20 allowance storage/selectors
│   ├── FloatLib.sol      # Fixed-point math with dynamic scaling
│   ├── FloatStrings.sol  # Float to string conversion
│   ├── ModuleLib.sol     # Module storage (owner mapping)
│   ├── RouterLib.sol     # Router storage (selector -> module mapping)
│   ├── LedgerLib.sol     # Ledger storage (accounts, balances, tree)
│   └── TreeLib.sol       # Debug helpers for ledger tree visualization
├── utilities/            # Reusable abstract contracts
│   ├── Initializable.sol # Initialization guard
│   └── ReentrancyGuard.sol # Module-specific reentrancy protection
├── interfaces/           # Interface definitions
│   └── ILedger.sol       # Ledger module interface
├── examples/             # Reference implementations and legacy code
│   ├── ERC20.sol
│   ├── ERC4626.sol
│   ├── Sentry.sol
│   └── Token.sol
└── tests/                # Foundry tests mirroring source structure
    ├── modules/
    ├── libraries/
    └── examples/
```

## Testing Conventions

- `.t.sol` suffix, `tests/` directory
- Inherit `forge-std/Test.sol`
- Test modules wrap actual modules (e.g., `TestLedger is Ledger`) for test-specific functions
- Must implement `selectors()` for Router registration
- Visualize ledger trees via `Tree` module: `tree.debugTree(root)`
- When running Forge, note EIP-3860 initcode size warnings: expected in tests sometimes; flag if non-test deployable contracts hit warning.

## Dependencies

- **Foundry** - Build/test (forge/cast/anvil)
- **OpenZeppelin Contracts Upgradeable** v5.5.0 - Secure patterns
- **Solady** v0.1.18 - Gas-optimized utilities (FixedPointMathLib)
- **forge-std** - Foundry test lib

Note: Uses standard OpenZeppelin (previously forked for module-specific reentrancy guards, merged upstream in v5.4).

## Configuration

- Solidity: 0.8.26 (fixed, auto-detect off)
- EVM: Cancun
- Optimizer: 200 runs
- Tests: `tests/`
- Artifacts: `artifacts/foundry/contracts/`
- Source root: `.` (contracts at repo root)
