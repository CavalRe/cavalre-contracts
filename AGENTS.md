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
- **Address encoding**: `keccak256(abi.encodePacked(parent, child))` via `LedgerLib.toAddress()`

Special addresses (LedgerLib):

- `TOTAL_ADDRESS` - account tree root
- `RESERVE_ADDRESS` - reserve account
- `NATIVE_ADDRESS` - native token (ETH)
- `UNALLOCATED_ADDRESS` - unallocated for ops

**ERC20Wrapper**: Creates ERC20-compatible wrappers per token. Delegates balance/allowance/transfers to Ledger via Router. Allows external contracts to treat ledger accounts as standard ERC20s.

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
- **Structure**: 128-bit signed exponent (high) + 128-bit signed mantissa (low)
- **Precision**: 18 significant digits
- **Normalization**: Mantissa ∈ [10^17, 10^18 - 1]
- **Constants**: ONE, TWO, ..., TEN predefined

Enables precise arithmetic across decimal scales—critical for multi-decimal tokens in accounting.

## Project Structure

```
cavalre-contracts/
├── modules/              # Core upgradeable modules
│   ├── Module.sol        # Abstract base for all modules
│   ├── Router.sol        # Immutable delegatecall dispatcher
│   └── Ledger.sol        # Hierarchical accounting + ERC20Wrapper
├── libraries/            # Stateless libraries and namespaced storage
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
- Visualize ledger trees: `TreeLib.debugTree(ledgers, root)`

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
