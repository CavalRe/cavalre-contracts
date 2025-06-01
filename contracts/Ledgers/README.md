# Ledgers.sol

The `Ledgers` contract is a hierarchical, double-entry accounting module designed for managing token balances across arbitrarily nested subaccounts. It extends the `Module` base contract and is designed to be used via delegatecall from the `Router`.

Balances are held only in leaf accounts, while parent accounts act as aggregators and control structures. The system supports accounting semantics (debit/credit classification), deterministic subaccount derivation, and access-controlled transfers and approvals.

## Features

* **Multi-token support**: Each root account defines a distinct token with its own name, symbol, and decimal precision. The system supports multiple tokens concurrently, each with its own hierarchical ledger.
* **Subaccounts as tree nodes**: Token balances are only stored in leaf nodes. Parent accounts are used solely for accounting purposes.
* **Recursive aggregation**: Parent balances reflect the total of all descendants, enabling real-time rollups of strategy- or vault-level balances.
* **Deterministic subaccount addressing**: Subaccount addresses are derived using a hash of the parent address and the subaccount label. This ensures structure without explicit storage of the full tree.
* **Subaccount indexing**: Each parent maintains an ordered list of subaccounts (`subAccounts[parent]`), and each subaccount is assigned a unique `subAccountIndex` for efficient lookup and enumeration.
* **Metadata for all accounts**: Each account (including roots and subaccounts) has its own name, symbol, and decimal setting.
* **Upgradeable architecture**: The system is designed for extensibility and modularity, making it suitable for use within upgradeable, delegatecall-based environments.



## Storage Structure

Defined in the `Store` struct (via `Lib`):

```solidity
struct Store {
    mapping(address => bool) isAccountGroup;
    mapping(address => address) parentAccount;
    mapping(address => uint32) subAccountIndex;
    mapping(address => address[]) subAccounts;

    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;

    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowances;
}
```

## Initialization

The contract uses an initializer (`Initializable`) to prevent re-entry and to ensure that storage is correctly registered on setup.

## Events

### ERC20-Compatible Events

These are standard events used to ensure compatibility with tooling and interfaces that expect ERC20 semantics:

* `Transfer(address indexed from, address indexed to, uint256 value)`
* `Approval(address indexed owner, address indexed spender, uint256 value)`

**Note:** Each ledger (i.e., token) is rooted at a unique address, and that root address corresponds to the token address.  
There is one **special ledger** whose root is the `address(this)` of the Ledger contract itself.  
Only **leaf nodes directly under this main root** are fully ERC20-compatible — these leaves satisfy the ERC20 API, and `Transfer` and `Approval` events are only emitted for operations involving those accounts.

This design allows multiple ledgers (tokens) to coexist under the same contract while maintaining ERC20 compatibility where needed.


### Ledger-Specific Events

These events are unique to the hierarchical ledger design and internal mechanics of the system:

* `InternalTransfer(address indexed from, address indexed to, uint256 value)` — emitted for internal subaccount transfers.
* `InternalApproval(address indexed owner, address indexed spender, uint256 value)` — internal-only approval between subaccounts.
* `SubAccountAdded(address indexed root, address indexed parentAccount, address indexed subAccount)` /  
  `SubAccountRemoved(address indexed root, address indexed parentAccount, address indexed subAccount)` — emitted when subaccounts are added or removed under a parent.
* `SourceAdded(string indexed appName)` / `SourceRemoved(string indexed appName)` — emitted when an application or integration is registered or removed from the ledger.

## Double-Entry Semantics

Every transfer — including minting and burning — is recorded as a **debit to one account and a credit to another**. This enforces true double-entry accounting across all ledger operations.

Each account is classified as either a **debit account** or a **credit account**. The effect of a transfer depends on both the operation (debit/credit) and the account type:

| Operation | Account Type   | Effect on Balance       |
|-----------|----------------|--------------------------|
| Debit     | Debit account  | Increases                |
| Debit     | Credit account | Decreases                |
| Credit    | Debit account  | Decreases                |
| Credit    | Credit account | Increases                |

This model enables consistent, auditable accounting across multi-asset vaults, strategies, and ledger-based financial primitives.


## Example Usage

```solidity
// Create a new subaccount under Alice
address aliceTrading = addSubAccount(alice, "Trading");

// Transfer internally
transfer(alice, aliceTrading, 100e18);
```

## Testing

Test coverage lives under `test/Ledgers/`. Use Foundry:

```bash
forge test --match-path tests/contracts/Ledgers/*
```

## Future Extensions

The ledger architecture is compatible with deploying ERC20 wrapper contracts for individual ledgers (tokens). These wrappers would implement the `IERC20` interface and forward calls like `transfer` and `approve` directly into the `Ledger` contract, preserving a single source of truth for balances while providing token-specific compatibility for external interfaces and aggregators.
