# CavalRe Contracts

This repository contains the core smart contracts powering [CavalRe](https://cavalre.xyz), a modular, accounting-driven architecture for onchain capital markets. Contracts are organized into clearly separated modules, libraries, utilities, and illustrative examples.

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

* **Module.sol**: Abstract base contract that all modules inherit, defining the shared interface and access to storage.
* **Router.sol**: The immutable entrypoint that delegates calls to upgradeable modules via `delegatecall`.
* **Ledgers.sol**: A hierarchical double-entry accounting system where all token balances live under structured subaccounts.
* **FloatLib.sol**: A custom fixed-point math library for precision arithmetic with dynamic scaling.

## Usage

To use this repo with Foundry, clone and install:

```bash
git clone https://github.com/CavalRe/cavalre-contracts.git
cd cavalre-contracts
forge install
```

### Importing Contracts

Update your `remappings.txt` to include:

```txt
@cavalre/=node_modules/@cavalre/contracts/
```

Then you can import modules like:

```solidity
import "@cavalre/Module.sol";
import "@cavalre/Ledgers/Ledgers.sol";
```

## Philosophy

CavalRe's smart contracts are built with the following principles:

* **Accounting-first architecture** — balances are structured and provable
* **Modular and upgradeable** — contracts are composed through the Router and can be swapped as independent modules
* **Auditable separation of concerns** — no monolithic contracts, everything is isolated and testable

## License

MIT