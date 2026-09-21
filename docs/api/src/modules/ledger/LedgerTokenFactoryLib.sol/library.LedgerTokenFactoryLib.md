# LedgerTokenFactoryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/LedgerTokenFactoryLib.sol)


## Functions
### tokenSalt


```solidity
function tokenSalt(ILedgerTokenFactory.TokenMetadata memory token_) internal pure returns (bytes32);
```

### predictERC20TokenAddress

Predict an ordinary internal ERC20Wrapper; shares use different creation bytecode.


```solidity
function predictERC20TokenAddress(ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    view
    returns (address _token);
```

### predictShareTokenAddress

Predict a ShareToken using shared metadata identity and dedicated creation bytecode.

Backing is not part of the salt. Reusing metadata with different backing must fail registration.


```solidity
function predictShareTokenAddress(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address);
```

### createInternalToken


```solidity
function createInternalToken(ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

### createShareToken

Deploy or replay a share token, register its Internal ledger, and bind its backing account.

Trusted internal composition: the consuming module must authorize token creation.
Matching registrations are idempotent; conflicting backing or an existing non-share ledger reverts.


```solidity
function createShareToken(address backingAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

