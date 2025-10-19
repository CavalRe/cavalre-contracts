// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ILedgers, ERC20Wrapper} from "../modules/Ledgers.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {console} from "forge-std/src/console.sol";

library LedgersLib {
    struct Store {
        mapping(address => string) name;
        mapping(address => string) symbol;
        mapping(address => uint8) decimals;
        mapping(address => address) root;
        mapping(address sub => address) parent;
        mapping(address parent => address[]) subs;
        mapping(address sub => uint32) subIndex;
        mapping(address => address) wrapper;
        mapping(address => uint8) flags;
        mapping(address => uint256) balance;
        mapping(address owner => mapping(address spender => uint256)) allowances;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledgers")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    uint8 internal constant MAX_DEPTH = 10;
    // toNamedAddress("Total")
    address internal constant TOTAL_ADDRESS = 0xa763678a2e868D872d408672C9f80B77F4d1d14B;
    // toNamedAddress("Reserve")
    address internal constant RESERVE_ADDRESS = 0x3a9097D216F9D5859bE6b3918F997A8823E92984;
    uint8 constant FLAG_IS_GROUP = 1 << 0; // 1 = group node, 0 = leaf/ledger
    uint8 constant FLAG_IS_CREDIT = 1 << 1; // 1 = credit account, 0 = debit
    uint8 constant FLAG_IS_INTERNAL = 1 << 2; // 1 = internal token, 0 = external token

    //==================================================================
    //                            Validation
    //==================================================================

    function checkZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) revert ILedgers.ZeroAddress();
    }

    function isZeroAddress(address addr_) internal pure returns (bool) {
        return addr_ == address(0);
    }

    function flags(bool isGroup_, bool isCredit_, bool isInternal_) internal pure returns (uint8 _flags) {
        if (isGroup_) _flags |= FLAG_IS_GROUP;
        if (isCredit_) _flags |= FLAG_IS_CREDIT;
        if (isInternal_) _flags |= FLAG_IS_INTERNAL;
    }

    function flags(address addr_) internal view returns (bool _isGroup, bool _isCredit, bool _isInternal) {
        uint8 _flags = store().flags[addr_];
        _isGroup = (_flags & FLAG_IS_GROUP) != 0;
        _isCredit = (_flags & FLAG_IS_CREDIT) != 0;
        _isInternal = (_flags & FLAG_IS_INTERNAL) != 0;
    }

    function isGroup(address addr_) internal view returns (bool) {
        return (store().flags[addr_] & FLAG_IS_GROUP) != 0;
    }

    function isCredit(address addr_) internal view returns (bool) {
        return (store().flags[addr_] & FLAG_IS_CREDIT) != 0;
    }

    function isInternal(address addr_) internal view returns (bool) {
        return (store().flags[addr_] & FLAG_IS_INTERNAL) != 0;
    }

    function setGroup(address addr_, bool isGroup_) internal {
        uint8 _flags = store().flags[addr_];
        if (isGroup_) {
            _flags |= FLAG_IS_GROUP;
        } else {
            _flags &= ~FLAG_IS_GROUP;
        }
        store().flags[addr_] = _flags;
    }

    function checkGroup(address addr_) internal view {
        if (!isGroup(addr_)) revert ILedgers.InvalidAccountGroup(addr_);
    }

    function isValidString(string memory str_) internal pure returns (bool) {
        uint256 length = bytes(str_).length;
        return length > 0 && length <= 64;
    }

    function checkString(string memory str_) internal pure {
        if (!isValidString(str_)) revert ILedgers.InvalidString(str_);
    }

    function checkAccountGroup(address addr_) internal view {
        if (!isGroup(addr_)) revert ILedgers.InvalidAccountGroup(addr_);
    }

    function toNamedAddress(string memory name_) internal pure returns (address) {
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(name_)))));
    }

    function toLedgerAddress(address parent_, address ledger_) internal pure returns (address) {
        checkZeroAddress(parent_);
        checkZeroAddress(ledger_);
        return address(uint160(uint256(keccak256(abi.encodePacked(parent_, ledger_)))));
    }

    function toGroupAddress(address parent_, string memory name_) internal pure returns (address) {
        checkZeroAddress(parent_);
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(parent_, toNamedAddress(name_))))));
    }

    // Transfers can only occur within the same tree
    function checkRoots(address a_, address b_) internal view returns (address) {
        address rootA = root(a_);
        if (a_ == b_) return rootA;
        address rootB = root(b_);
        if (rootA != rootB) revert ILedgers.DifferentRoots(a_, b_);
        return rootA;
    }

    //==================
    // Metadata Setters
    //==================
    function name(address addr_, string memory name_) internal {
        checkString(name_);
        store().name[addr_] = name_;
    }

    function symbol(address addr_, string memory symbol_) internal {
        checkString(symbol_);
        store().symbol[addr_] = symbol_;
    }

    function decimals(address addr_, uint8 decimals_) internal {
        if (decimals_ == 0) revert ILedgers.InvalidDecimals(decimals_);
        store().decimals[addr_] = decimals_;
    }

    //==================
    // Metadata Getters
    //==================
    function name(address addr_) internal view returns (string memory) {
        return store().name[addr_];
    }

    function symbol(address addr_) internal view returns (string memory) {
        return store().symbol[addr_];
    }

    function decimals(address addr_) internal view returns (uint8) {
        return store().decimals[addr_];
    }

    function root(address addr_) internal view returns (address _root) {
        _root = store().root[addr_];
        if (_root == address(0)) revert ILedgers.InvalidAccountGroup(addr_);
    }

    function parent(address addr_) internal view returns (address) {
        return store().parent[addr_];
    }

    function subAccounts(address addr_) internal view returns (address[] memory) {
        return store().subs[addr_];
    }

    function subAccount(address parent_, uint256 index_) internal view returns (address) {
        address[] storage subs_ = store().subs[parent_];
        if (index_ >= subs_.length) revert ILedgers.InvalidSubAccountIndex(index_);
        return subs_[index_];
    }

    function hasSubAccount(address addr_) internal view returns (bool) {
        return store().subs[addr_].length > 0;
    }

    function subAccountIndex(address parent_, address addr_) internal view returns (uint32) {
        address _addr = toLedgerAddress(parent_, addr_);
        return store().subIndex[_addr];
    }

    function wrapper(address token_) internal view returns (address) {
        return store().wrapper[token_];
    }

    //==================================================================
    //                        Balance & Supply
    //==================================================================
    function balanceOf(address addr_) internal view returns (uint256) {
        return store().balance[addr_];
    }

    function hasBalance(address addr_) internal view returns (bool) {
        return store().balance[addr_] > 0;
    }

    //==================================================================
    //                         Tree Manipulation
    //==================================================================

    function addSubAccountGroup(address parent_, string memory name_, bool isCredit_) internal returns (address _sub) {
        checkGroup(parent_);
        checkString(name_);

        _sub = toGroupAddress(parent_, name_);

        bool _isExistingParent = parent(_sub) == parent_;
        bool _isExistingName = keccak256(bytes(name(_sub))) == keccak256(bytes(name_));
        if (_isExistingParent && _isExistingName) {
            if ((isCredit(_sub) == isCredit_) && isGroup(_sub)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedgers.InvalidSubAccountGroup(name_, isCredit_);
            }
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.parent[_sub] = parent_;
        s.subs[parent_].push(toNamedAddress(name_));
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(true, isCredit_, true);
        emit ILedgers.SubAccountGroupAdded(_root, parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        internal
        returns (address _sub)
    {
        if (!isGroup(parent_)) revert ILedgers.InvalidAccountGroup(parent_);

        _sub = toLedgerAddress(parent_, addr_);

        bool _isExistingParent = parent(_sub) == parent_;
        if (_isExistingParent) {
            if ((isCredit(_sub) == isCredit_) && !isGroup(_sub)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedgers.InvalidSubAccount(addr_, isCredit_);
            }
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.parent[_sub] = parent_;
        s.subs[parent_].push(addr_);
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(false, isCredit_, true);
        emit ILedgers.SubAccountAdded(_root, parent_, addr_, isCredit_);
    }

    // function addExternalToken(address token_) internal returns (address) {
    //     if (isZeroAddress(token_)) revert ILedgers.InvalidAddress(token_);

    //     string memory _name = IERC20(token_).name();
    //     string memory _symbol = IERC20(token_).symbol();
    //     uint8 _decimals = IERC20(token_).decimals();

    //     Store storage s = store();
    //     // Check if token already exists
    //     if (s.root[token_] == token_) {
    //         // Token already exists
    //         bool _sameName = keccak256(bytes(_name)) == keccak256(bytes(name(token_)));
    //         bool _sameSymbol = keccak256(bytes(_symbol)) == keccak256(bytes(symbol(token_)));
    //         bool _sameDec = _decimals == decimals(token_);
    //         (bool _isGroup, bool _isCredit, bool _isInternal) = flags(token_);
    //         bool _sameType = _isGroup && !_isCredit && !_isInternal;
    //         if (_sameName && _sameSymbol && _sameDec && _sameType) {
    //             // No changes needed
    //             return token_;
    //         }
    //         revert ILedgers.InvalidToken(token_, _name, _symbol, _decimals, _isCredit, _isInternal);
    //     }
    //     if (!isInternal_) {
    //         bool _sameName = keccak256(bytes(name_)) == keccak256(bytes(IERC20(token_).name()));
    //         bool _sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(IERC20(token_).symbol()));
    //         bool _sameDec = IERC20(token_).decimals() == decimals_;
    //         if (!_sameName || !_sameSymbol || !_sameDec) {
    //             revert ILedgers.InvalidToken(token_, name_, symbol_, decimals_, isCredit_, isInternal_);
    //         }
    //         name_ = string(abi.encodePacked(name_, " | CavalRe"));
    //         symbol_ = string(abi.encodePacked(symbol_, ".cav"));
    //         token_ = address(new ERC20Wrapper(address(this), name_, symbol_, decimals_));
    //     }
    //     s.name[token_] = name_;
    //     s.symbol[token_] = symbol_;
    //     s.decimals[token_] = decimals_;
    //     s.root[token_] = token_;
    //     s.flags[token_] = flags(true, false, isInternal_);

    //     // Add a "Total" credit subaccount group
    //     addSubAccountGroup(token_, "Total", true);

    //     // Add a "Reserve" debit subaccount
    //     addSubAccount(token_, RESERVE_ADDRESS, "Reserve", false);

    //     // Add a subaccount to Scale for this token
    //     if (token_ != address(this)) {
    //         addSubAccount(address(this), token_, name_, isCredit_);
    //     }

    //     emit ILedgers.LedgerAdded(token_, name_, symbol_, decimals_);

    //     return token_;
    // }

    /* 
        Question:
        For an external token, should Ledgers use the external address or the internal wrapper address?
        For iternal tokens, Ledgers uses the internal wrapper address.
        If we use the internal wrapper address for external tokens, then we need a mapping from external -> internal
    */
    function addLedger(
        address token_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool isCredit_,
        bool isInternal_
    ) internal {
        if (isZeroAddress(token_) || !isValidString(name_) || !isValidString(symbol_) || decimals_ == 0) {
            revert ILedgers.InvalidToken(token_, name_, symbol_, decimals_, isCredit_, isInternal_);
        }

        Store storage s = store();
        // Check if token already exists
        if (token_ != address(0) && s.root[token_] == token_) {
            // Token already exists
            bool _sameName = keccak256(bytes(name_)) == keccak256(bytes(name(token_)));
            bool _sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(symbol(token_)));
            bool _sameDec = decimals(token_) == decimals_;
            (bool _isGroup, bool _isCredit, bool _isInternal) = flags(token_);
            bool _sameType = _isGroup == true && _isCredit == isCredit_ && _isInternal == isInternal_;
            if (_sameName && _sameSymbol && _sameDec && _sameType) {
                // No changes needed
                return;
            }
            revert ILedgers.InvalidToken(token_, name_, symbol_, decimals_, isCredit_, isInternal_);
        }
        // Handle external tokens
        if (!isInternal_) {
            IERC20Metadata meta = IERC20Metadata(token_);
            bool _sameName = keccak256(bytes(name_)) == keccak256(bytes(meta.name()));
            bool _sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(meta.symbol()));
            bool _sameDec = meta.decimals() == decimals_;
            if (!_sameName || !_sameSymbol || !_sameDec) {
                revert ILedgers.InvalidToken(token_, name_, symbol_, decimals_, isCredit_, isInternal_);
            }
            name_ = string(abi.encodePacked(name_, " | CavalRe"));
            symbol_ = string(abi.encodePacked(symbol_, ".cav"));
            address _token = address(new ERC20Wrapper(address(this), name_, symbol_, decimals_));
            s.wrapper[token_] = _token;
            token_ = _token; // Use the internal wrapper address
        }
        s.name[token_] = name_;
        s.symbol[token_] = symbol_;
        s.decimals[token_] = decimals_;
        s.root[token_] = token_;
        s.flags[token_] = flags(true, isCredit_, isInternal_);

        // Add a "Total" credit subaccount group
        addSubAccountGroup(token_, "Total", true);

        // Add a Reserve subaccount and subaccount to Scale for this token
        if (token_ != address(this)) {
            if (isCredit_) {
                addSubAccount(toGroupAddress(token_, "Total"), RESERVE_ADDRESS, "Reserve", isCredit_);
                addSubAccount(toGroupAddress(address(this), "Total"), token_, name_, isCredit_);
            } else {
                addSubAccount(token_, RESERVE_ADDRESS, "Reserve", isCredit_);
                addSubAccount(address(this), token_, name_, isCredit_);
            }
        }

        emit ILedgers.LedgerAdded(token_, name_, symbol_, decimals_);
    }

    function createToken(string memory name_, string memory symbol_, uint8 decimals_, bool isCredit_)
        external
        returns (address)
    {
        address _token = address(new ERC20Wrapper(address(this), name_, symbol_, decimals_));
        addLedger(_token, name_, symbol_, decimals_, isCredit_, true);
        return _token;
    }

    function removeSubAccountGroup(address parent_, string memory name_) internal returns (address) {
        address _sub = toGroupAddress(parent_, name_);
        if (!isGroup(parent_)) revert ILedgers.InvalidAccountGroup(parent_);
        if (!isGroup(_sub)) revert ILedgers.InvalidAccountGroup(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert ILedgers.SubAccountGroupNotFound(name_);
        }

        if (hasSubAccount(_sub)) revert ILedgers.HasSubAccount(_sub);
        if (hasBalance(_sub)) revert ILedgers.HasBalance(_sub);

        Store storage s = store();

        uint256 _index = s.subIndex[_sub]; // 1-based
        uint256 _lastIndex = s.subs[parent_].length; // 1-based
        address _lastChild = s.subs[parent_][_lastIndex - 1];
        address _lastChildAbsolute = toLedgerAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_sub] = "";
        s.root[_sub] = address(0);
        s.parent[_sub] = address(0);
        s.subIndex[_sub] = 0;
        s.flags[_sub] = 0;

        address _root = root(parent_);
        emit ILedgers.SubAccountGroupRemoved(_root, parent_, name_);

        return _sub;
    }

    function removeSubAccount(address parent_, address addr_) internal returns (address) {
        address _sub = toLedgerAddress(parent_, addr_);
        if (!isGroup(parent_)) revert ILedgers.InvalidAccountGroup(parent_);
        if (isGroup(_sub)) revert ILedgers.InvalidLedgerAccount(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert ILedgers.SubAccountNotFound(addr_);
        }

        if (hasSubAccount(_sub)) revert ILedgers.HasSubAccount(addr_);
        if (hasBalance(_sub)) revert ILedgers.HasBalance(addr_);

        Store storage s = store();

        uint256 _index = s.subIndex[_sub]; // 1-based
        uint256 _lastIndex = s.subs[parent_].length; // 1-based
        address _lastChild = s.subs[parent_][_lastIndex - 1];
        address _lastChildAbsolute = toLedgerAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_sub] = "";
        s.root[_sub] = address(0);
        s.parent[_sub] = address(0);
        s.subIndex[_sub] = 0;
        s.flags[_sub] = 0;

        address _root = root(parent_);
        emit ILedgers.SubAccountRemoved(_root, parent_, addr_);

        return _sub;
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function debit(address parent_, address addr_, uint256 amount_, bool emitEvent_) internal returns (address _root) {
        checkAccountGroup(parent_);
        _root = toLedgerAddress(parent_, addr_);

        Store storage s = store();
        uint256 _balance;
        uint8 _depth;
        address _parent = parent_;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (_parent == address(0)) {
                // Root found
                // Emits once after a successful full walk.
                // root = actual token root; (parent_, addr_) = exact leaf address on the tree.
                if (emitEvent_) emit ILedgers.Debit(_root, parent_, addr_, amount_);
                emit ILedgers.BalanceUpdate(_root, parent_, addr_, _balance);
                return _root;
            }
            if (isCredit(_root)) {
                if (s.balance[_root] < amount_) revert ILedgers.InsufficientBalance(_root, parent_, addr_, amount_);
                _balance = s.balance[_root] - amount_;
                s.balance[_root] = _balance;
            } else {
                _balance = s.balance[_root] + amount_;
                s.balance[_root] = _balance;
            }
            _root = _parent;
            _parent = s.parent[_parent];
            _depth++;
        }
        revert ILedgers.MaxDepthExceeded();
    }

    function credit(address parent_, address addr_, uint256 amount_, bool emitEvent_)
        internal
        returns (address _root)
    {
        checkAccountGroup(parent_);
        _root = toLedgerAddress(parent_, addr_);

        Store storage s = store();
        uint256 _balance;
        uint8 _depth;
        address _parent = parent_;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (_parent == address(0)) {
                // Root found
                // Emits once after a successful full walk.
                // root = actual token root; (parent_, addr_) = exact leaf address on the tree.
                if (emitEvent_) emit ILedgers.Credit(_root, parent_, addr_, amount_);
                emit ILedgers.BalanceUpdate(_root, parent_, addr_, _balance);
                return _root;
            }
            if (isCredit(_root)) {
                _balance = s.balance[_root] + amount_;
                s.balance[_root] = _balance;
            } else {
                if (s.balance[_root] < amount_) revert ILedgers.InsufficientBalance(_root, parent_, addr_, amount_);
                _balance = s.balance[_root] - amount_;
                s.balance[_root] = _balance;
            }
            _root = _parent;
            _parent = s.parent[_parent];
            _depth++;
        }
        revert ILedgers.MaxDepthExceeded();
    }

    function wrap(address token_, uint256 amount_) internal {
        address _wrapper = store().wrapper[token_];
        if (_wrapper == address(0)) revert ILedgers.InvalidAddress(token_);
        SafeERC20.safeTransferFrom(IERC20(token_), msg.sender, address(this), amount_);
        mint(_wrapper, msg.sender, amount_);
    }

    function unwrap(address token_, uint256 amount_) internal {
        address _wrapper = store().wrapper[token_];
        if (_wrapper == address(0)) revert ILedgers.InvalidAddress(token_);
        burn(_wrapper, msg.sender, amount_);
        SafeERC20.safeTransfer(IERC20(token_), msg.sender, amount_);
    }

    function transfer(
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) internal returns (bool) {
        address creditRoot = credit(fromParent_, from_, amount_, emitEvent_);
        address debitRoot = debit(toParent_, to_, amount_, emitEvent_);
        if (creditRoot != debitRoot) revert ILedgers.DifferentRoots(creditRoot, debitRoot);
        return true;
    }

    function mint(address toParent_, address to_, uint256 amount_) internal returns (bool) {
        address _token = root(toParent_);
        return transfer(_token, TOTAL_ADDRESS, toParent_, to_, amount_, true);
    }

    function burn(address fromParent_, address from_, uint256 amount_) internal returns (bool) {
        address _token = root(fromParent_);
        return transfer(fromParent_, from_, _token, TOTAL_ADDRESS, amount_, true);
    }

    function approve(address ownerParent_, address owner_, address spender_, uint256 amount_, bool emitEvent_)
        internal
        returns (bool)
    {
        address _owner = toLedgerAddress(ownerParent_, owner_);

        store().allowances[_owner][spender_] = amount_;
        if (emitEvent_) emit ILedgers.InternalApproval(ownerParent_, owner_, spender_, amount_);
        return true;
    }

    /// @notice Increase allowance for (ownerParent_/owner_) → (spenderParent_/spender_) by `added_`.
    function increaseAllowance(address ownerParent_, address owner_, address spender_, uint256 added_, bool emitEvent_)
        internal
        returns (bool, uint256)
    {
        uint256 current = allowance(ownerParent_, owner_, spender_);
        uint256 newAmount = current + added_; // ^0.8 handles overflow
        return (approve(ownerParent_, owner_, spender_, newAmount, emitEvent_), newAmount);
    }

    /// @notice Decrease allowance for (ownerParent_/owner_) → (spenderParent_/spender_) by `subtracted_`.
    /// @dev Reverts on underflow (no clamping).
    function decreaseAllowance(
        address ownerParent_,
        address owner_,
        address spender_,
        uint256 subtracted_,
        bool emitEvent_
    ) internal returns (bool, uint256) {
        uint256 current = allowance(ownerParent_, owner_, spender_);
        if (subtracted_ > current) {
            revert ILedgers.InsufficientAllowance(ownerParent_, owner_, spender_, current, subtracted_);
        }
        uint256 newAmount = current - subtracted_;
        return (approve(ownerParent_, owner_, spender_, newAmount, emitEvent_), newAmount);
    }

    /// @notice Forcefully set allowance for (ownerParent_/owner_) → (spenderParent_/spender_) to `amount_`.
    /// If both current and target are non-zero, sets to 0 first, then to `amount_` (ERC-20 safety pattern).
    function forceApprove(address ownerParent_, address owner_, address spender_, uint256 amount_, bool emitEvent_)
        internal
        returns (bool)
    {
        uint256 current = allowance(ownerParent_, owner_, spender_);

        if (current != 0 && amount_ != 0) {
            // zero first to avoid non-zero→non-zero race
            approve(ownerParent_, owner_, spender_, 0, false);
        }

        return approve(ownerParent_, owner_, spender_, amount_, emitEvent_);
    }

    function allowance(address ownerParent_, address owner_, address spender_) internal view returns (uint256) {
        address _ownerAddress = toLedgerAddress(ownerParent_, owner_);
        return store().allowances[_ownerAddress][spender_];
    }

    function transferFrom(
        address spender_,
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) internal returns (bool) {
        checkRoots(fromParent_, toParent_);
        Store storage s = store();

        address _ownerAddress = toLedgerAddress(fromParent_, from_);
        s.allowances[_ownerAddress][spender_] -= amount_;

        return transfer(fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }
}
