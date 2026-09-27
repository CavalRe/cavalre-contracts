// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger} from "../modules/ledger/ILedger.sol";
import {LedgerLib} from "../modules/ledger/LedgerLib.sol";
import {ERC20TokenLib} from "../modules/ledger/ERC20TokenLib.sol";

library ERC20Lib {
    struct Store {
        mapping(address => mapping(address => uint256)) allowances;
    }

    bytes4 internal constant INITIALIZE_ERC20 = bytes4(keccak256("initializeERC20()"));
    bytes4 internal constant NAME = bytes4(keccak256("name()"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    bytes4 internal constant BALANCE_OF = bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 internal constant INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"));
    bytes4 internal constant DECREASE_ALLOWANCE = bytes4(keccak256("decreaseAllowance(address,uint256)"));
    bytes4 internal constant FORCE_APPROVE = bytes4(keccak256("forceApprove(address,uint256)"));

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position_ = STORE_POSITION;
        assembly {
            s.slot := position_
        }
    }

    /// @dev Canonical ERC20 executes in Dispatcher context and resolves its account flags locally.
    function transfer(address from_, address to_, uint256 amount_) internal returns (bool) {
        (uint256 fromFlags_,, address fromAbsolute_) = LedgerLib.effectiveFlags(address(this), address(this), from_);
        (uint256 toFlags_,,) = LedgerLib.effectiveFlags(address(this), address(this), to_);
        ERC20TokenLib.enforceDebitLeaves(fromFlags_, from_, toFlags_, to_);
        if (from_ == to_ && LedgerLib.balanceOf(fromAbsolute_, false) < amount_) {
            revert ILedger.InsufficientBalance(address(this), address(this), fromAbsolute_, amount_);
        }
        ILedger(address(this)).transfer(address(this), fromFlags_, from_, toFlags_, to_, amount_);
        return true;
    }
}
