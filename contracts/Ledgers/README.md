# Multitoken

Multitoken is a hierarchical token standard implemented in Solidity, designed to support multiple tokens, arbitrary subaccount structures, and true double-entry accounting with debit and credit accounts. It enables tree-like token accounting where balances are tracked at leaf nodes, and parent nodes aggregate their children's balances recursively.

## Features

* Subaccounts as tree nodes: Token balances are only stored in leaf nodes. Parent accounts are used solely for accounting purposes.
* Recursive aggregation: Parent balances reflect the total of all descendants.
* Access control: Only parent nodes can authorize or initiate actions on behalf of their children.
* Deterministic subaccount addressing: Subaccounts are derived using a hash of the parent address and the subaccount label.
* Metadata for all accounts: Each account (including roots and subaccounts) has its own name and symbol.
* Upgradeable architecture: Designed with extensibility and modularity in mind.

## Architecture

```
Root Account (e.g., Alice)
├── Subaccount: Alice/Trading
│   └── Subaccount: Alice/Trading/Binance
└── Subaccount: Alice/Wallet
```

* Only leaf accounts hold balances.
* Transfers between subaccounts preserve hierarchy and isolate activity (e.g., accounting for different strategies or vaults).

## Installation

```bash
npm install https://github.com/CavalRe/cavalre-contracts.git
```

## Usage

### Create a Root Account

```solidity
mint(address root, uint256 amount, string memory name, string memory symbol);
```

### Create a Subaccount

```solidity
createSubaccount(address parent, string memory label);
```

Generates a deterministic subaccount address: `address sub = hash(parent, label);`

### Transfer Between Subaccounts

```solidity
transfer(address from, address to, uint256 amount);
```

* Enforces access control: `msg.sender` must be `from` or a parent of `from`.
* Only allows transfer between valid leaf accounts.

## Testing

Use [Foundry](https://book.getfoundry.sh/) for testing:

```bash
forge test
```

## Security Considerations

* Subaccount creation is deterministic, which avoids collisions but may leak structure.
* Transfers are restricted to leaf nodes. Aggregates are recalculated lazily.
* Avoid storing secrets or relying on subaccount labels for security.

## License

MIT © CavalRe

## Contributions

Pull requests are welcome. Please open an issue first if you have a significant feature request.
