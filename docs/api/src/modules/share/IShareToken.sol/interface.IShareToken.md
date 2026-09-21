# IShareToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/share/IShareToken.sol)


## Events
### ShareIssued

```solidity
event ShareIssued(address indexed token, address indexed holder, uint256 shares, uint256 backing);
```

### ShareRedeemed

```solidity
event ShareRedeemed(address indexed token, address indexed holder, uint256 shares, uint256 backing);
```

### ShareCancelled

```solidity
event ShareCancelled(address indexed token, address indexed holder, uint256 shares);
```

## Errors
### InvalidShareState

```solidity
error InvalidShareState(uint256 supply, uint256 backing);
```

### InvalidShareAmount

```solidity
error InvalidShareAmount();
```

### InvalidSettlement

```solidity
error InvalidSettlement();
```

### UnsupportedDecimalDifference

```solidity
error UnsupportedDecimalDifference();
```

