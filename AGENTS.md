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
- Avoid trivial one-line helper functions; prefer one core implementation and call it directly.
- Validation naming: `is*` / `has*` return booleans; `enforce*` requires the named condition and reverts with a specific custom error on failure. Name the required condition, e.g. `enforceNonZeroAddress`.
- Validation helpers are read-only (`view` / `pure` in Solidity). They may return validated data or context to avoid recomputation, but must not mutate state or caller-owned inputs. Name state-changing operations by their action, e.g. `prepareEpoch` or `consumeIntent`.
- Keep descriptive names for getters, calculations, and verification reports; a function that can revert is not automatically an `enforce*` helper. Test assertions retain `assert*` names.
- Validate at the responsible layer: Ledger owns topology/accounting, share code owns share restrictions, consuming modules own authorization. Reuse existing errors and validated data; repeat a check only when intervening work can invalidate it. Keep simple single-use checks inline.
- Section comment style: `// -- Section Name --` (avoid boxed multi-line separators).
- For commit msg/body requests: first inspect current changes with `git status --short`, `git diff --stat HEAD`, and `git diff --unified=0 HEAD`; `git diff HEAD` excludes untracked files, so include relevant untracked files shown by status and inspect their contents before drafting. Include only changes present in current tracked diff + relevant untracked files, never prior commits or broader session history. Return commit message + body in one single copy-pasteable fenced `text` block by default.

## Updating This File

After completing **major tasks**, reflect on whether CLAUDE.md should be updated. Only update for:

- **Fundamental architecture changes** (e.g., new core module, storage pattern changes, major refactors)
- **Critical tips/best practices** that future agents should know (e.g., non-obvious gotchas, essential workflows)

Be **conservative**—don't update for routine bug fixes, minor features, or task-specific details. This file should contain timeless, foundational knowledge.

When updating: maintain concise style, add to appropriate section, avoid redundancy.

## Project Overview

CavalRe: modular, accounting-driven smart contracts for onchain capital markets. Dispatcher/Dispatchable pattern with delegatecall-based upgradability + hierarchical double-entry ledger.

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

**Dispatcher.sol** - Immutable entrypoint. Maps function selectors → module addresses, delegatecalls on each call. Enables upgradability with constant Dispatcher address.

**Dispatchable.sol** - Abstract base for all modules:

- `__self` immutable - detects delegatecall context
- `enforceIsDelegated()` / `enforceNotDelegated()` - guards
- `enforceIsOwner()` - access control via ModuleLib storage
- `selectors()` - must implement to register commands

**Registration flow**: Module implements `selectors()` → returns function selectors array → Dispatcher maps selector → module address. On call: Dispatcher looks up selector, delegatecalls to module.

### Ledger Module

`modules/ledger/Ledger.sol` - Hierarchical double-entry accounting:

- **Account hierarchy**: Tree structure, parent-child via `LedgerLib.Store`
- **Debit vs Credit**: Encoded in `LedgerLib.AccountKind`
- **Group vs Leaf**: Groups (containers) or leaves (actual balances)
- **Token kind**: Typed `LedgerLib.TokenKind` enum (`Unregistered`, `Native`, `External`, `Internal`); shares are ordinary internal tokens.
- **Registration**: Registered accounts have non-`Unregistered` `AccountKind`
- **Address taxonomy**: `absolute_` = recursive accounting key, `relative_` = reusable child key, `holder_` = relative key of a token root's direct child. Derive accounting keys with `LedgerLib.toAddress(absoluteParent, relative)`; registration returns absolute keys. All parent arguments are absolute. ERC20 views/events project through the direct child custodian (stored depth 3, token-relative depth 2); internal operations keep explicit account context.
- **Custody storage**: `Store.custody` replaces `Store.ledger`. Registered direct children point to themselves; descendants inherit their parent's absolute custodian. `ledger(absolute)` derives the root from the custodian's packed parent. Roots have no custody entry and identify themselves by their flags. Unregistered leaves retain no entry: explicit parent context resolves their custody without an ancestry walk.

Special addresses / roots:

- `NATIVE_ADDRESS` - native token (ETH)
- all registered roots are debit groups
- each root auto-registers `LedgerLib.SOURCE_ADDRESS` / `Source` as its default credit source leaf; `address(0)` is ERC20 event-only
- packed addresses always identify absolute parents; every ledger root packs `ROOT_ADDRESS`

**ERC20Wrapper / ShareToken**: Internal roots use ERC20Wrapper; share roots use the dedicated ShareToken subclass. Both are self-wrapped at creation. If a root has a wrapper, the wrapper address is the root address. Native/external roots do not get separate wrapper surfaces.

**ERC20 Example Module**: `examples/LedgerERC20.sol` exposes ERC20 API for canonical root at `address(this)`. Metadata/supply/balances route through `LedgerLib`; allowances live in `LedgerERC20Lib`; transfers route through `Ledger.transfer(...)`.

**Tree Module**: `modules/tree/TreeView.sol` owns topology/debug reads (`root`, `parent`, `flags`, `effectiveFlags`, `subAccounts`, `debugTree(s)`) so `Ledger` can stay focused on accounting state and mutations.

`LedgerLib.transfer(ledger, fromFlags, fromRelative, toFlags, toRelative, amount)` accepts already-resolved effective account flags. Callers validate parent/ledger membership through `effectiveFlags` and reuse that metadata for their own restrictions and the posting. Packed flags provide each absolute parent, depth and polarity; raw zero flags do not describe an unregistered effective leaf. Internal postings support deep accounts and credit accounts. User-facing ERC20 wrappers supply the token root as both parents to the authenticated Ledger callback.

### Share Module

`modules/share/ShareTokenLib.sol` issues and burns shares through share Source using one explicit-parent/relative `issue` and `redeem` function each, without callback/data arguments. Consuming modules add and verify backing before issue, and release and verify backing after redeem; they own exact settlement-delta checks, authorization, slippage and reentrancy. Issue derives the pre-addition ratio by subtracting the supplied addition from current backing. Backing can be a non-token ledger such as Scale. ShareToken exposes ERC20 operations plus backing/conversion views through ShareTokenView. Public ERC20 transfers require direct debit leaves at both endpoints and reject credit accounts, including Source; no public cancellation endpoint or separate mutation module is installed. Use `predictShareTokenAddress` for share CREATE2 addresses; `predictERC20TokenAddress` remains internal-token-only. ShareTokenLib stores immutable token-to-backing bindings in its `cavalre.storage.ShareToken` namespace; zero means unregistered. Share roots pack `ROOT_ADDRESS` as their parent, like every other ledger. `isShareToken(address)` and `backingAccount(address)` belong to ShareTokenView, not TreeView; no share kind or bit exists. Ledger retains all supply, balances and backing accounting. See `docs/modules/ShareTokens.md` for zero-state and rounding policies.

### Staking Reward Module

`StakingRewardFactory` owns program creation; `StakingRewardToken` owns runtime accounting and views. Install both through Dispatcher. `StakingRewardWrapper` presents actual balances beneath a configured staking group; there is no principal receipt ledger. Reward ShareToken supply is the authoritative aggregate outstanding-unit balance, held in one custody leaf until claims.

`LedgerLib.transfer` settles each affected staking program through the Dispatcher-only `settleStakeTransfer` selector before posting, including internal and nested paths. Do not duplicate settlement in consuming modules. Same-program transfers carry proportional pending units; exits allocate forfeited pending units to remaining stake without changing reward-share supply or custody. Final release tests remaining stake, not reward-unit ownership. Available rewards stay with their owner. Nested SR assets use actual staking subtrees, not wrapper-root accounts.

Storage layouts remain unchanged. The existing checkpoint at the staking-group address records allocation residual units; groups cannot be holders. Final unstake credits that residual to the last eligible position. See `modules/staking/README.md` for arithmetic bounds, custody projection, access restrictions and empty-state policies.

### Storage Pattern

ERC-7201 namespaced storage avoids collisions:

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.ModuleName")) - 1)) & ~bytes32(uint256(0xff));
```

Each storage library: `Store` struct + `store()` function for isolated storage slot.

### FloatLib - Custom Fixed-Point Math

`math/FloatLib.sol` - Custom fixed-point:

- **Type**: `Float` wraps `int256`
- **Structure**: signed base-10 exponent packed with a 72-bit mantissa
- **Precision**: 21 significant digits
- **Normalization**: Mantissa magnitude normalized to `[10^20, 10^21 - 1]`
- **Constants**: ONE, TWO, ..., TEN predefined

Enables precise arithmetic across decimal scales—critical for multi-decimal tokens in accounting.

## Project Structure

```
cavalre-contracts/
├── modules/
│   ├── dispatcher/       # Dispatchable/Dispatcher selector router
│   ├── ledger/           # Hierarchical accounting + ERC20Wrapper
│   ├── staking/          # Staking-reward token creation and accounting
│   └── tree/             # Topology/debug surface
├── math/                 # FloatLib + FloatStrings
├── utilities/            # Reusable abstract contracts
│   ├── Initializable.sol # Initialization guard
│   └── ReentrancyGuard.sol # Module-specific reentrancy protection
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
- Must implement `selectors()` for Dispatcher registration
- Visualize ledger trees via `TreeView` module: `tree.debugTree(root)`
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
