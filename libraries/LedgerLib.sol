// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger, ERC20Wrapper} from "../modules/Ledger.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
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

    function flags(address addr_) internal view returns (uint256) {
        return store().flags[addr_];
    }

    function accountKind(uint256 flags_) internal pure returns (AccountKind) {
        return AccountKind((flags_ & ACCOUNT_KIND_MASK) >> ACCOUNT_KIND_SHIFT);
    }

    function tokenKind(uint256 flags_) internal pure returns (TokenKind) {
        return TokenKind((flags_ & TOKEN_KIND_MASK) >> TOKEN_KIND_SHIFT);
    }

    function packedAddress(uint256 flags_) internal pure returns (address) {
        return address(uint160(flags_ >> PACK_ADDR_SHIFT));
    }

    function parent(uint256 flags_) internal pure returns (address) {
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

    function effectiveFlags(address parent_, address addr_) internal view returns (address _current, uint256 _flags) {
        _current = toAddress(parent_, addr_);
        _flags = flags(_current);
        if (!isUnregisteredAccount(_flags)) return (_current, _flags);
        if (_flags != 0) revert ILedger.InvalidAddress(addr_);

        // Unregistered derived leaves inherit polarity and depth from their parent.
        uint256 _parentFlags = flags(parent_);
        _flags = flags(
            parent_,
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

    function claimAccount(address token_) internal view returns (address) {
        return claimAccount(flags(token_));
    }

    function checkClaimAccount(address token_, address parent_, address addr_)
        internal
        view
        returns (address _claimAccount)
    {
        _claimAccount = toAddress(parent_, addr_);
        if (!isLedger(flags(_claimAccount))) revert ILedger.InvalidLedgerAccount(_claimAccount);
        address _claimedRoot = root(_claimAccount);
        if (_claimedRoot == token_ || isClaim(flags(_claimedRoot))) revert ILedger.InvalidLedgerAccount(_claimAccount);
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
    function debitBalanceOf(address addr_) internal view returns (uint256) {
        return store().debits[addr_];
    }

    function creditBalanceOf(address addr_) internal view returns (uint256) {
        return store().credits[addr_];
    }

    function balanceOf(address addr_, bool isCredit_) internal view returns (uint256 _balance) {
        if (isCredit_) {
            return creditBalanceOf(addr_) - debitBalanceOf(addr_);
        }
        return debitBalanceOf(addr_) - creditBalanceOf(addr_);
    }

    function totalSupply(address token_) internal view returns (uint256 _supply) {
        return debitBalanceOf(token_);
    }

    //==================================================================
    //                         Tree Manipulation
    //==================================================================

    function addSubAccountGroup(address parent_, string memory name_, bool isCredit_)
        internal
        returns (address _addr, uint256 _flags)
    {
        return addSubAccountGroup(parent_, toAddress(name_), name_, isCredit_);
    }

    function addSubAccountGroup(address parent_, address addr_, string memory name_, bool isCredit_)
        internal
        returns (address _addr, uint256 _flags)
    {
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        checkString(name_);

        _addr = toAddress(parent_, addr_);
        _flags = flags(
            parent_,
            isCredit_ ? AccountKind.CreditGroup : AccountKind.DebitGroup,
            TokenKind.Unregistered,
            depth(flags(parent_)) + 1
        );
        uint256 _existingFlags = flags(_addr);
        if (!isUnregisteredAccount(_existingFlags)) {
            if (_flags == _existingFlags && keccak256(bytes(name(_addr))) == keccak256(bytes(name_))) {
                // SubAccount already exists with the same name and same flags
                return (_addr, _flags);
            } else {
                // SubAccount already exists with the same name but different flags
                revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
            }
        }
        if (debitBalanceOf(_addr) > 0 || creditBalanceOf(_addr) > 0) {
            revert ILedger.InvalidSubAccountGroup(name_, isCredit_);
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_addr] = name_;
        s.root[_addr] = _root;
        s.subs[parent_].push(addr_);
        s.subIndex[_addr] = uint32(s.subs[parent_].length);
        s.flags[_addr] = _flags;
        emit ILedger.SubAccountGroupAdded(_root, parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, string memory name_, bool isCredit_)
        internal
        returns (address _addr, uint256 _flags)
    {
        return addSubAccount(parent_, toAddress(name_), name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        internal
        returns (address _addr, uint256 _flags)
    {
        if (!isGroup(flags(parent_))) {
            revert ILedger.InvalidAccountGroup();
        }

        _addr = toAddress(parent_, addr_);
        _flags = flags(
            parent_,
            isCredit_ ? AccountKind.CreditLedger : AccountKind.DebitLedger,
            TokenKind.Unregistered,
            depth(flags(parent_)) + 1
        );
        uint256 _existingFlags = flags(_addr);
        if (!isUnregisteredAccount(_existingFlags)) {
            if (_flags == _existingFlags && keccak256(bytes(name(_addr))) == keccak256(bytes(name_))) {
                // SubAccount already exists with the same name and same flags
                return (_addr, _flags);
            } else {
                // SubAccount already exists with the same name but different flags
                revert ILedger.InvalidSubAccount(addr_);
            }
        }
        if (
            (isCredit_ && debitBalanceOf(_addr) > creditBalanceOf(_addr))
                || (!isCredit_ && creditBalanceOf(_addr) > debitBalanceOf(_addr))
        ) {
            revert ILedger.InvalidSubAccount(addr_);
        }

        address _root = root(parent_);

        Store storage s = store();
        s.name[_addr] = name_;
        s.root[_addr] = _root;
        s.subs[parent_].push(addr_);
        s.subIndex[_addr] = uint32(s.subs[parent_].length);
        s.flags[_addr] = _flags;
        emit ILedger.SubAccountAdded(_root, parent_, addr_, isCredit_);
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

        addSubAccount(root_, address(0), "Zero Address", true);
        emit ILedger.LedgerAdded(root_, name_, symbol_, decimals_);
    }

    function addNativeToken() internal returns (uint256 _flags) {
        return addLedger(
            LedgerLib.NATIVE_ADDRESS,
            ILedger(address(this)).nativeName(),
            ILedger(address(this)).nativeSymbol(),
            ILedger(address(this)).nativeDecimals(),
            TokenKind.Native,
            address(0)
        );
    }

    function addExternalToken(address token_) internal returns (uint256 _flags) {
        IERC20Metadata _meta = IERC20Metadata(token_);
        string memory _name = _meta.name();
        string memory _symbol = _meta.symbol();
        uint8 _decimals = _meta.decimals();
        if (!isValidString(_name) || !isValidString(_symbol)) {
            revert ILedger.InvalidToken(token_, _name, _symbol, _decimals);
        }

        return addLedger(token_, _name, _symbol, _decimals, TokenKind.External, address(0));
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_)
        internal
        returns (address _token, uint256 _flags)
    {
        if (!isValidString(name_) || !isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }

        bytes32 _salt = keccak256(abi.encode(name_, symbol_, decimals_));
        bytes memory _creationCode = abi.encodePacked(
            type(ERC20Wrapper).creationCode, abi.encode(address(this), address(0), name_, symbol_, decimals_, false)
        );
        _token = Create2.computeAddress(_salt, keccak256(_creationCode));

        if (root(_token) == _token) {
            _flags = flags(address(0), AccountKind.DebitGroup, TokenKind.Internal, 1);
            bool _sameFlags = _flags == flags(_token);
            bool _sameWrapper = wrapper(_token) == _token;
            if (_sameFlags && _sameWrapper) return (_token, _flags);
            revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);

        // Internal roots remain self-wrapped so the root address is immediately usable as an ERC20 surface.
        _token = address(new ERC20Wrapper{salt: _salt}(address(this), address(0), name_, symbol_, decimals_, false));
        _flags = addLedger(_token, name_, symbol_, decimals_, TokenKind.Internal, address(0));

        Store storage s = store();
        s.wrapper[_token] = _token;
    }

    function addClaimToken(address token_, address parent_, address addr_) internal returns (uint256 _flags) {
        address _claimAccount = checkClaimAccount(token_, parent_, addr_);

        IERC20Metadata _meta = IERC20Metadata(token_);
        string memory _name = _meta.name();
        string memory _symbol = _meta.symbol();
        uint8 _decimals = _meta.decimals();
        if (!isValidString(_name) || !isValidString(_symbol)) {
            revert ILedger.InvalidToken(token_, _name, _symbol, _decimals);
        }

        return addLedger(token_, _name, _symbol, _decimals, TokenKind.Claim, _claimAccount);
    }

    function createClaimToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address parent_,
        address addr_
    ) internal returns (address _token, uint256 _flags) {
        if (!isValidString(name_) || !isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }
        address _claimAccount = checkClaimAccount(address(0), parent_, addr_);

        bytes32 _salt = keccak256(abi.encode(name_, symbol_, decimals_, _claimAccount));
        _token = Create2.computeAddress(
            _salt,
            keccak256(
                abi.encodePacked(
                    type(ERC20Wrapper).creationCode,
                    abi.encode(address(this), address(0), name_, symbol_, decimals_, false)
                )
            )
        );

        if (root(_token) == _token) {
            _flags = flags(_claimAccount, AccountKind.DebitGroup, TokenKind.Claim, 1);
            if (_flags == flags(_token) && wrapper(_token) == _token) return (_token, _flags);
            revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);

        _token = address(new ERC20Wrapper{salt: _salt}(address(this), address(0), name_, symbol_, decimals_, false));
        if (root(_claimAccount) == _token) revert ILedger.InvalidLedgerAccount(_claimAccount);
        _flags = addLedger(_token, name_, symbol_, decimals_, TokenKind.Claim, _claimAccount);

        Store storage s = store();
        s.wrapper[_token] = _token;
    }

    function removeSubAccountGroup(address parent_, string memory name_) internal returns (address) {
        return removeSubAccountGroup(parent_, toAddress(name_));
    }

    function removeSubAccountGroup(address parent_, address addr_) internal returns (address _addr) {
        _addr = toAddress(parent_, addr_);
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        uint256 _flags = flags(_addr);

        // Must exist and belong to this parent
        if (isUnregisteredAccount(_flags)) return _addr;
        if (parent(_flags) != parent_) revert ILedger.SubAccountGroupNotFound(addr_);
        if (!isGroup(_flags)) revert ILedger.InvalidAccountGroup();

        if (hasSubAccount(_addr)) revert ILedger.HasSubAccount(_addr);
        if (debitBalanceOf(_addr) > 0 || creditBalanceOf(_addr) > 0) revert ILedger.HasBalance(_addr);

        Store storage s = store();

        uint256 _index = s.subIndex[_addr]; // 1-based
        uint256 _lastIndex = s.subs[parent_].length; // 1-based
        address _lastChild = s.subs[parent_][_lastIndex - 1];
        address _lastChildAbsolute = toAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_addr] = "";
        s.root[_addr] = address(0);
        s.subIndex[_addr] = 0;
        s.flags[_addr] = 0;

        address _root = root(parent_);
        emit ILedger.SubAccountGroupRemoved(_root, parent_, addr_);
    }

    function removeSubAccount(address parent_, string memory name_) internal returns (address) {
        return removeSubAccount(parent_, toAddress(name_));
    }

    function removeSubAccount(address parent_, address addr_) internal returns (address) {
        address _addr = toAddress(parent_, addr_);
        if (!isGroup(flags(parent_))) revert ILedger.InvalidAccountGroup();
        uint256 _flags = flags(_addr);

        // Must exist and belong to this parent
        if (isUnregisteredAccount(_flags)) return _addr;
        if (parent(_flags) != parent_) revert ILedger.SubAccountNotFound(addr_);
        if (isGroup(_flags)) revert ILedger.InvalidLedgerAccount(_addr);

        if (hasSubAccount(_addr)) revert ILedger.HasSubAccount(addr_);
        if (debitBalanceOf(_addr) > 0 || creditBalanceOf(_addr) > 0) revert ILedger.HasBalance(addr_);

        Store storage s = store();

        uint256 _index = s.subIndex[_addr]; // 1-based
        uint256 _lastIndex = s.subs[parent_].length; // 1-based
        address _lastChild = s.subs[parent_][_lastIndex - 1];
        address _lastChildAbsolute = toAddress(parent_, _lastChild);
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChildAbsolute] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.name[_addr] = "";
        s.root[_addr] = address(0);
        s.subIndex[_addr] = 0;
        s.flags[_addr] = 0;

        address _root = root(parent_);
        emit ILedger.SubAccountRemoved(_root, parent_, addr_);

        return _addr;
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
        uint8 depth;
        bool isCredit;
        address eventAddr;
    }

    function setAccountCache(address parent_, address addr_) private view returns (AccountCache memory _acct) {
        (_acct.current, _acct.flags) = effectiveFlags(parent_, addr_);
        _acct.depth = depth(_acct.flags);
        _acct.isCredit = isCredit(_acct.flags);
        _acct.eventAddr = _acct.depth == 2 ? addr_ : _acct.current;
    }

    function emitTransfer(address root_, AccountCache memory from_, AccountCache memory to_, uint256 amount_) private {
        if (root_ == wrapper(root_) && (from_.depth == 2 || to_.depth == 2)) {
            ERC20Wrapper(root_).emitTransfer(from_.eventAddr, to_.eventAddr, amount_);
        } else {
            emit ILedger.Transfer(from_.eventAddr, to_.eventAddr, amount_);
        }
    }

    function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        internal
        returns (address _root, bool _fromIsCredit, bool _toIsCredit)
    {
        _root = checkRoots(fromParent_, toParent_);
        if (_root == address(0)) revert ILedger.ZeroAddress();

        AccountCache memory _from = setAccountCache(fromParent_, from_);
        AccountCache memory _to = setAccountCache(toParent_, to_);
        emitTransfer(_root, _from, _to, amount_);
        if (_from.current == _to.current) {
            return (_root, _from.isCredit, _to.isCredit);
        }

        bool _isSameSide = _from.isCredit == _to.isCredit;

        // Ensure current accounts are ledger accounts (not groups)
        if (isGroup(_from.flags)) revert ILedger.InvalidLedgerAccount(_from.current);
        if (isGroup(_to.flags)) revert ILedger.InvalidLedgerAccount(_to.current);

        // Ensure roots are valid before starting the walk.
        if (_from.depth == 0) revert ILedger.ZeroDepth();
        if (_to.depth == 0) revert ILedger.ZeroDepth();

        Store storage s = store();
        uint8 _depth = _from.depth > _to.depth ? _from.depth : _to.depth;
        while (_depth > 0) {
            // if (_current != _root && !isGroup(_parentFlags)) revert ILedger.InvalidAccountGroup();
            if (_from.depth >= _depth) {
                _from.balance = _update(
                    _from, _root, _from.isCredit ? s.credits : s.debits, amount_, _from.isCredit
                );
                if (_depth > 1) {
                    _from.current = parent(_from.flags);
                    _from.flags = flags(_from.current);
                }
            }
            if (_to.depth >= _depth) {
                _to.balance =
                    _update(_to, _root, _to.isCredit ? s.credits : s.debits, amount_, !_to.isCredit);
                if (_depth > 1) {
                    _to.current = parent(_to.flags);
                    _to.flags = flags(_to.current);
                }
            }
            // Once both walks reach the same ancestor on the same side, remaining upward mutations are identical,
            // so no further net balance changes occur above this point. Depth 1 is the root completion case.
            if (_depth == 1 || (_from.current == _to.current && _isSameSide)) {
                return (_root, _from.isCredit, _to.isCredit);
            }
            _depth--;
        }
        revert ILedger.ZeroDepth();
    }

    function wrap(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        internal
        returns (address _token, bool _fromIsCredit, bool _toIsCredit)
    {
        _token = root(fromParent_);
        uint256 _tokenFlags = flags(_token);
        // Wrap only applies to external/native debit roots with real asset custody.
        if (isCredit(_tokenFlags) || (!isExternal(_tokenFlags) && !isNative(_tokenFlags))) {
            revert ILedger.InvalidLedgerAccount(_token);
        }
        (_token, _fromIsCredit, _toIsCredit) = transfer(fromParent_, from_, toParent_, to_, amount_);
        // Debit-root wrap must move value from credit source into debit holder balance.
        if (!_fromIsCredit) revert ILedger.InvalidSubAccount(from_);
        if (_toIsCredit) revert ILedger.InvalidSubAccount(to_);
        if (_token == NATIVE_ADDRESS) {
            if (msg.value != amount_) {
                revert ILedger.IncorrectAmount(msg.value, amount_);
            }
            // Native value already sits on the router (this contract via delegatecall),
            // so no external transfer is needed.
        } else {
            SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), amount_);
        }
    }

    function unwrap(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        internal
        returns (address _token, bool _fromIsCredit, bool _toIsCredit)
    {
        _token = root(fromParent_);
        uint256 _tokenFlags = flags(_token);
        // Unwrap only applies to external/native debit roots with real asset custody.
        if (isCredit(_tokenFlags) || (!isExternal(_tokenFlags) && !isNative(_tokenFlags))) {
            revert ILedger.InvalidLedgerAccount(_token);
        }
        (_token, _fromIsCredit, _toIsCredit) = transfer(fromParent_, from_, toParent_, to_, amount_);
        // Debit-root unwrap burns from debit holder balance back into credit source.
        if (_fromIsCredit) revert ILedger.InvalidSubAccount(from_);
        if (!_toIsCredit) revert ILedger.InvalidSubAccount(to_);
        if (_token == NATIVE_ADDRESS) {
            (bool _success,) = payable(msg.sender).call{value: amount_}("");
            if (!_success) revert ILedger.NativeTransferFailed();
        } else {
            SafeERC20.safeTransfer(IERC20(_token), msg.sender, amount_);
        }
    }

}
