// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {Initializable} from "../../utilities/Initializable.sol";
import {ReentrancyGuard} from "../../utilities/ReentrancyGuard.sol";
import {LedgerLib} from "./LedgerLib.sol";
import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";

import {ILedger} from "./ILedger.sol";

contract Ledger is Dispatchable, Initializable, ReentrancyGuard {
    using ShortStrings for string;

    constructor(uint8 decimals_, string memory nativeName_, string memory nativeSymbol_, uint8 nativeDecimals_) {
        _decimals = decimals_;
        bytes memory nativeNameRaw_ = bytes(nativeName_);
        if (nativeNameRaw_.length == 0 || nativeNameRaw_.length > 31) revert ILedger.InvalidString(nativeName_);
        _nativeName = nativeName_.toShortString();

        bytes memory nativeSymbolRaw_ = bytes(nativeSymbol_);
        if (nativeSymbolRaw_.length == 0 || nativeSymbolRaw_.length > 31) revert ILedger.InvalidString(nativeSymbol_);
        _nativeSymbol = nativeSymbol_.toShortString();

        if (nativeDecimals_ == 0) revert ILedger.InvalidDecimals(nativeDecimals_);
        _nativeDecimals = nativeDecimals_;
    }

    uint8 internal immutable _decimals;
    ShortString internal immutable _nativeName;
    ShortString internal immutable _nativeSymbol;
    uint8 internal immutable _nativeDecimals;
    bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
        abi.encode(uint256(keccak256("cavalre.storage.Ledger.ReentrancyGuard")) - 1)
    ) & ~bytes32(uint256(0xff));

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function _reentrancyGuardStorageSlot() internal pure override returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }

    function signatures() external pure virtual override returns (string[] memory _signatures) {
        _signatures = new string[](14);
        _signatures[0] = "initializeLedger(string,string)";
        _signatures[1] = "addSubAccountGroup(address,address,address,string,bool)";
        _signatures[2] = "addSubAccount(address,address,address,string,bool)";
        _signatures[3] = "addNativeToken()";
        _signatures[4] = "addExternalToken(address)";
        _signatures[5] = "createInternalToken(string,string,uint8,string)";
        _signatures[6] = "createClaimToken(string,string,uint8,address,address,address,string)";
        _signatures[7] = "removeSubAccountGroup(address,address,address)";
        _signatures[8] = "removeSubAccount(address,address,address)";
        _signatures[9] = "transfer(address,address,address,address,address,uint256)";
        _signatures[10] = "transfer(address,address,address,address,uint256)";
        _signatures[11] = "wrap(address,uint256)";
        _signatures[12] = "unwrap(address,uint256)";
        _signatures[13] = "handleNative()";
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](14);
        _selectors[n++] = bytes4(keccak256("initializeLedger(string,string)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addNativeToken()"));
        _selectors[n++] = bytes4(keccak256("addExternalToken(address)"));
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,string)"));
        _selectors[n++] = bytes4(keccak256("createClaimToken(string,string,uint8,address,address,address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("handleNative()"));

        if (n != 14) revert InvalidCommandsLength(n);
    }

    function initializeLedger_unchained(string memory name_, string memory symbol_) public onlyInitializing {
        enforceIsOwner();

        LedgerLib.setNativeMetadata(
            ShortStrings.toString(_nativeName), ShortStrings.toString(_nativeSymbol), _nativeDecimals
        );

        // Canonical root is always registered at the dispatcher address; ERC20 exposure remains an optional module.
        LedgerLib.addLedger(address(this), name_, symbol_, 18, LedgerLib.TokenKind.Internal, address(0));
    }

    function initializeLedger(string memory name_, string memory symbol_) external initializer {
        initializeLedger_unchained(name_, symbol_);
    }

    function addSubAccountGroup(
        address root_,
        address holderParent_,
        address relative_,
        string memory name_,
        bool isCredit_
    ) external returns (address, uint256) {
        enforceIsOwner();

        return LedgerLib.addSubAccountGroup(root_, holderParent_, relative_, name_, isCredit_);
    }

    function addSubAccount(address root_, address holderParent_, address relative_, string memory name_, bool isCredit_)
        external
        returns (address, uint256)
    {
        enforceIsOwner();

        return LedgerLib.addSubAccount(root_, holderParent_, relative_, name_, isCredit_);
    }

    function addNativeToken() external returns (uint256 _flags) {
        enforceIsOwner();
        return LedgerLib.addNativeToken();
    }

    function addExternalToken(address token_) external returns (uint256 _flags) {
        enforceIsOwner();
        return LedgerLib.addExternalToken(token_);
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        external
        returns (address _token, uint256 _flags)
    {
        enforceIsOwner();
        return LedgerLib.createInternalToken(name_, symbol_, decimals_, version_);
    }

    function createClaimToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address root_,
        address holderParent_,
        address relative_,
        string memory version_
    ) external returns (address _token, uint256 _flags) {
        enforceIsOwner();
        return LedgerLib.createClaimToken(name_, symbol_, decimals_, root_, holderParent_, relative_, version_);
    }

    function removeSubAccountGroup(address root_, address holderParent_, address relative_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccountGroup(root_, holderParent_, relative_);
    }

    function removeSubAccount(address root_, address holderParent_, address relative_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccount(root_, holderParent_, relative_);
    }

    //===========
    // Transfers
    //===========

    function transfer(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        uint256 amount_
    ) external {
        (address _root, bool _fromIsCredit, bool _toIsCredit) =
            LedgerLib.enforceTransfer(root_, fromHolderParent_, from_, toHolderParent_, to_);
        // Wrapper calls must come from the root wrapper; canonical ERC20 may call via address(this).
        if (msg.sender != LedgerLib.wrapper(_root) && (msg.sender != address(this) || _root != address(this))) {
            revert ILedger.Unauthorized(msg.sender);
        }
        // Public transfer surfaces may not mint from credit into debit accounts.
        if (_fromIsCredit && !_toIsCredit) {
            revert ILedger.InvalidLedgerAccount(fromHolderParent_);
        }
        LedgerLib.transfer(root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
    }

    function transfer(address root_, address fromHolderParent_, address toHolderParent_, address to_, uint256 amount_)
        external
    {
        // Direct user transfer uses msg.sender as source leaf under fromParent_.
        (, bool _fromIsCredit, bool _toIsCredit) =
            LedgerLib.enforceTransfer(root_, fromHolderParent_, msg.sender, toHolderParent_, to_);
        // Public transfers may not mint from credit into debit accounts.
        if (_fromIsCredit && !_toIsCredit) {
            revert ILedger.InvalidLedgerAccount(fromHolderParent_);
        }
        LedgerLib.transfer(root_, fromHolderParent_, msg.sender, toHolderParent_, to_, amount_);
    }

    function wrap(address token_, uint256 amount_)
        external
        payable
        nonReentrant
        returns (address _token, bool _fromIsCredit, bool _toIsCredit)
    {
        if (token_ != LedgerLib.NATIVE_ADDRESS && msg.value != 0) {
            revert ILedger.IncorrectAmount(msg.value, 0);
        }
        // Wrap mints from the root Source account into msg.sender.
        return LedgerLib.wrap(msg.sender, token_, token_, LedgerLib.SOURCE_ADDRESS, token_, msg.sender, amount_);
    }

    function handleNative() external payable nonReentrant {
        LedgerLib.wrap(
            msg.sender,
            LedgerLib.NATIVE_ADDRESS,
            LedgerLib.NATIVE_ADDRESS,
            LedgerLib.SOURCE_ADDRESS,
            LedgerLib.NATIVE_ADDRESS,
            msg.sender,
            msg.value
        );
    }

    function unwrap(address token_, uint256 amount_)
        external
        payable
        nonReentrant
        returns (address _token, bool _fromIsCredit, bool _toIsCredit)
    {
        if (msg.value != 0) revert ILedger.IncorrectAmount(msg.value, 0);
        // Unwrap burns from msg.sender back into the root Source account.
        return LedgerLib.unwrap(msg.sender, token_, token_, msg.sender, token_, LedgerLib.SOURCE_ADDRESS, amount_);
    }
}
