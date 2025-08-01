# CavalRe Contracts

This repository contains the core smart contracts powering [CavalRe](https://caval.re), a modular, accounting-driven architecture for onchain capital markets. Contracts are organized into clearly separated modules, libraries, utilities, and illustrative examples.

## Repository Structure

```txt
cavalre-contracts/
├── contracts/              # Core modules
│   ├── Module.sol          # Abstract base all modules inherit
│   ├── Router.sol          # Immutable delegatecall dispatcher
│   └── Ledgers/            # Ledger-based accounting module
│       ├── Ledgers.sol
│       └── README.md
├── libraries/              # Pure math and string libraries
│   ├── FloatLib/
│   │   └── FloatLib.sol
│   └── FloatStrings/
│       └── FloatStrings.sol
├── utilities/              # Reusable abstract contracts
│   ├── Initializable/
│   │   └── Initializable.sol
│   └── ReentrancyGuard/
│       └── ReentrancyGuard.sol
└── examples/               # Legacy or reference modules
    ├── ERC20/
    │   └── ERC20.sol
    ├── ERC4626/
    │   └── ERC4626.sol
    └── Sentry/
        └── Sentry.sol
```

## Core Concepts

- **Module.sol**: Abstract base contract that all modules inherit, defining the shared interface and access to storage.
- **Router.sol**: The immutable entrypoint that delegates calls to upgradeable modules via `delegatecall`.
- **Ledgers.sol**: A hierarchical double-entry accounting system where all token balances live under structured subaccounts.
- **FloatLib.sol**: A custom fixed-point math library for precision arithmetic with dynamic scaling.

## Installation

To use CavalRe contracts in your project via Git:

```bash
npm install https://github.com/CavalRe/cavalre-contracts.git
```

Then add this to your `remappings.txt`:

```txt
@cavalre/=node_modules/cavalre-contracts/
```

This allows you to import contracts like:

```solidity
import "@cavalre/contracts/Module.sol";
import "@cavalre/contracts/Ledgers/Ledgers.sol";
```

## Philosophy

CavalRe's smart contracts are built with the following principles:

- **Accounting-first architecture** — balances are structured and provable
- **Modular and upgradeable** — contracts are composed through the Router and can be swapped as independent modules
- **Auditable separation of concerns** — no monolithic contracts, everything is isolated and testable

## OpenZeppelin Fork Notice

This project currently uses a fork of [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) to support [module-specific reentrancy guards](contracts/security/ReentrancyGuard.sol) in a diamond-style architecture.

The changes have been merged upstream and will be included in **OpenZeppelin Contracts v5.4**.
Relevant PR: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/5688

Until v5.4 is released, the fork is used via [`npm overrides`](https://docs.npmjs.com/cli/v9/configuring-npm/package-json#overrides), and remappings are adjusted accordingly.

## License

MIT
