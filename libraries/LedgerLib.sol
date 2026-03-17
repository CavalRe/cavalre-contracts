// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger, ERC20Wrapper} from "../modules/Ledger.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library LedgerLib {
    struct Store {
        mapping(address => string) name;
        mapping(address => string) symbol;
        mapping(address => uint8) decimals;
        mapping(address => address) root;
        mapping(address => address) wrapper;
        mapping(address parent => address[]) subs;
        mapping(address sub => uint32) subIndex;
        mapping(address => uint256) flags;
        mapping(address => uint256) debits;
        mapping(address => uint256) credits;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 _position = STORE_POSITION;
        assembly {
            s.slot := _position
        }
    }

    uint8 internal constant MAX_DEPTH = 10;
    // toAddress("Native")
    address internal constant NATIVE_ADDRESS = 0xE0092BfAe8c1A1d8CB953ed67bd42A4861E423F9;
    // toAddress("Unallocated")
    address internal constant SOURCE_ADDRESS = 0x245f14e61ecde591FD8B445DC8e2bF76da4505E6;
    uint256 constant FLAG_IS_GROUP = 1 << 0; // 1 = group node, 0 = leaf/ledger
    uint256 constant FLAG_IS_CREDIT = 1 << 1; // 1 = credit account, 0 = debit
    uint256 constant FLAG_IS_INTERNAL = 1 << 2; // 1 = internal token, 0 = external token
    uint256 constant FLAG_IS_NATIVE = 1 << 3; // 1 = native token root
    uint256 constant FLAG_IS_WRAPPER = 1 << 4; // 1 = token has wrapper surface
    uint256 constant FLAG_IS_REGISTERED = 1 << 5; // 1 = account registered via addSubAccount*()
    uint256 constant FLAG_DEPTH_SHIFT = 8;
    uint256 constant FLAG_DEPTH_MASK = uint256(0xff) << FLAG_DEPTH_SHIFT;
    uint256 constant PACK_ADDR_SHIFT = 96; // store address in high 160 bits

    //==================================================================
    //                            Validation
    //==================================================================

    function isZeroAddress(address addr_) internal pure returns (bool) {
        return addr_ == address(0);
    }

    function checkZeroAddress(address addr_) internal pure {
        if (isZeroAddress(addr_)) revert ILedger.ZeroAddress();
    }

    function isValidString(string memory str_) internal pure returns (bool) {
        uint256 length = bytes(str_).length;
        return length > 0 && length <= 64;
    }

    function checkString(string memory str_) internal pure {
        if (!isValidString(str_)) revert ILedger.InvalidString(str_);
    }

    // Transfers can only occur within the same tree
    function checkRoots(address a_, address b_) internal view returns (address) {
        address rootA = root(a_);
        if (a_ == b_) return rootA;
        address rootB = root(b_);
        if (rootA != rootB) revert ILedger.DifferentRoots(a_, b_);
        return rootA;
    }

    //==================================================================
    //                            Flags
    //==================================================================

    function flags(
        address parent_,
        bool isGroup_,
        bool isCredit_,
        bool isInternal_,
        bool isNative_,
        bool isWrapper_,
        bool isRegistered_,
        uint8 depth_
    ) internal pure returns (uint256 _flags) {
        if (isGroup_) _flags |= FLAG_IS_GROUP;
        if (isCredit_) _flags |= FLAG_IS_CREDIT;
        if (isInternal_) _flags |= FLAG_IS_INTERNAL;
        if (isNative_) _flags |= FLAG_IS_NATIVE;
        if (isWrapper_) _flags |= FLAG_IS_WRAPPER;
        if (isRegistered_) _flags |= FLAG_IS_REGISTERED;
        _flags |= (uint256(depth_) << FLAG_DEPTH_SHIFT);
        _flags |= (uint256(uint160(parent_)) << PACK_ADDR_SHIFT);
    }

    function flags(address addr_) internal view returns (uint256) {
        return store().flags[addr_];
    }

    function parent(uint256 flags_) internal pure returns (address) {
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

    function isNative(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_NATIVE) != 0;
    }

    function isWrapper(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_WRAPPER) != 0;
    }

    function isRegistered(uint256 flags_) internal pure returns (bool) {
        return (flags_ & FLAG_IS_REGISTERED) != 0;
    }

    function depth(uint256 flags_) internal pure returns (uint8) {
        return uint8((flags_ & FLAG_DEPTH_MASK) >> FLAG_DEPTH_SHIFT);
    }

    function isExternal(uint256 flags_) internal pure returns (bool) {
        return !isInternal(flags_) && !isNative(flags_);
    }

    function isRoot(uint256 flags_) internal pure returns (bool) {
        return depth(flags_) == 1 && isGroup(flags_) && isRegistered(flags_) && parent(flags_) == address(0);
    }

    //==================================================================
    //                            Addresses
    //==================================================================

    function toAddress(string memory name_) internal pure returns (address) {
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(name_)))));
    }

    function toAddress(address parent_, address ledger_) internal pure returns (address) {
        checkZeroAddress(parent_);
        checkZeroAddress(ledger_);
        return address(uint160(uint256(keccak256(abi.encodePacked(parent_, ledger_)))));
    }

    function toAddress(address parent_, string memory name_) internal pure returns (address) {
        checkZeroAddress(parent_);
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(parent_, toAddress(name_))))));
    }

    //==================================================================
    //                         Metadata Setters
    //==================================================================
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

    //==================================================================
    //                         Metadata Getters
    //==================================================================
    function name(address addr_) internal view returns (string memory) {
        return store().name[addr_];
    }

    function symbol(address addr_) internal view returns (string memory) {
        return store().symbol[addr_];
    }

    function decimals(address addr_) internal view returns (uint8) {
        return store().decimals[addr_];
    }

    function root(address addr_) internal view returns (address) {
        return store().root[addr_];
    }

    function parent(address addr_) internal view returns (address) {
        return parent(flags(addr_));
    }

    function wrapper(address addr_) internal view returns (address) {
        return store().wrapper[addr_];
    }

    function subAccounts(address addr_) internal view returns (address[] memory) {
        return store().subs[addr_];
    }

    function subAccount(address parent_, uint256 index_) internal view returns (address) {
        address[] storage _subs = store().subs[parent_];
        if (index_ >= _subs.length) {
            revert ILedger.InvalidSubAccountIndex(index_);
        }
        return _subs[index_];
    }

    function hasSubAccount(address addr_) internal view returns (bool) {
        return store().subs[addr_].length > 0;
    }

    function subAccountIndex(address parent_, address addr_) internal view returns (uint32) {
        address _addr = toAddress(parent_, addr_);
        return store().subIndex[_addr];
    }

    //==================================================================
    //                        Balance & Valuation
    //==================================================================
    function debitOf(address addr_) internal view returns (uint256) {
        return store().debits[addr_];
    }

    function creditOf(address addr_) internal view returns (uint256) {
        return store().credits[addr_];
    }

    function balanceOf(address addr_) internal view returns (uint256) {
        Store storage s = store();
        uint256 _debitBalance = s.debits[addr_];
        uint256 _creditBalance = s.credits[addr_];
        return _debitBalance > _creditBalance ? _debitBalance - _creditBalance : _creditBalance - _debitBalance;
    }

    function hasBalance(address addr_) internal view returns (bool) {
        return debitOf(addr_) > 0 || creditOf(addr_) > 0;
    }

    function totalSupply(address token_) internal view returns (uint256 _supply) {
        return debitOf(token_);
    }

    //==================================================================
    //                         Tree Manipulation
    //==================================================================

    function addSubAccountGroup(address parent_, string memory name_, bool isCredit_) internal returns (address _sub) {
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        checkString(name_);

        _sub = toAddress(parent_, name_);

        bool _isExistingParent = parent(_sub) == parent_;
        bool _isExistingName = keccak256(bytes(name(_sub))) == keccak256(bytes(name_));
        if (_isExistingParent && _isExistingName) {
            uint256 _subFlags = flags(_sub);
            if ((isCredit(_subFlags) == isCredit_) && isGroup(_subFlags)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
            }
        }

        address _root = root(parent_);
        uint8 _depth = depth(flags(parent_)) + 1;
        if (_depth > MAX_DEPTH) revert ILedger.MaxDepthExceeded();

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.subs[parent_].push(toAddress(name_));
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(parent_, true, isCredit_, true, false, false, true, _depth);
        emit ILedger.SubAccountGroupAdded(_root, parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        internal
        returns (address _sub)
    {
        if (!isGroup(flags(parent_))) {
            revert ILedger.InvalidAccountGroup();
        }

        _sub = toAddress(parent_, addr_);

        bool _isExistingParent = parent(_sub) == parent_;
        if (_isExistingParent) {
            uint256 _subFlags = flags(_sub);
            if ((isCredit(_subFlags) == isCredit_) && !isGroup(_subFlags)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedger.InvalidSubAccount(addr_, isCredit_);
            }
        }

        address _root = root(parent_);
        uint8 _depth = depth(flags(parent_)) + 1;
        if (_depth > MAX_DEPTH) revert ILedger.MaxDepthExceeded();

        Store storage s = store();
        s.name[_sub] = name_;
        s.root[_sub] = _root;
        s.subs[parent_].push(addr_);
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.flags[_sub] = flags(parent_, false, isCredit_, true, false, false, true, _depth);
        emit ILedger.SubAccountAdded(_root, parent_, addr_, isCredit_);
    }

    function addLedger(address root_, string memory name_, string memory symbol_, uint8 decimals_, bool isInternal_)
        internal
    {
        if (isZeroAddress(root_) || !isValidString(name_) || !isValidString(symbol_)) {
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
        s.wrapper[root_] = address(0);
        bool _isNative = root_ == NATIVE_ADDRESS;
        s.flags[root_] = flags(address(0), true, false, isInternal_, _isNative, false, true, 1);

        emit ILedger.LedgerAdded(root_, name_, symbol_, decimals_);
    }

    function addExternalToken(address token_) internal {
        if (!isZeroAddress(token_) && token_ == root(token_)) {
            revert ILedger.DuplicateToken(token_);
        }

        IERC20Metadata _meta = IERC20Metadata(token_);
        string memory _name = _meta.name();
        string memory _symbol = _meta.symbol();
        uint8 _decimals = _meta.decimals();
        if (!isValidString(_name) || !isValidString(_symbol)) {
            revert ILedger.InvalidToken(token_, _name, _symbol, _decimals);
        }
        addLedger(token_, _name, _symbol, _decimals, false);
    }

    function addInternalToken(string memory name_, string memory symbol_, uint8 decimals_)
        internal
        returns (address token_)
    {
        if (!isValidString(name_) || !isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }
        // Internal roots remain self-wrapped so the root address is immediately usable as an ERC20 surface.
        token_ = address(new ERC20Wrapper(address(this), address(0), name_, symbol_, decimals_));
        addLedger(token_, name_, symbol_, decimals_, true);

        Store storage s = store();
        s.wrapper[token_] = token_;
        s.flags[token_] = flags(address(0), true, false, true, false, true, true, 1);
    }

    function createWrapper(address token_) internal returns (address wrapper_) {
        if (token_ == address(this) || root(token_) != token_) revert ILedger.InvalidAddress(token_);
        if (wrapper(token_) != address(0)) revert ILedger.DuplicateWrapper(token_);

        string memory name_ = name(token_);
        string memory symbol_ = symbol(token_);
        uint8 decimals_ = decimals(token_);
        uint256 flags_ = flags(token_);

        if (isInternal(flags_)) {
            // Internal roots already carry canonical metadata, so their optional wrapper surface is exact.
            wrapper_ = address(new ERC20Wrapper(address(this), token_, name_, symbol_, decimals_));
        } else {
            // External/native wrappers are explicitly branded surfaces over the registered root asset.
            wrapper_ = address(
                new ERC20Wrapper(
                    address(this),
                    token_,
                    string(abi.encodePacked(name_, " | CavalRe")),
                    string(abi.encodePacked(symbol_, ".cav")),
                    decimals_
                )
            );
        }

        Store storage s = store();
        s.wrapper[token_] = wrapper_;
        s.flags[token_] = flags(address(0), true, false, isInternal(flags_), isNative(flags_), true, true, 1);
    }

    function removeSubAccountGroup(address parent_, string memory name_) internal returns (address) {
        address _sub = toAddress(parent_, name_);
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        if (!isGroup(flags(_sub))) revert ILedger.InvalidAccountGroup();

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
        address _lastChildAbsolute = toAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_sub] = "";
        s.root[_sub] = address(0);
        s.subIndex[_sub] = 0;
        s.flags[_sub] = 0;

        address _root = root(parent_);
        emit ILedger.SubAccountGroupRemoved(_root, parent_, name_);

        return _sub;
    }

    function removeSubAccount(address parent_, address addr_) internal returns (address) {
        address _sub = toAddress(parent_, addr_);
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        if (isGroup(flags(_sub))) revert ILedger.InvalidLedgerAccount(_sub);

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
        address _lastChildAbsolute = toAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_sub] = "";
        s.root[_sub] = address(0);
        s.subIndex[_sub] = 0;
        s.flags[_sub] = 0;

        address _root = root(parent_);
        emit ILedger.SubAccountRemoved(_root, parent_, addr_);

        return _sub;
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function debit(address root_, address parent_, address addr_, uint256 amount_) internal {
        if (root_ == address(0)) revert ILedger.ZeroAddress();
        address _current = toAddress(parent_, addr_);
        uint256 _currentFlags = flags(_current);
        if (isGroup(_currentFlags)) revert ILedger.InvalidLedgerAccount(_current);
        uint256 _parentFlags = flags(parent_);
        bool _isRegistered = isRegistered(_currentFlags);
        bool _isCreditSide = _isRegistered ? isCredit(_currentFlags) : isCredit(_parentFlags);

        Store storage s = store();
        uint256 _balance;
        uint8 _depth;
        address _parent = parent_;
        while (_depth < MAX_DEPTH) {
            if (_current != root_ && !isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
            if (_isCreditSide) {
                _balance = s.credits[_current];
                if (_balance < amount_) {
                    revert ILedger.InsufficientBalance(root_, parent_, addr_, amount_);
                }
                _balance -= amount_;
                s.credits[_current] = _balance;
            } else {
                _balance = s.debits[_current] + amount_;
                s.debits[_current] = _balance;
            }
            if (_current == root_) {
                // Root found
                // Emits once after a successful full walk.
                // root = actual token root; (parent_, addr_) = exact leaf address on the tree.
                emit ILedger.Debit(root_, parent_, addr_, amount_);
                emit ILedger.BalanceUpdate(root_, parent_, addr_, _balance);
                return;
            }
            _current = _parent;
            _parent = parent(_parentFlags);
            _parentFlags = flags(_parent);
            _depth++;
        }
        revert ILedger.MaxDepthExceeded();
    }

    function credit(address root_, address parent_, address addr_, uint256 amount_) internal {
        if (root_ == address(0)) revert ILedger.ZeroAddress();
        address _current = toAddress(parent_, addr_);
        uint256 _currentFlags = flags(_current);
        if (isGroup(_currentFlags)) revert ILedger.InvalidLedgerAccount(_current);
        uint256 _parentFlags = flags(parent_);
        bool _isRegistered = isRegistered(_currentFlags);
        bool _isCreditSide = _isRegistered ? isCredit(_currentFlags) : isCredit(_parentFlags);

        Store storage s = store();
        uint256 _balance;
        uint8 _depth;
        address _parent = parent_;
        while (_depth < MAX_DEPTH) {
            if (_current != root_ && !isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
            if (_isCreditSide) {
                _balance = s.credits[_current] + amount_;
                s.credits[_current] = _balance;
            } else {
                _balance = s.debits[_current];
                if (_balance < amount_) {
                    revert ILedger.InsufficientBalance(root_, parent_, addr_, amount_);
                }
                _balance -= amount_;
                s.debits[_current] = _balance;
            }
            if (_current == root_) {
                // Root found
                // Emits once after a successful full walk.
                // root = actual token root; (parent_, addr_) = exact leaf address on the tree.
                emit ILedger.Credit(root_, parent_, addr_, amount_);
                emit ILedger.BalanceUpdate(root_, parent_, addr_, _balance);
                return;
            }
            _current = _parent;
            _parent = parent(_parentFlags);
            _parentFlags = flags(_parent);
            _depth++;
        }
        revert ILedger.MaxDepthExceeded();
    }

    function wrap(address token_, uint256 amount_, address sourceParent_, address source_) internal {
        if (root(token_) != token_) revert ILedger.InvalidAddress(token_);
        if (token_ == NATIVE_ADDRESS) {
            if (msg.value != amount_) {
                revert ILedger.IncorrectAmount(msg.value, amount_);
            }
            // Native value already sits on the router (this contract via delegatecall),
            // so no external transfer is needed.
        } else {
            if (msg.value != 0) revert ILedger.IncorrectAmount(msg.value, 0);
            SafeERC20.safeTransferFrom(IERC20(token_), msg.sender, address(this), amount_);
        }
        transfer(sourceParent_, source_, token_, msg.sender, amount_);
    }

    function unwrap(address token_, uint256 amount_, address sourceParent_, address source_) internal {
        if (root(token_) != token_) revert ILedger.InvalidAddress(token_);
        if (msg.value != 0) revert ILedger.IncorrectAmount(msg.value, 0);
        if (token_ == NATIVE_ADDRESS) {
            transfer(token_, msg.sender, sourceParent_, source_, amount_);
            (bool _success,) = payable(msg.sender).call{value: amount_}("");
            if (!_success) revert ILedger.NativeTransferFailed();
        } else {
            transfer(token_, msg.sender, sourceParent_, source_, amount_);
            SafeERC20.safeTransfer(IERC20(token_), msg.sender, amount_);
        }
    }

    function _update(
        AccountCache memory acct_,
        address root_,
        mapping(address => uint256) storage balances_,
        uint256 amount_,
        bool isIncreased_
    ) internal returns (uint256 _balance) {
        _balance = balances_[acct_.current];
        if (isIncreased_) {
            _balance += amount_;
            balances_[acct_.current] = _balance;
        } else {
            if (_balance < amount_) {
                revert ILedger.InsufficientBalance(root_, parent(acct_.flags), acct_.current, amount_);
            }
            _balance -= amount_;
            balances_[acct_.current] = _balance;
        }
    }

    struct AccountCache {
        uint256 balance;
        address current;
        uint256 flags;
    }

    function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        internal
        returns (bool)
    {
        address _root = checkRoots(fromParent_, toParent_);
        if (_root == address(0)) revert ILedger.ZeroAddress();

        AccountCache memory fromLeaf;
        AccountCache memory toLeaf;
        fromLeaf.current = toAddress(fromParent_, from_);
        toLeaf.current = toAddress(toParent_, to_);
        if (fromLeaf.current == toLeaf.current) return true;

        fromLeaf.flags = flags(fromLeaf.current);
        if (!isRegistered(fromLeaf.flags)) {
            // Unregistered accounts inherit credit/debit status from their parent but are always one level deeper.
            fromLeaf.flags = uint256(uint160(fromParent_)) << 96;
            if (isCredit(flags(fromParent_))) fromLeaf.flags |= FLAG_IS_CREDIT;
            fromLeaf.flags |= uint256(depth(flags(fromParent_)) + 1) << FLAG_DEPTH_SHIFT;
        }

        toLeaf.flags = flags(toLeaf.current);
        if (!isRegistered(toLeaf.flags)) {
            // Unregistered accounts inherit credit/debit status from their parent but are always one level deeper.
            toLeaf.flags = uint256(uint160(toParent_)) << 96;
            if (isCredit(flags(toParent_))) toLeaf.flags |= FLAG_IS_CREDIT;
            toLeaf.flags |= uint256(depth(flags(toParent_)) + 1) << FLAG_DEPTH_SHIFT;
        }

        bool _isSameSide = isCredit(fromLeaf.flags) == isCredit(toLeaf.flags);

        AccountCache memory from = AccountCache(0, fromLeaf.current, fromLeaf.flags);
        AccountCache memory to = AccountCache(0, toLeaf.current, toLeaf.flags);

        // Ensure current accounts are ledger accounts (not groups)
        if (isGroup(from.flags)) revert ILedger.InvalidLedgerAccount(from.current);
        if (isGroup(to.flags)) revert ILedger.InvalidLedgerAccount(to.current);

        // Ensure max depth is not exceeded before starting the walk.
        if (depth(from.flags) > MAX_DEPTH) revert ILedger.MaxDepthExceeded();
        if (depth(to.flags) > MAX_DEPTH) revert ILedger.MaxDepthExceeded();

        // Ensure roots are valid before starting the walk.
        if (depth(from.flags) == 0) revert ILedger.ZeroDepth();
        if (depth(to.flags) == 0) revert ILedger.ZeroDepth();

        Store storage s = store();
        uint8 _depth = depth(from.flags) > depth(to.flags) ? depth(from.flags) : depth(to.flags);
        while (_depth > 0) {
            // if (_current != _root && !isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
            if (depth(fromLeaf.flags) >= _depth) {
                from.balance = _update(
                    from, _root, isCredit(fromLeaf.flags) ? s.credits : s.debits, amount_, isCredit(fromLeaf.flags)
                );
                if (_depth > 1) {
                    from.current = parent(from.flags);
                    from.flags = flags(from.current);
                }
            }
            if (depth(toLeaf.flags) >= _depth) {
                to.balance =
                    _update(to, _root, isCredit(toLeaf.flags) ? s.credits : s.debits, amount_, !isCredit(toLeaf.flags));
                if (_depth > 1) {
                    to.current = parent(to.flags);
                    to.flags = flags(to.current);
                }
            }
            // Once both walks reach the same ancestor on the same side, remaining upward mutations are identical,
            // so no further net balance changes occur above this point. Depth 1 is the root completion case.
            if (_depth == 1 || (from.current == to.current && _isSameSide)) {
                // Emits once after a successful full walk.
                emit ILedger.Credit(_root, fromParent_, fromLeaf.current, amount_);
                emit ILedger.Debit(_root, toParent_, toLeaf.current, amount_);
                emit ILedger.BalanceUpdate(_root, fromParent_, fromLeaf.current, from.balance);
                emit ILedger.BalanceUpdate(_root, toParent_, toLeaf.current, to.balance);
                return true;
            }
            _depth--;
        }
        revert ILedger.MaxDepthExceeded();
    }

    function reallocate(address fromToken_, address toToken_, uint256 amount_) internal {
        if (amount_ == 0) return;

        transfer(address(this), fromToken_, address(this), toToken_, amount_);
    }
}
