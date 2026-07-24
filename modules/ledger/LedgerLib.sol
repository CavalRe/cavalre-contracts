// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "./ERC20Wrapper.sol";
import {ILedger} from "./ILedger.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library LedgerLib {
    enum AccountKind {
        Unregistered,
        DebitGroup,
        CreditGroup,
        DebitLedger,
        CreditLedger
    }

    enum TokenKind {
        Unregistered,
        Native,
        External,
        Internal,
        Claim
    }

    struct Store {
        mapping(address => string) name;
        mapping(address => string) symbol;
        mapping(address => uint8) decimals;
        mapping(address => address) root;
        address[] roots;
        mapping(address => uint256) rootIndex;
        mapping(address => address) wrapper;
        mapping(address parent => address[]) subs;
        mapping(address sub => uint32) subIndex;
        mapping(address => uint256) flags;
        mapping(address => uint256) debits;
        mapping(address => uint256) credits;
        string nativeName;
        string nativeSymbol;
        uint8 nativeDecimals;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 _position = STORE_POSITION;
        assembly {
            s.slot := _position
        }
    }

    string internal constant SOURCE_NAME = "Source";
    // toAddress("Source")
    address internal constant SOURCE_ADDRESS = 0x245f14e61ecde591FD8B445DC8e2bF76da4505E6;

    // toAddress("Native")
    address internal constant NATIVE_ADDRESS = 0xE0092BfAe8c1A1d8CB953ed67bd42A4861E423F9;
    uint256 constant ACCOUNT_KIND_SHIFT = 0;
    uint256 constant ACCOUNT_KIND_MASK = uint256(0x07) << ACCOUNT_KIND_SHIFT;
    uint256 constant TOKEN_KIND_SHIFT = 3;
    uint256 constant TOKEN_KIND_MASK = uint256(0x07) << TOKEN_KIND_SHIFT;
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

    function enforceNativeValue(uint256 expected_) internal view {
        if (msg.value != expected_) revert ILedger.IncorrectAmount(msg.value, expected_);
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

    function flags(address packedAddress_, AccountKind accountKind_, TokenKind tokenKind_, uint8 depth_)
        internal
        pure
        returns (uint256 _flags)
    {
        _flags |= uint256(accountKind_) << ACCOUNT_KIND_SHIFT;
        _flags |= uint256(tokenKind_) << TOKEN_KIND_SHIFT;
        _flags |= (uint256(depth_) << FLAG_DEPTH_SHIFT);
        _flags |= (uint256(uint160(packedAddress_)) << PACK_ADDR_SHIFT);
    }

    function flags(address absolute_) internal view returns (uint256) {
        return store().flags[absolute_];
    }

    function rootCount() internal view returns (uint256) {
        return store().roots.length;
    }

    function rootAt(uint256 index_) internal view returns (address) {
        return store().roots[index_];
    }

    function roots(uint256 start_, uint256 limit_) internal view returns (address[] memory _roots) {
        Store storage s = store();
        uint256 _length = s.roots.length;
        if (start_ >= _length) return new address[](0);

        uint256 _available = _length - start_;
        uint256 _count = limit_ < _available ? limit_ : _available;
        _roots = new address[](_count);
        for (uint256 i; i < _count; ++i) {
            _roots[i] = s.roots[start_ + i];
        }
    }

    function accountKind(uint256 flags_) internal pure returns (AccountKind) {
        return AccountKind((flags_ & ACCOUNT_KIND_MASK) >> ACCOUNT_KIND_SHIFT);
    }

    function tokenKind(uint256 flags_) internal pure returns (TokenKind) {
        return TokenKind((flags_ & TOKEN_KIND_MASK) >> TOKEN_KIND_SHIFT);
    }

    function packedAddress(uint256 flags_) internal pure returns (address) {
        // Safe because packed addresses occupy exactly the high 160-bit lane.
        // forge-lint: disable-next-line(unsafe-typecast)
        return address(uint160(flags_ >> PACK_ADDR_SHIFT));
    }

    function holderParent(uint256 flags_) internal pure returns (address) {
        if (isRoot(flags_)) return address(0);
        return packedAddress(flags_);
    }

    function isUnregisteredAccount(uint256 flags_) internal pure returns (bool) {
        return accountKind(flags_) == AccountKind.Unregistered;
    }

    function isDebitGroup(uint256 flags_) internal pure returns (bool) {
        return accountKind(flags_) == AccountKind.DebitGroup;
    }

    function isCreditGroup(uint256 flags_) internal pure returns (bool) {
        return accountKind(flags_) == AccountKind.CreditGroup;
    }

    function isDebitLedger(uint256 flags_) internal pure returns (bool) {
        return accountKind(flags_) == AccountKind.DebitLedger;
    }

    function isCreditLedger(uint256 flags_) internal pure returns (bool) {
        return accountKind(flags_) == AccountKind.CreditLedger;
    }

    function isGroup(uint256 flags_) internal pure returns (bool) {
        return isDebitGroup(flags_) || isCreditGroup(flags_);
    }

    function isLedger(uint256 flags_) internal pure returns (bool) {
        return isDebitLedger(flags_) || isCreditLedger(flags_);
    }

    function isCredit(uint256 flags_) internal pure returns (bool) {
        return isCreditGroup(flags_) || isCreditLedger(flags_);
    }

    function effectiveFlags(address root_, address holderParent_, address relative_)
        internal
        view
        returns (uint256 _effectiveFlags, uint256 _originalFlags, address _absolute)
    {
        address _absoluteParent = holderParent_ == root_ ? root_ : toAddress(root_, holderParent_);
        _absolute = toAddress(root_, holderParent_, relative_);
        _originalFlags = flags(_absolute);
        if (!isUnregisteredAccount(_originalFlags)) return (_originalFlags, _originalFlags, _absolute);
        if (_originalFlags != 0) revert ILedger.InvalidAddress(relative_);

        // Unregistered derived leaves inherit polarity and depth from their parent.
        uint256 _parentFlags = flags(_absoluteParent);
        _effectiveFlags = flags(
            holderParent_,
            isCredit(_parentFlags) ? AccountKind.CreditLedger : AccountKind.DebitLedger,
            TokenKind.Unregistered,
            depth(_parentFlags) + 1
        );
    }

    function isUnregisteredToken(uint256 flags_) internal pure returns (bool) {
        return tokenKind(flags_) == TokenKind.Unregistered;
    }

    function isInternal(uint256 flags_) internal pure returns (bool) {
        return tokenKind(flags_) == TokenKind.Internal;
    }

    function isNative(uint256 flags_) internal pure returns (bool) {
        return tokenKind(flags_) == TokenKind.Native;
    }

    function depth(uint256 flags_) internal pure returns (uint8) {
        // Safe because FLAG_DEPTH_MASK bounds the shifted value to one byte.
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint8((flags_ & FLAG_DEPTH_MASK) >> FLAG_DEPTH_SHIFT);
    }

    function isExternal(uint256 flags_) internal pure returns (bool) {
        return tokenKind(flags_) == TokenKind.External;
    }

    function isRoot(uint256 flags_) internal pure returns (bool) {
        return depth(flags_) == 1 && isGroup(flags_);
    }

    function isClaim(uint256 flags_) internal pure returns (bool) {
        return tokenKind(flags_) == TokenKind.Claim;
    }

    function claimAccount(uint256 flags_) internal pure returns (address) {
        if (!isRoot(flags_) || !isClaim(flags_)) return address(0);
        return packedAddress(flags_);
    }

    function checkClaimAccount(address claimTokenAddress_, address absoluteClaimAccount_) internal view {
        if (!isLedger(flags(absoluteClaimAccount_))) revert ILedger.InvalidLedgerAccount(absoluteClaimAccount_);
        address _claimAccountRoot = root(absoluteClaimAccount_);
        if (_claimAccountRoot == claimTokenAddress_ || isClaim(flags(_claimAccountRoot))) {
            revert ILedger.InvalidLedgerAccount(absoluteClaimAccount_);
        }
    }

    //==================================================================
    //                            Addresses
    //==================================================================

    /// @notice Derives a relative address from a human-readable name.
    /// @dev Relative addresses are reusable across token trees and become holder addresses under a holder parent.
    function toAddress(string memory name_) internal pure returns (address) {
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(name_)))));
    }

    /// @notice Derives the next address in an address tree.
    /// @dev Use `toAddress(holderParent, relative)` for holders, and `toAddress(root, holder)` for absolute keys.
    function toAddress(address base_, address relative_) internal pure returns (address) {
        checkZeroAddress(base_);
        return address(uint160(uint256(keccak256(abi.encodePacked(base_, relative_)))));
    }

    /// @notice Derives an absolute Ledger storage address in root scope.
    /// @dev First derives the holder from `holderParent_ + relative_`, then projects it through `root_`.
    function toAddress(address root_, address holderParent_, address relative_) internal pure returns (address) {
        address _holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        return toAddress(root_, _holder);
    }

    /// @notice Derives a named relative address in a holder-parent context.
    /// @dev This is a contextual relative value, not an absolute Ledger storage key.
    function toAddress(address holderParent_, string memory name_) internal pure returns (address) {
        checkZeroAddress(holderParent_);
        checkString(name_);
        return address(uint160(uint256(keccak256(abi.encodePacked(holderParent_, toAddress(name_))))));
    }

    //==================================================================
    //                         Metadata Setters
    //==================================================================
    function name(address absolute_, string memory name_) internal {
        checkString(name_);
        store().name[absolute_] = name_;
    }

    function symbol(address absolute_, string memory symbol_) internal {
        checkString(symbol_);
        store().symbol[absolute_] = symbol_;
    }

    function decimals(address absolute_, uint8 decimals_) internal {
        if (decimals_ == 0) revert ILedger.InvalidDecimals(decimals_);
        store().decimals[absolute_] = decimals_;
    }

    //==================================================================
    //                         Metadata Getters
    //==================================================================
    function name(address absolute_) internal view returns (string memory) {
        return store().name[absolute_];
    }

    function symbol(address absolute_) internal view returns (string memory) {
        return store().symbol[absolute_];
    }

    function decimals(address absolute_) internal view returns (uint8) {
        return store().decimals[absolute_];
    }

    function root(address absolute_) internal view returns (address) {
        return store().root[absolute_];
    }

    function wrapper(address absolute_) internal view returns (address) {
        return store().wrapper[absolute_];
    }

    function subAccounts(address absolute_) internal view returns (address[] memory) {
        return store().subs[absolute_];
    }

    function subAccount(address absolute_, uint256 index_) internal view returns (address) {
        address[] storage _subs = store().subs[absolute_];
        if (index_ >= _subs.length) {
            revert ILedger.InvalidSubAccountIndex(index_);
        }
        return _subs[index_];
    }

    function hasSubAccount(address absolute_) internal view returns (bool) {
        return store().subs[absolute_].length > 0;
    }

    function subAccountIndex(address absolute_) internal view returns (uint32) {
        return store().subIndex[absolute_];
    }

    function toSubIndex(uint256 index_) private pure returns (uint32) {
        if (index_ > type(uint32).max) revert ILedger.TooManySubAccounts(index_);
        // Safe because the explicit guard above bounds index_ to uint32.
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint32(index_);
    }

    //==================================================================
    //                        Balance & Valuation
    //==================================================================
    function debitBalanceOf(address absolute_) internal view returns (uint256) {
        return store().debits[absolute_];
    }

    function creditBalanceOf(address absolute_) internal view returns (uint256) {
        return store().credits[absolute_];
    }

    function balanceOf(address absolute_, bool isCredit_) internal view returns (uint256 _balance) {
        if (isCredit_) {
            return creditBalanceOf(absolute_) - debitBalanceOf(absolute_);
        }
        return debitBalanceOf(absolute_) - creditBalanceOf(absolute_);
    }

    function totalSupply(address root_) internal view returns (uint256 _supply) {
        return debitBalanceOf(root_);
    }

    //==================================================================
    //                         TreeView Manipulation
    //==================================================================

    function addSubAccountGroup(address root_, address holderParent_, string memory name_, bool isCredit_)
        internal
        returns (address _holder, uint256 _flags)
    {
        return addSubAccountGroup(root_, holderParent_, toAddress(name_), name_, isCredit_);
    }

    function addSubAccountGroup(
        address root_,
        address holderParent_,
        address relative_,
        string memory name_,
        bool isCredit_
    ) internal returns (address _holder, uint256 _flags) {
        address _absoluteParent = holderParent_ == root_ ? root_ : toAddress(root_, holderParent_);
        uint256 _parentFlags = flags(_absoluteParent);
        if (!isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
        checkString(name_);

        _holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        address _absolute = toAddress(root_, holderParent_, relative_);
        _flags = flags(
            holderParent_,
            isCredit_ ? AccountKind.CreditGroup : AccountKind.DebitGroup,
            TokenKind.Unregistered,
            depth(_parentFlags) + 1
        );
        uint256 _existingFlags = flags(_absolute);
        if (!isUnregisteredAccount(_existingFlags)) {
            if (_flags == _existingFlags && keccak256(bytes(name(_absolute))) == keccak256(bytes(name_))) {
                // SubAccount already exists with the same name and same flags
                return (_holder, _flags);
            } else {
                // SubAccount already exists with the same name but different flags
                revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
            }
        }
        if (debitBalanceOf(_absolute) > 0 || creditBalanceOf(_absolute) > 0) {
            revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
        }

        address _root = root(_absoluteParent);
        if (_root != root_) revert ILedger.DifferentRoots(root_, _absoluteParent);

        Store storage s = store();
        s.name[_absolute] = name_;
        s.root[_absolute] = _root;
        s.subs[_absoluteParent].push(relative_);
        s.subIndex[_absolute] = toSubIndex(s.subs[_absoluteParent].length);
        s.flags[_absolute] = _flags;
        emit ILedger.SubAccountGroupAdded(_root, holderParent_, name_, isCredit_);
    }

    function addSubAccount(address root_, address holderParent_, string memory name_, bool isCredit_)
        internal
        returns (address _holder, uint256 _flags)
    {
        return addSubAccount(root_, holderParent_, toAddress(name_), name_, isCredit_);
    }

    function addSubAccount(address root_, address holderParent_, address relative_, string memory name_, bool isCredit_)
        internal
        returns (address _holder, uint256 _flags)
    {
        address _absoluteParent = holderParent_ == root_ ? root_ : toAddress(root_, holderParent_);
        uint256 _parentFlags = flags(_absoluteParent);
        if (!isGroup(_parentFlags)) {
            revert ILedger.InvalidAccountGroup();
        }

        _holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        address _absolute = toAddress(root_, holderParent_, relative_);
        _flags = flags(
            holderParent_,
            isCredit_ ? AccountKind.CreditLedger : AccountKind.DebitLedger,
            TokenKind.Unregistered,
            depth(_parentFlags) + 1
        );
        uint256 _existingFlags = flags(_absolute);
        if (!isUnregisteredAccount(_existingFlags)) {
            if (_flags == _existingFlags && keccak256(bytes(name(_absolute))) == keccak256(bytes(name_))) {
                // SubAccount already exists with the same name and same flags
                return (_holder, _flags);
            } else {
                // SubAccount already exists with the same name but different flags
                revert ILedger.InvalidSubAccount(relative_);
            }
        }
        if (
            (isCredit_ && debitBalanceOf(_absolute) > creditBalanceOf(_absolute))
                || (!isCredit_ && creditBalanceOf(_absolute) > debitBalanceOf(_absolute))
        ) {
            revert ILedger.InvalidSubAccount(relative_);
        }

        address _root = root(_absoluteParent);
        if (_root != root_) revert ILedger.DifferentRoots(root_, _absoluteParent);

        Store storage s = store();
        s.name[_absolute] = name_;
        s.root[_absolute] = _root;
        s.subs[_absoluteParent].push(relative_);
        s.subIndex[_absolute] = toSubIndex(s.subs[_absoluteParent].length);
        s.flags[_absolute] = _flags;
        emit ILedger.SubAccountAdded(_root, holderParent_, relative_, isCredit_);
    }

    function addLedger(
        address root_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        TokenKind tokenKind_,
        address packedAddress_
    ) internal returns (uint256 _flags) {
        if (isZeroAddress(root_) || !isValidString(name_) || !isValidString(symbol_)) {
            revert ILedger.InvalidToken(root_, name_, symbol_, decimals_);
        }

        _flags = flags(packedAddress_, AccountKind.DebitGroup, tokenKind_, 1);

        Store storage s = store();
        // Check if token already exists
        if (s.root[root_] == root_) {
            // Token already exists
            bool _sameName = keccak256(bytes(name_)) == keccak256(bytes(name(root_)));
            bool _sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(symbol(root_)));
            bool _sameDec = decimals(root_) == decimals_;
            bool _sameFlags = _flags == flags(root_);
            if (_sameName && _sameSymbol && _sameDec && _sameFlags) {
                // No changes needed
                return _flags;
            }
            revert ILedger.InvalidToken(root_, name_, symbol_, decimals_);
        }
        s.name[root_] = name_;
        s.symbol[root_] = symbol_;
        s.decimals[root_] = decimals_;
        s.root[root_] = root_;
        s.flags[root_] = _flags;
        s.roots.push(root_);
        s.rootIndex[root_] = s.roots.length;

        addSubAccount(root_, root_, SOURCE_ADDRESS, SOURCE_NAME, true);
        emit ILedger.LedgerAdded(root_, name_, symbol_, decimals_);
    }

    function setNativeMetadata(string memory name_, string memory symbol_, uint8 decimals_) internal {
        Store storage s = store();
        s.nativeName = name_;
        s.nativeSymbol = symbol_;
        s.nativeDecimals = decimals_;
    }

    function nativeName() internal view returns (string memory) {
        return store().nativeName;
    }

    function nativeSymbol() internal view returns (string memory) {
        return store().nativeSymbol;
    }

    function nativeDecimals() internal view returns (uint8) {
        return store().nativeDecimals;
    }

    function addNativeToken() internal returns (uint256 _flags) {
        return addLedger(
            LedgerLib.NATIVE_ADDRESS, nativeName(), nativeSymbol(), nativeDecimals(), TokenKind.Native, address(0)
        );
    }

    function addExternalToken(address token_) internal returns (uint256 _flags) {
        // External roots intentionally require ERC20 metadata compliance at registration.
        IERC20Metadata _meta = IERC20Metadata(token_);
        string memory _name = _meta.name();
        string memory _symbol = _meta.symbol();
        uint8 _decimals = _meta.decimals();
        if (!isValidString(_name) || !isValidString(_symbol)) {
            revert ILedger.InvalidToken(token_, _name, _symbol, _decimals);
        }

        return addLedger(token_, _name, _symbol, _decimals, TokenKind.External, address(0));
    }

    function removeSubAccountGroup(address root_, address holderParent_, string memory name_)
        internal
        returns (address)
    {
        return removeSubAccountGroup(root_, holderParent_, toAddress(name_));
    }

    function removeSubAccountGroup(address root_, address holderParent_, address relative_)
        internal
        returns (address _holder)
    {
        address _absoluteParent = holderParent_ == root_ ? root_ : toAddress(root_, holderParent_);
        uint256 _parentFlags = flags(_absoluteParent);
        if (!isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();

        _holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        address _absolute = toAddress(root_, holderParent_, relative_);
        uint256 _flags = flags(_absolute);

        // Must exist and belong to this parent
        if (isUnregisteredAccount(_flags)) return _holder;
        if (holderParent(_flags) != holderParent_) revert ILedger.SubAccountGroupNotFound(relative_);
        if (!isGroup(_flags)) revert ILedger.InvalidAccountGroup();

        if (hasSubAccount(_absolute)) revert ILedger.HasSubAccount(_absolute);
        if (debitBalanceOf(_absolute) > 0 || creditBalanceOf(_absolute) > 0) revert ILedger.HasBalance(_absolute);

        Store storage s = store();

        uint256 _index = s.subIndex[_absolute]; // 1-based
        uint256 _lastIndex = s.subs[_absoluteParent].length; // 1-based
        address _lastChild = s.subs[_absoluteParent][_lastIndex - 1];
        address _lastChildAbsolute = toAddress(root_, holderParent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[_absoluteParent][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = toSubIndex(_index);
        }
        s.subs[_absoluteParent].pop();

        s.name[_absolute] = "";
        s.root[_absolute] = address(0);
        s.subIndex[_absolute] = 0;
        s.flags[_absolute] = 0;

        address _root = root(_absoluteParent);
        if (_root != root_) revert ILedger.DifferentRoots(root_, _absoluteParent);
        emit ILedger.SubAccountGroupRemoved(_root, holderParent_, relative_);
    }

    function removeSubAccount(address root_, address holderParent_, string memory name_) internal returns (address) {
        return removeSubAccount(root_, holderParent_, toAddress(name_));
    }

    function removeSubAccount(address root_, address holderParent_, address relative_)
        internal
        returns (address _holder)
    {
        address _absoluteParent = holderParent_ == root_ ? root_ : toAddress(root_, holderParent_);
        uint256 _parentFlags = flags(_absoluteParent);
        if (!isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();

        _holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        address _absolute = toAddress(root_, holderParent_, relative_);
        uint256 _flags = flags(_absolute);

        // Must exist and belong to this parent
        if (isUnregisteredAccount(_flags)) return _holder;
        if (holderParent(_flags) != holderParent_) revert ILedger.SubAccountNotFound(relative_);
        if (isGroup(_flags)) revert ILedger.InvalidLedgerAccount(_absolute);

        if (hasSubAccount(_absolute)) revert ILedger.HasSubAccount(relative_);
        if (debitBalanceOf(_absolute) > 0 || creditBalanceOf(_absolute) > 0) revert ILedger.HasBalance(relative_);

        Store storage s = store();

        uint256 _index = s.subIndex[_absolute]; // 1-based
        uint256 _lastIndex = s.subs[_absoluteParent].length; // 1-based
        address _lastChild = s.subs[_absoluteParent][_lastIndex - 1];
        address _lastChildAbsolute = toAddress(root_, holderParent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[_absoluteParent][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = toSubIndex(_index);
        }
        s.subs[_absoluteParent].pop();

        s.name[_absolute] = "";
        s.root[_absolute] = address(0);
        s.subIndex[_absolute] = 0;
        s.flags[_absolute] = 0;

        address _root = root(_absoluteParent);
        if (_root != root_) revert ILedger.DifferentRoots(root_, _absoluteParent);
        emit ILedger.SubAccountRemoved(_root, holderParent_, relative_);
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function _update(
        AccountCache memory acct_,
        address root_,
        mapping(address => uint256) storage balances_,
        uint256 amount_,
        bool isIncreased_
    ) internal returns (uint256 _balance) {
        _balance = balances_[acct_.absolute];
        if (isIncreased_) {
            _balance += amount_;
            balances_[acct_.absolute] = _balance;
        } else {
            if (_balance < amount_) {
                revert ILedger.InsufficientBalance(root_, holderParent(acct_.flags), acct_.absolute, amount_);
            }
            _balance -= amount_;
            balances_[acct_.absolute] = _balance;
        }
    }

    struct AccountCache {
        uint256 balance;
        address holder;
        address relative;
        address absolute;
        uint256 flags;
        uint8 depth;
        bool isUnregistered;
    }

    function setAccountCache(address root_, address holderParent_, address relative_)
        private
        view
        returns (AccountCache memory _acct)
    {
        uint256 _originalFlags;
        _acct.holder = holderParent_ == root_ ? relative_ : toAddress(holderParent_, relative_);
        _acct.relative = relative_;
        (_acct.flags, _originalFlags, _acct.absolute) = effectiveFlags(root_, holderParent_, relative_);
        _acct.depth = depth(_acct.flags);
        _acct.isUnregistered = isUnregisteredAccount(_originalFlags);
    }

    function emitWrapperTransfer(
        address root_,
        AccountCache memory from_,
        bool fromIsCredit_,
        AccountCache memory to_,
        bool toIsCredit_,
        uint256 amount_
    ) private {
        ERC20Wrapper(root_)
            .emitTransfer(fromIsCredit_ ? address(0) : from_.holder, toIsCredit_ ? address(0) : to_.holder, amount_);
    }

    function enforceTransfer(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_
    ) internal view returns (address _root, bool _fromIsCredit, bool _toIsCredit) {
        if (root_ == address(0)) revert ILedger.ZeroAddress();
        address _fromAbsoluteParent = fromHolderParent_ == root_ ? root_ : toAddress(root_, fromHolderParent_);
        address _toAbsoluteParent = toHolderParent_ == root_ ? root_ : toAddress(root_, toHolderParent_);
        _root = checkRoots(_fromAbsoluteParent, _toAbsoluteParent);
        if (_root != root_) revert ILedger.DifferentRoots(root_, _root);

        (uint256 _fromFlags,, address _fromAbsolute) = effectiveFlags(root_, fromHolderParent_, from_);
        (uint256 _toFlags,, address _toAbsolute) = effectiveFlags(root_, toHolderParent_, to_);

        if (isGroup(_fromFlags)) revert ILedger.InvalidLedgerAccount(_fromAbsolute);
        if (isGroup(_toFlags)) revert ILedger.InvalidLedgerAccount(_toAbsolute);
        if (depth(_fromFlags) == 0) revert ILedger.ZeroDepth();
        if (depth(_toFlags) == 0) revert ILedger.ZeroDepth();

        _fromIsCredit = isCredit(_fromFlags);
        _toIsCredit = isCredit(_toFlags);
    }

    function transfer(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        uint256 amount_
    ) internal returns (address _root, bool _fromIsCredit, bool _toIsCredit) {
        (_root, _fromIsCredit, _toIsCredit) = enforceTransfer(root_, fromHolderParent_, from_, toHolderParent_, to_);

        AccountCache memory _from = setAccountCache(root_, fromHolderParent_, from_);
        AccountCache memory _to = setAccountCache(root_, toHolderParent_, to_);
        // Emit before same-account no-op so ERC20 self-transfers still produce Transfer(from, from, amount).
        if (_root == wrapper(_root)) {
            emitWrapperTransfer(_root, _from, _fromIsCredit, _to, _toIsCredit, amount_);
        }
        if (_from.absolute == _to.absolute) {
            return (_root, _fromIsCredit, _toIsCredit);
        }

        bool _isSameSide = _fromIsCredit == _toIsCredit;

        Store storage s = store();
        uint8 _depth = _from.depth > _to.depth ? _from.depth : _to.depth;
        while (_depth > 0) {
            // if (_current != _root && !isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
            if (_from.depth >= _depth) {
                _from.balance = _update(_from, _root, _fromIsCredit ? s.credits : s.debits, amount_, _fromIsCredit);
                emit ILedger.Credit(_root, _from.absolute, amount_, _from.balance);
                if (_depth > 1) {
                    address _holderParent = holderParent(_from.flags);
                    _from.absolute = _holderParent == _root ? _root : toAddress(_root, _holderParent);
                    _from.flags = flags(_from.absolute);
                }
            }
            if (_to.depth >= _depth) {
                _to.balance = _update(_to, _root, _toIsCredit ? s.credits : s.debits, amount_, !_toIsCredit);
                emit ILedger.Debit(_root, _to.absolute, amount_, _to.balance);
                if (_depth > 1) {
                    address _holderParent = holderParent(_to.flags);
                    _to.absolute = _holderParent == _root ? _root : toAddress(_root, _holderParent);
                    _to.flags = flags(_to.absolute);
                }
            }
            // Once both walks reach the same ancestor on the same side, remaining upward mutations are identical,
            // so no further net balance changes occur above this point. Depth 1 is the root completion case.
            if (_depth == 1 || (_from.absolute == _to.absolute && _isSameSide)) {
                return (_root, _fromIsCredit, _toIsCredit);
            }
            _depth--;
        }
        revert ILedger.ZeroDepth();
    }

    struct WrapCache {
        uint256 rootFlags;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 received;
    }

    function wrap(
        address payer_,
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        uint256 amount_
    ) internal returns (address, bool _fromIsCredit, bool _toIsCredit) {
        WrapCache memory c;
        c.rootFlags = flags(root_);
        // Wrap only applies to external/native debit roots with real asset custody.
        if (isCredit(c.rootFlags) || (!isExternal(c.rootFlags) && !isNative(c.rootFlags))) {
            revert ILedger.InvalidLedgerAccount(root_);
        }
        (, _fromIsCredit, _toIsCredit) = transfer(root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
        // Debit-root wrap must move value from credit source into debit holder balance.
        if (!_fromIsCredit) revert ILedger.InvalidSubAccount(from_);
        if (_toIsCredit) revert ILedger.InvalidSubAccount(to_);
        if (root_ == NATIVE_ADDRESS) {
            if (payer_ != msg.sender) revert ILedger.InvalidNativePayer(payer_, msg.sender);
            if (msg.value != amount_) {
                revert ILedger.IncorrectAmount(msg.value, amount_);
            }
            // Native value already sits on the dispatcher (this contract via delegatecall),
            // so no external transfer is needed.
        } else {
            c.balanceBefore = IERC20(root_).balanceOf(address(this));
            SafeERC20.safeTransferFrom(IERC20(root_), payer_, address(this), amount_);
            c.balanceAfter = IERC20(root_).balanceOf(address(this));
            c.received = c.balanceAfter > c.balanceBefore ? c.balanceAfter - c.balanceBefore : 0;
            if (c.received != amount_) revert ILedger.UnsupportedTokenBehavior(root_, amount_, c.received);
        }
        return (root_, _fromIsCredit, _toIsCredit);
    }

    struct UnwrapCache {
        uint256 rootFlags;
        uint256 liabilities;
        uint256 collateral;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 received;
    }

    function unwrap(
        address recipient_,
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        uint256 amount_
    ) internal returns (address, bool _fromIsCredit, bool _toIsCredit) {
        UnwrapCache memory c;
        c.rootFlags = flags(root_);
        // Unwrap only applies to external/native debit roots with real asset custody.
        if (isCredit(c.rootFlags) || (!isExternal(c.rootFlags) && !isNative(c.rootFlags))) {
            revert ILedger.InvalidLedgerAccount(root_);
        }
        c.liabilities = totalSupply(root_);
        c.collateral = root_ == NATIVE_ADDRESS ? address(this).balance : IERC20(root_).balanceOf(address(this));
        if (c.collateral < c.liabilities) {
            revert ILedger.UndercollateralizedToken(root_, c.liabilities, c.collateral);
        }

        (, _fromIsCredit, _toIsCredit) = transfer(root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
        // Debit-root unwrap burns from debit holder balance back into credit source.
        if (_fromIsCredit) revert ILedger.InvalidSubAccount(from_);
        if (!_toIsCredit) revert ILedger.InvalidSubAccount(to_);
        if (root_ == NATIVE_ADDRESS) {
            (bool _success,) = payable(recipient_).call{value: amount_}("");
            if (!_success) revert ILedger.NativeTransferFailed();
        } else {
            c.balanceBefore = IERC20(root_).balanceOf(recipient_);
            SafeERC20.safeTransfer(IERC20(root_), recipient_, amount_);
            c.balanceAfter = IERC20(root_).balanceOf(recipient_);
            c.received = c.balanceAfter > c.balanceBefore ? c.balanceAfter - c.balanceBefore : 0;
            if (c.received != amount_) revert ILedger.UnsupportedTokenBehavior(root_, amount_, c.received);
        }
        return (root_, _fromIsCredit, _toIsCredit);
    }
}
