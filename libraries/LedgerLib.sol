// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger, ERC20Wrapper} from "../modules/Ledger.sol";
import {Float, FloatLib} from "./FloatLib.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library LedgerLib {
    using FloatLib for uint256;
    using FloatLib for Float;

    struct Store {
        mapping(address => string) name;
        mapping(address => string) symbol;
        mapping(address => uint8) decimals;
        mapping(address => address) root;
        mapping(address sub => address) parent;
        mapping(address parent => address[]) subs;
        mapping(address sub => uint32) subIndex;
        mapping(address => uint256) flags;
        mapping(address => uint256) balance;
        mapping(address owner => mapping(address spender => uint256)) allowances;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff));

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
    // toNamedAddress("Defaul Source")
    address internal constant DEFAULT_SOURCE_ADDRESS = 0xFa37b787d525B289AA879f2D9bEDF3eDDF0FbeDd;
    uint256 constant FLAG_IS_GROUP = 1 << 0; // 1 = group node, 0 = leaf/ledger
    uint256 constant FLAG_IS_CREDIT = 1 << 1; // 1 = credit account, 0 = debit
    uint256 constant FLAG_IS_INTERNAL = 1 << 2; // 1 = internal token, 0 = external token
    uint256 constant PACK_ADDR_SHIFT = 96; // store address in high 160 bits
    //==================================================================
    //                            Validation
    //==================================================================

    function checkZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) revert ILedger.ZeroAddress();
    }

    function isZeroAddress(address addr_) internal pure returns (bool) {
        return addr_ == address(0);
    }

    function flags(address wrapper_, bool isGroup_, bool isCredit_, bool isInternal_)
        internal
        pure
        returns (uint256 _flags)
    {
        if (isGroup_) _flags |= FLAG_IS_GROUP;
        if (isCredit_) _flags |= FLAG_IS_CREDIT;
        if (isInternal_) _flags |= FLAG_IS_INTERNAL;
        _flags |= (uint256(uint160(wrapper_)) << PACK_ADDR_SHIFT);
    }

    // function flags(address addr_)
    //     internal
    //     view
    //     returns (address _wrapper, bool _isGroup, bool _isCredit, bool _isInternal)
    // {
    //     uint256 _flags = store().flags[addr_];
    //     _wrapper = address(uint160(_flags >> PACK_ADDR_SHIFT));
    //     _isGroup = (_flags & FLAG_IS_GROUP) != 0;
    //     _isCredit = (_flags & FLAG_IS_CREDIT) != 0;
    //     _isInternal = (_flags & FLAG_IS_INTERNAL) != 0;
    // }

    function flags(address addr_) internal view returns (uint256) {
        return store().flags[addr_];
    }

    function wrapper(uint256 flags_) internal pure returns (address) {
        return address(uint160(flags_ >> PACK_ADDR_SHIFT));
    }

    function isGroup(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_GROUP) != 0;
    }

    function isCredit(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_CREDIT) != 0;
    }

    function isInternal(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_INTERNAL) != 0;
    }

    function wrapper(address token_) internal view returns (address) {
        return wrapper(store().flags[token_]);
    }

    function isGroup(address addr_) internal view returns (bool) {
        return isGroup(store().flags[addr_]);
    }

    function isCredit(address addr_) internal view returns (bool) {
        return isCredit(store().flags[addr_]);
    }

    function isInternal(address addr_) internal view returns (bool) {
        return isInternal(store().flags[addr_]);
    }

    function checkGroup(address addr_) internal view {
        if (!isGroup(addr_)) revert ILedger.InvalidAccountGroup(addr_);
    }

    function isValidString(string memory str_) internal pure returns (bool) {
        uint256 length = bytes(str_).length;
        return length > 0 && length <= 64;
    }

    function checkString(string memory str_) internal pure {
        if (!isValidString(str_)) revert ILedger.InvalidString(str_);
    }

    function checkAccountGroup(address addr_) internal view {
        if (!isGroup(addr_)) revert ILedger.InvalidAccountGroup(addr_);
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
        if (rootA != rootB) revert ILedger.DifferentRoots(a_, b_);
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
        if (decimals_ == 0) revert ILedger.InvalidDecimals(decimals_);
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
        if (_root == address(0)) revert ILedger.InvalidAccountGroup(addr_);
    }

    function parent(address addr_) internal view returns (address) {
        return store().parent[addr_];
    }

    function subAccounts(address addr_) internal view returns (address[] memory) {
        return store().subs[addr_];
    }

    function subAccount(address parent_, uint256 index_) internal view returns (address) {
        address[] storage subs_ = store().subs[parent_];
        if (index_ >= subs_.length) revert ILedger.InvalidSubAccountIndex(index_);
        return subs_[index_];
    }

    function hasSubAccount(address addr_) internal view returns (bool) {
        return store().subs[addr_].length > 0;
    }

    function subAccountIndex(address parent_, address addr_) internal view returns (uint32) {
        address _addr = toLedgerAddress(parent_, addr_);
        return store().subIndex[_addr];
    }

    //==================================================================
    //                        Balance & Valuation
    //==================================================================
    function balanceOf(address addr_) internal view returns (uint256) {
        return store().balance[addr_];
    }

    function hasBalance(address addr_) internal view returns (bool) {
        return store().balance[addr_] > 0;
    }

    function parent(address addr_, bool isCredit_) internal pure returns (address) {
        if (isCredit_) {
            return toGroupAddress(addr_, "Total");
        } else {
            return addr_;
        }
    }

    function reserveAddress(address token_) internal view returns (address) {
        return toLedgerAddress(parent(token_, isCredit(token_)), RESERVE_ADDRESS);
    }

    function scaleAddress(address token_) internal view returns (address) {
        return toLedgerAddress(parent(address(this), isCredit(token_)), token_);
    }

    function reserve(address token_) internal view returns (uint256) {
        return balanceOf(reserveAddress(token_));
    }

    function scale(address token_) internal view returns (uint256) {
        return balanceOf(scaleAddress(token_));
    }

    function price(address token_) internal view returns (Float memory) {
        Float memory _reserve = reserve(token_).toFloat(uint256(decimals(token_)));
        if (_reserve.mantissa == 0) revert ILedger.ZeroReserve(token_);
        Float memory _scale = scale(token_).toFloat();
        return _scale.divide(_reserve);
    }

    function totalValue(address token_) internal view returns (Float memory) {
        uint8 _decimals = decimals(token_);
        Float memory _reserve = reserve(token_).toFloat(uint256(_decimals));
        if (_reserve.mantissa == 0) revert ILedger.ZeroReserve(token_);
        Float memory _scale = scale(token_).toFloat();
        Float memory _totalSupply = isInternal(token_)
            ? balanceOf(toLedgerAddress(parent(address(this), isCredit(token_)), token_)).toFloat(_decimals)
            : IERC20(token_).totalSupply().toFloat(_decimals);
        return _totalSupply.fullMulDiv(_scale, _reserve);
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
                revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
            }
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.parent[_sub] = parent_;
        s.subs[parent_].push(toNamedAddress(name_));
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(_root, true, isCredit_, true);
        emit ILedger.SubAccountGroupAdded(_root, parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        internal
        returns (address _sub)
    {
        if (!isGroup(parent_)) revert ILedger.InvalidAccountGroup(parent_);

        _sub = toLedgerAddress(parent_, addr_);

        bool _isExistingParent = parent(_sub) == parent_;
        if (_isExistingParent) {
            if ((isCredit(_sub) == isCredit_) && !isGroup(_sub)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedger.InvalidSubAccount(addr_, isCredit_);
            }
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.parent[_sub] = parent_;
        s.subs[parent_].push(addr_);
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(_root, false, isCredit_, true);
        emit ILedger.SubAccountAdded(_root, parent_, addr_, isCredit_);
    }

    function addLedger(
        address root_,
        address wrapper_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool isCredit_,
        bool isInternal_
    ) internal {
        if (
            isZeroAddress(root_) // Root cannot be zero address
                || (root_ == address(this) && !isZeroAddress(wrapper_)) // If root is Ledger, wrapper must be zero address
                || (isZeroAddress(wrapper_) && root_ != address(this)) // If root is not Ledger, wrapper cannot be zero address
                || !isValidString(name_) || !isValidString(symbol_)
        ) {
            revert ILedger.InvalidToken(root_, name_, symbol_, decimals_);
        }

        Store storage s = store();
        // Check if token already exists
        if (s.root[root_] == root_) {
            // Token already exists
            bool _sameName = keccak256(bytes(name_)) == keccak256(bytes(name(root_)));
            bool _sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(symbol(root_)));
            bool _sameDec = decimals(root_) == decimals_;
            if (_sameName && _sameSymbol && _sameDec) {
                // No changes needed
                return;
            }
            revert ILedger.InvalidToken(root_, name_, symbol_, decimals_);
        }
        s.name[root_] = name_;
        s.symbol[root_] = symbol_;
        s.decimals[root_] = decimals_;
        s.root[root_] = root_;
        s.flags[root_] = flags(wrapper_, true, isCredit_, isInternal_);

        // Add a "Total" credit subaccount group
        addSubAccountGroup(root_, "Total", true);
        addSubAccount(toLedgerAddress(root_, TOTAL_ADDRESS), DEFAULT_SOURCE_ADDRESS, "Default Source", true);

        // Add a Reserve subaccount and subaccount to Scale for this token
        if (root_ != address(this)) {
            addSubAccount(parent(root_, isCredit_), RESERVE_ADDRESS, "Reserve", isCredit_);
            addSubAccount(parent(address(this), isCredit_), root_, name_, isCredit_);
        }

        emit ILedger.LedgerAdded(root_, name_, symbol_, decimals_);
    }

    function createWrappedToken(address token_) internal {
        IERC20Metadata _meta = IERC20Metadata(token_);
        string memory _name = _meta.name();
        string memory _symbol = _meta.symbol();
        uint8 _decimals = _meta.decimals();
        if (!isValidString(_name) || !isValidString(_symbol)) {
            revert ILedger.InvalidToken(token_, _name, _symbol, _decimals);
        }
        address _wrapper = address(
            new ERC20Wrapper(
                address(this),
                token_,
                string(abi.encodePacked(_name, " | CavalRe")),
                string(abi.encodePacked(_symbol, ".cav")),
                _decimals
            )
        );
        addLedger(token_, _wrapper, _name, _symbol, _decimals, false, false);
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, bool isCredit_)
        internal
        returns (address wrapper_)
    {
        if (!isValidString(name_) || !isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }
        wrapper_ = address(new ERC20Wrapper(address(this), address(0), name_, symbol_, decimals_));
        addLedger(wrapper_, wrapper_, name_, symbol_, decimals_, isCredit_, true);
    }

    function removeSubAccountGroup(address parent_, string memory name_) internal returns (address) {
        address _sub = toGroupAddress(parent_, name_);
        if (!isGroup(parent_)) revert ILedger.InvalidAccountGroup(parent_);
        if (!isGroup(_sub)) revert ILedger.InvalidAccountGroup(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert ILedger.SubAccountGroupNotFound(name_);
        }

        if (hasSubAccount(_sub)) revert ILedger.HasSubAccount(_sub);
        if (hasBalance(_sub)) revert ILedger.HasBalance(_sub);

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
        emit ILedger.SubAccountGroupRemoved(_root, parent_, name_);

        return _sub;
    }

    function removeSubAccount(address parent_, address addr_) internal returns (address) {
        address _sub = toLedgerAddress(parent_, addr_);
        if (!isGroup(parent_)) revert ILedger.InvalidAccountGroup(parent_);
        if (isGroup(_sub)) revert ILedger.InvalidLedgerAccount(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert ILedger.SubAccountNotFound(addr_);
        }

        if (hasSubAccount(_sub)) revert ILedger.HasSubAccount(addr_);
        if (hasBalance(_sub)) revert ILedger.HasBalance(addr_);

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
        emit ILedger.SubAccountRemoved(_root, parent_, addr_);

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
                if (emitEvent_) emit ILedger.Debit(_root, parent_, addr_, amount_);
                emit ILedger.BalanceUpdate(_root, parent_, addr_, _balance);
                return _root;
            }
            if (isCredit(_root)) {
                if (s.balance[_root] < amount_) revert ILedger.InsufficientBalance(_root, parent_, addr_, amount_);
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
        revert ILedger.MaxDepthExceeded();
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
                if (emitEvent_) emit ILedger.Credit(_root, parent_, addr_, amount_);
                emit ILedger.BalanceUpdate(_root, parent_, addr_, _balance);
                return _root;
            }
            if (isCredit(_root)) {
                _balance = s.balance[_root] + amount_;
                s.balance[_root] = _balance;
            } else {
                if (s.balance[_root] < amount_) revert ILedger.InsufficientBalance(_root, parent_, addr_, amount_);
                _balance = s.balance[_root] - amount_;
                s.balance[_root] = _balance;
            }
            _root = _parent;
            _parent = s.parent[_parent];
            _depth++;
        }
        revert ILedger.MaxDepthExceeded();
    }

    function wrap(address token_, uint256 amount_) internal {
        address _wrapper = wrapper(token_);
        if (_wrapper == address(0)) revert ILedger.InvalidAddress(token_);
        SafeERC20.safeTransferFrom(IERC20(token_), msg.sender, address(this), amount_);
        mint(token_, msg.sender, amount_);
    }

    function unwrap(address token_, uint256 amount_) internal {
        address _wrapper = wrapper(token_);
        if (_wrapper == address(0)) revert ILedger.InvalidAddress(token_);
        burn(token_, msg.sender, amount_);
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
        if (creditRoot != debitRoot) revert ILedger.DifferentRoots(creditRoot, debitRoot);
        return true;
    }

    function mint(address toParent_, address to_, uint256 amount_) internal returns (bool) {
        address _token = root(toParent_);
        return transfer(toLedgerAddress(_token, TOTAL_ADDRESS), DEFAULT_SOURCE_ADDRESS, toParent_, to_, amount_, true);
    }

    function burn(address fromParent_, address from_, uint256 amount_) internal returns (bool) {
        address _token = root(fromParent_);
        return
            transfer(fromParent_, from_, toLedgerAddress(_token, TOTAL_ADDRESS), DEFAULT_SOURCE_ADDRESS, amount_, true);
    }

    function approve(address ownerParent_, address owner_, address spender_, uint256 amount_, bool emitEvent_)
        internal
        returns (bool)
    {
        address _owner = toLedgerAddress(ownerParent_, owner_);

        store().allowances[_owner][spender_] = amount_;
        if (emitEvent_) emit ILedger.InternalApproval(ownerParent_, owner_, spender_, amount_);
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
            revert ILedger.InsufficientAllowance(ownerParent_, owner_, spender_, current, subtracted_);
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
