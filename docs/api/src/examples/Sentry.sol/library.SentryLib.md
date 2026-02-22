# SentryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/examples/Sentry.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 internal constant STORE_POSITION = keccak256("@cavalre.sentry.store")
```


### TRANSFER_OWNERSHIP

```solidity
bytes4 internal constant TRANSFER_OWNERSHIP = bytes4(keccak256("transferOwnership(address,address)"))
```


### ACCEPT_OWNERSHIP

```solidity
bytes4 internal constant ACCEPT_OWNERSHIP = bytes4(keccak256("acceptOwnership(address)"))
```


### RENOUNCE_OWNERSHIP

```solidity
bytes4 internal constant RENOUNCE_OWNERSHIP = bytes4(keccak256("renounceOwnership(address)"))
```


### CONFIRM_RENOUNCE_OWNERSHIP

```solidity
bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP = bytes4(keccak256("confirmRenounceOwnership(address)"))
```


### PENDING_OWNER

```solidity
bytes4 internal constant PENDING_OWNER = bytes4(keccak256("pendingOwner(address)"))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

