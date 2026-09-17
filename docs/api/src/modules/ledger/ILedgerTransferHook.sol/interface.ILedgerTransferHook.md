# ILedgerTransferHook
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5316bd1d9e8e7ab1df82167844d0b85518ce76e4/modules/ledger/ILedgerTransferHook.sol)

Optional Dispatcher callback, invoked before Ledger balances change.

Implementations must authenticate the Dispatcher self-call. Account arguments are absolute keys.


## Functions
### beforeLedgerTransfer


```solidity
function beforeLedgerTransfer(
    address ledger,
    address from,
    address to,
    bool fromIsCredit,
    bool toIsCredit,
    uint256 amount
) external;
```

