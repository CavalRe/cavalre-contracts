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
        _signatures = new string[](18);
        _signatures[0] = "initializeLedger(string,string)";
        _signatures[1] = "addSubAccountGroup(address,string,bool)";
        _signatures[2] = "addSubAccountGroup(address,address,string,bool)";
        _signatures[3] = "addSubAccount(address,string,bool)";
        _signatures[4] = "addSubAccount(address,address,string,bool)";
        _signatures[5] = "addNativeToken()";
        _signatures[6] = "addExternalToken(address)";
        _signatures[7] = "createInternalToken(string,string,uint8,string)";
        _signatures[8] = "createClaimToken(string,string,uint8,address,address,string)";
        _signatures[9] = "removeSubAccountGroup(address,string)";
        _signatures[10] = "removeSubAccountGroup(address,address)";
        _signatures[11] = "removeSubAccount(address,string)";
        _signatures[12] = "removeSubAccount(address,address)";
        _signatures[13] = "transfer(address,address,address,address,uint256)";
        _signatures[14] = "transfer(address,address,address,uint256)";
        _signatures[15] = "wrap(address,uint256)";
        _signatures[16] = "unwrap(address,uint256)";
        _signatures[17] = "handleNative()";
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](18);
        _selectors[n++] = bytes4(keccak256("initializeLedger(string,string)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addNativeToken()"));
        _selectors[n++] = bytes4(keccak256("addExternalToken(address)"));
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,string)"));
        _selectors[n++] = bytes4(keccak256("createClaimToken(string,string,uint8,address,address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("handleNative()"));

        if (n != 18) revert InvalidCommandsLength(n);
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

    function addSubAccountGroup(address parent_, string memory name_, bool isCredit_)
        external
        returns (address, uint256)
    {
        enforceIsOwner();

        return LedgerLib.addSubAccountGroup(parent_, name_, isCredit_);
    }

    function addSubAccountGroup(address parent_, address addr_, string memory name_, bool isCredit_)
        external
        returns (address, uint256)
    {
        enforceIsOwner();

        return LedgerLib.addSubAccountGroup(parent_, addr_, name_, isCredit_);
    }

    function addSubAccount(address parent_, string memory name_, bool isCredit_) external returns (address, uint256) {
        enforceIsOwner();

        return LedgerLib.addSubAccount(parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        external
        returns (address, uint256)
    {
        enforceIsOwner();

        return LedgerLib.addSubAccount(parent_, addr_, name_, isCredit_);
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
        address parent_,
        address addr_,
        string memory version_
    ) external returns (address _token, uint256 _flags) {
        enforceIsOwner();
        return LedgerLib.createClaimToken(name_, symbol_, decimals_, parent_, addr_, version_);
    }

    function removeSubAccountGroup(address parent_, string memory name_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccountGroup(parent_, name_);
    }

    function removeSubAccountGroup(address parent_, address addr_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccountGroup(parent_, addr_);
    }

    function removeSubAccount(address parent_, string memory name_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccount(parent_, name_);
    }

    function removeSubAccount(address parent_, address addr_) external returns (address) {
        enforceIsOwner();

        return LedgerLib.removeSubAccount(parent_, addr_);
    }

    //===========
    // Transfers
    //===========

    function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_) external {
        (address _root, bool _fromIsCredit, bool _toIsCredit) =
            LedgerLib.enforceTransfer(fromParent_, from_, toParent_, to_);
        // Wrapper calls must come from the root wrapper; canonical ERC20 may call via address(this).
        if (msg.sender != LedgerLib.wrapper(_root) && (msg.sender != address(this) || _root != address(this))) {
            revert ILedger.Unauthorized(msg.sender);
        }
        // Public transfer surfaces may not mint from credit into debit accounts.
        if (_fromIsCredit && !_toIsCredit) {
            revert ILedger.InvalidLedgerAccount(fromParent_);
        }
        LedgerLib.transfer(fromParent_, from_, toParent_, to_, amount_);
    }

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external {
        // Direct user transfer uses msg.sender as source leaf under fromParent_.
        (, bool _fromIsCredit, bool _toIsCredit) = LedgerLib.enforceTransfer(fromParent_, msg.sender, toParent_, to_);
        // Public transfers may not mint from credit into debit accounts.
        if (_fromIsCredit && !_toIsCredit) {
            revert ILedger.InvalidLedgerAccount(fromParent_);
        }
        LedgerLib.transfer(fromParent_, msg.sender, toParent_, to_, amount_);
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
        // Wrap mints from the root Zero Address source into msg.sender.
        return LedgerLib.wrap(msg.sender, token_, address(0), token_, msg.sender, amount_);
    }

    function handleNative() external payable nonReentrant {
        LedgerLib.wrap(
            msg.sender, LedgerLib.NATIVE_ADDRESS, address(0), LedgerLib.NATIVE_ADDRESS, msg.sender, msg.value
        );
    }

    function unwrap(address token_, uint256 amount_)
        external
        payable
        nonReentrant
        returns (address _token, bool _fromIsCredit, bool _toIsCredit)
    {
        if (msg.value != 0) revert ILedger.IncorrectAmount(msg.value, 0);
        // Unwrap burns from msg.sender back into the root Zero Address source.
        return LedgerLib.unwrap(msg.sender, token_, msg.sender, token_, address(0), amount_);
    }
}
