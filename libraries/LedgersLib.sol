// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ILedgers} from "../interfaces/ILedgers.sol";

contract ERC20Wrapper {
    address private immutable _ledgers;
    string private _name;
    string private _symbol;
    uint8 public immutable _decimals;

    constructor(address ledgers_, string memory name_, string memory symbol_, uint8 decimals_) {
        _ledgers = ledgers_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return ILedgers(_ledgers).name(address(this));
    }

    function symbol() public view returns (string memory) {
        return ILedgers(_ledgers).symbol(address(this));
    }

    function decimals() public view returns (uint8) {
        return ILedgers(_ledgers).decimals(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return ILedgers(_ledgers).totalSupply(address(this));
    }

    function balanceOf(address account_) public view returns (uint256) {
        return ILedgers(_ledgers).balanceOf(address(this), account_);
    }

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return ILedgers(_ledgers).allowance(address(this), owner_, address(this), spender_);
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        bool ok = ILedgers(_ledgers).approveWrapper(address(this), msg.sender, spender_, amount_);
        if (ok) emit Approval(msg.sender, spender_, amount_);
        return ok;
    }

    function transfer(address to_, uint256 amount_) public returns (bool) {
        bool ok = ILedgers(_ledgers).transferWrapper(address(this), msg.sender, to_, amount_);
        if (ok) emit Transfer(msg.sender, to_, amount_);
        return ok;
    }

    function mint(address to_, uint256 amount_) public returns (bool) {
        bool ok = ILedgers(_ledgers).mintWrapper(address(this), to_, amount_);
        if (ok) emit Transfer(address(0), to_, amount_);
        return ok;
    }

    function burn(address from_, uint256 amount_) public returns (bool) {
        bool ok = ILedgers(_ledgers).burnWrapper(address(this), from_, amount_);
        if (ok) emit Transfer(from_, address(0), amount_);
        return ok;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        bool ok = ILedgers(_ledgers).transferFromWrapper(address(this), msg.sender, from_, to_, amount_);
        if (ok) emit Transfer(from_, to_, amount_);
        return ok;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library LedgersLib {
    struct Store {
        mapping(address => bool) isGroup;
        mapping(address sub => address) parent;
        mapping(address sub => uint32) subIndex;
        mapping(address parent => address[]) subs;
        mapping(address => string) name;
        mapping(address => string) symbol;
        mapping(address => uint8) decimals;
        mapping(address => bool) isCredit;
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
    // toNamedAddress("Supply")
    address internal constant SUPPLY_ADDRESS = 0x486d9E1EFfBE2991Ba97401Be079767f9879e1Dd;

    //==================================================================
    //                            Validation
    //==================================================================
    function checkZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) revert ILedgers.ZeroAddress();
    }

    function isGroup(address addr_) internal view returns (bool) {
        return store().isGroup[addr_];
    }

    function isCredit(address addr_) internal view returns (bool) {
        return store().isCredit[addr_];
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
        return address(uint160(uint256(keccak256(abi.encodePacked(parent_, name_)))));
    }

    // Transfers can only occur within the same tree
    function checkRoots(address a_, address b_) internal view {
        if (a_ == b_) return;
        if (root(a_) != root(b_)) revert ILedgers.DifferentRoots(a_, b_);
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
        return store().symbol[root(addr_)];
    }

    function decimals(address addr_) internal view returns (uint8) {
        return store().decimals[root(addr_)];
    }

    function root(address addr_) internal view returns (address) {
        checkAccountGroup(addr_);

        Store storage s = store();
        uint256 _depth;
        address _parentAccount;
        while (_depth < MAX_DEPTH) {
            _depth++;
            _parentAccount = s.parent[addr_];
            if (_parentAccount == address(0)) {
                // Root found
                return addr_;
            }
            addr_ = _parentAccount;
        }
        revert ILedgers.MaxDepthExceeded();
    }

    function parent(address addr_) internal view returns (address) {
        return store().parent[addr_];
    }

    function subAccounts(address addr_) internal view returns (address[] memory) {
        return store().subs[addr_];
    }

    function hasSubAccount(address addr_) internal view returns (bool) {
        return store().subs[addr_].length > 0;
    }

    function subAccountIndex(address addr_) internal view returns (uint32) {
        return store().subIndex[addr_];
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

    function addSubAccount(address parent_, string memory name_, bool isGroup_, bool isCredit_)
        internal
        returns (address _sub)
    {
        if (!isGroup(parent_)) revert ILedgers.InvalidAccountGroup(parent_);
        if (!isValidString(name_)) revert ILedgers.InvalidSubAccount(name_, isGroup_, isCredit_);

        _sub = toGroupAddress(parent_, name_);

        bool _isExistingParent = parent(_sub) == parent_;
        bool _isExistingName = keccak256(bytes(name(_sub))) == keccak256(bytes(name_));
        if (_isExistingParent && _isExistingName) {
            if ((isCredit(_sub) == isCredit_) && (isGroup(_sub) == isGroup_)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert ILedgers.InvalidSubAccount(name_, isGroup_, isCredit_);
            }
        }

        Store storage s = store();
        s.isGroup[_sub] = isGroup_;
        s.name[_sub] = name_;
        s.parent[_sub] = parent_;
        s.subs[parent_].push(_sub);
        s.subIndex[_sub] = uint32(s.subs[parent_].length);
        s.isCredit[_sub] = isCredit_;
        address _root = root(parent_);
        emit ILedgers.SubAccountAdded(_root, parent_, name_, isGroup_, isCredit_);
    }

    function removeSubAccount(address parent_, string memory name_) internal returns (address) {
        address _sub = toGroupAddress(parent_, name_);
        if (!isGroup(parent_)) revert ILedgers.InvalidAccountGroup(parent_);
        if (!isGroup(_sub)) revert ILedgers.InvalidAccountGroup(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert ILedgers.SubAccountNotFound(name_);
        }

        if (hasSubAccount(_sub)) revert ILedgers.HasSubAccount(name_);
        if (hasBalance(_sub)) revert ILedgers.HasBalance(name_);

        Store storage s = store();

        uint256 _index = s.subIndex[_sub]; // 1-based
        uint256 _lastIndex = s.subs[parent_].length; // 1-based
        address _lastChild = s.subs[parent_][_lastIndex - 1];
        if (_index != _lastIndex) {
            s.subs[parent_][_index - 1] = _lastChild;
            s.subIndex[_lastChild] = uint32(_index);
        }
        s.subs[parent_].pop();

        s.subIndex[_sub] = 0;
        s.parent[_sub] = address(0);
        s.isGroup[_sub] = false;
        s.isCredit[_sub] = false;
        s.name[_sub] = "";

        address _root = root(parent_);
        emit ILedgers.SubAccountRemoved(_root, parent_, name_);

        return _sub;
    }

    function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) internal {
        if (!isValidString(name_) || !isValidString(symbol_) || decimals_ == 0) {
            revert ILedgers.InvalidToken(name_, symbol_, decimals_);
        }

        Store storage s = store();
        if (s.isGroup[token_] && s.parent[token_] == address(0)) {
            // Token already exists
            bool sameName = keccak256(bytes(name_)) == keccak256(bytes(name(token_)));
            bool sameSymbol = keccak256(bytes(symbol_)) == keccak256(bytes(symbol(token_)));
            bool sameDec = decimals(token_) == decimals_;
            if (sameName && sameSymbol && sameDec) {
                // No changes needed
                return;
            }
            revert ILedgers.InvalidToken(name_, symbol_, decimals_);
        }
        s.isGroup[token_] = true;
        s.name[token_] = name_;
        s.symbol[token_] = symbol_;
        s.decimals[token_] = decimals_;

        address _supply = toLedgerAddress(token_, SUPPLY_ADDRESS);
        s.name[_supply] = "Supply";
        s.isCredit[_supply] = true;

        if (token_ != address(this)) {
            addSubAccount(address(this), name_, false, false);
        }

        emit ILedgers.LedgerAdded(token_, name_, symbol_, decimals_);
    }

    function createToken(string memory name_, string memory symbol_, uint8 decimals_) external returns (address) {
        address token = address(new ERC20Wrapper(address(this), name_, symbol_, decimals_));
        addLedger(token, name_, symbol_, decimals_);
        return token;
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function debit(address parent_, address addr_, uint256 amount_, bool emitEvent_)
        internal
        returns (address _currentAccount)
    {
        checkAccountGroup(parent_);
        _currentAccount = toLedgerAddress(parent_, addr_);

        Store storage s = store();
        uint8 _depth;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (parent_ == address(0)) {
                // Root found
                return _currentAccount;
            }
            if (s.isCredit[_currentAccount]) {
                require(s.balance[_currentAccount] >= amount_, "Ledgers: Insufficient balance");
                s.balance[_currentAccount] -= amount_;
            } else {
                s.balance[_currentAccount] += amount_;
            }
            _currentAccount = parent_;
            parent_ = s.parent[parent_];
            _depth++;
        }
        if (emitEvent_) emit ILedgers.Debit(parent_, addr_, amount_);
        revert ILedgers.MaxDepthExceeded();
    }

    function credit(address parent_, address addr_, uint256 amount_, bool emitEvent_)
        internal
        returns (address _currentAccount)
    {
        checkAccountGroup(parent_);
        _currentAccount = toLedgerAddress(parent_, addr_);

        Store storage s = store();
        uint8 _depth;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (parent_ == address(0)) {
                // Root found
                return _currentAccount;
            }
            if (s.isCredit[_currentAccount]) {
                s.balance[_currentAccount] += amount_;
            } else {
                require(s.balance[_currentAccount] >= amount_, "Ledgers: Insufficient balance");
                s.balance[_currentAccount] -= amount_;
            }
            _currentAccount = parent_;
            parent_ = s.parent[parent_];
            _depth++;
        }
        if (emitEvent_) emit ILedgers.Credit(parent_, addr_, amount_);
        revert ILedgers.MaxDepthExceeded();
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
        transfer(_token, SUPPLY_ADDRESS, toParent_, to_, amount_, true);
        return true;
    }

    function burn(address fromParent_, address from_, uint256 amount_) internal returns (bool) {
        address _token = root(fromParent_);
        transfer(fromParent_, from_, _token, SUPPLY_ADDRESS, amount_, true);
        return true;
    }

    function approve(
        address ownerParent_,
        address owner_,
        address spenderParent_,
        address spender_,
        uint256 amount_,
        bool emitEvent_
    ) internal returns (bool) {
        checkRoots(ownerParent_, spenderParent_);
        address _owner = toLedgerAddress(ownerParent_, owner_);
        address _spender = toLedgerAddress(spenderParent_, spender_);

        store().allowances[_owner][_spender] = amount_;
        if (emitEvent_) emit ILedgers.InternalApproval(_owner, _spender, amount_);
        return true;
    }

    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        internal
        view
        returns (uint256)
    {
        address _ownerAddress = toLedgerAddress(ownerParent_, owner_);
        if (hasSubAccount(_ownerAddress)) {
            revert ILedgers.HasSubAccount(name(_ownerAddress));
        }
        address _spenderAddress = toLedgerAddress(spenderParent_, spender_);
        if (hasSubAccount(_spenderAddress)) {
            revert ILedgers.HasSubAccount(name(_spenderAddress));
        }
        return store().allowances[_ownerAddress][_spenderAddress];
    }

    function transferFrom(
        address fromParent_,
        address from_,
        address spenderParent_,
        address spender_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) internal returns (bool) {
        checkRoots(fromParent_, spenderParent_);
        checkRoots(spenderParent_, toParent_);
        Store storage s = store();

        address _ownerAddress = toLedgerAddress(fromParent_, from_);
        address _spenderAddress = toLedgerAddress(spenderParent_, spender_);
        s.allowances[_ownerAddress][_spenderAddress] -= amount_;

        return transfer(fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }
}
