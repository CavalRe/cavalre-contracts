// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "../Module.sol";
import {Initializable} from "../../utilities/Initializable.sol";

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

library Lib {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Credit(address indexed parent, address indexed ledger, uint256 value);
    event Debit(address indexed parent, address indexed ledger, uint256 value);
    event InternalApproval(address indexed owner, address indexed spender, uint256 value);
    event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
    event SubAccountAdded(address indexed root, address indexed parent, string subName, bool isGroup, bool isCredit);
    event SubAccountRemoved(address indexed root, address indexed parent, string subName);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Custom errors
    error DifferentRoots(address a, address b);
    error DuplicateSubAccount(address sub);
    error HasBalance(string subName);
    error HasSubAccount(string subName);
    error InsufficientBalance();
    error InvalidAddress(address absoluteAddress);
    error InvalidDecimals(uint8 decimals);
    error InvalidAccountGroup(address groupAddress);
    error InvalidLedgerAccount(address ledgerAddress);
    error InvalidSubAccount(string subName, bool isGroup, bool isCredit);
    error InvalidString(string symbol);
    error InvalidToken(string name, string symbol, uint8 decimals);
    error MaxDepthExceeded();
    error NotCredit(string name);
    error SubAccountNotFound(string subName);
    error ZeroAddress();

    uint8 internal constant MAX_DEPTH = 10;
    // toNamedAddress("Supply")
    address internal constant SUPPLY_ADDRESS = 0x486d9E1EFfBE2991Ba97401Be079767f9879e1Dd;

    // Selectors
    bytes4 internal constant INITIALIZE_LEDGERS = bytes4(keccak256("initializeLedgers()"));
    bytes4 internal constant NAME = bytes4(keccak256("name(address)"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol(address)"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals(address)"));
    bytes4 internal constant ROOT = bytes4(keccak256("root(address)"));
    bytes4 internal constant PARENT = bytes4(keccak256("parent(address)"));
    bytes4 internal constant IS_GROUP = bytes4(keccak256("isGroup(address)"));
    bytes4 internal constant SUBACCOUNTS = bytes4(keccak256("subAccounts(address)"));
    bytes4 internal constant HAS_SUBACCOUNT = bytes4(keccak256("hasSubAccount(address)"));
    bytes4 internal constant SUBACCOUNT_INDEX = bytes4(keccak256("subAccountIndex(address)"));
    bytes4 internal constant BASE_NAME = bytes4(keccak256("name()"));
    bytes4 internal constant BASE_SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant BASE_DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant GROUP_BALANCE_OF = bytes4(keccak256("balanceOf(address,string)"));
    bytes4 internal constant BALANCE_OF = bytes4(keccak256("balanceOf(address,address)"));
    bytes4 internal constant BASE_BALANCE_OF = bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply(address)"));
    bytes4 internal constant BASE_TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,address,address,uint256)"));
    bytes4 internal constant BASE_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,address,address,uint256)"));
    bytes4 internal constant BASE_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant BASE_ALLOWANCE = bytes4(keccak256("allowance(address)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,address,address,address,uint256)"));
    bytes4 internal constant BASE_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));

    // Stores
    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledgers")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    //==================================================================
    //                            Validation
    //==================================================================
    function checkZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) revert ZeroAddress();
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
        if (!isValidString(str_)) revert InvalidString(str_);
    }

    function checkAccountGroup(address addr_) internal view {
        if (!isGroup(addr_)) revert InvalidAccountGroup(addr_);
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
        if (root(a_) != root(b_)) revert DifferentRoots(a_, b_);
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
        if (decimals_ == 0) revert InvalidDecimals(decimals_);
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
        revert MaxDepthExceeded();
    }

    function parent(address addr_) internal view returns (address) {
        return store().parent[addr_];
    }

    function subAccounts(address parent_) internal view returns (address[] memory) {
        return store().subs[parent_];
    }

    function hasSubAccount(address parent_) internal view returns (bool) {
        return store().subs[parent_].length > 0;
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
        if (!isGroup(parent_)) revert InvalidAccountGroup(parent_);
        if (!isValidString(name_)) revert InvalidSubAccount(name_, isGroup_, isCredit_);

        _sub = toGroupAddress(parent_, name_);

        bool _isExistingParent = parent(_sub) == parent_;
        bool _isExistingName = keccak256(bytes(name(_sub))) == keccak256(bytes(name_));
        if (_isExistingParent && _isExistingName) {
            if ((isCredit(_sub) == isCredit_) && (isGroup(_sub) == isGroup_)) {
                // SubAccount already exists with the same name and credit status
                return _sub;
            } else {
                // SubAccount already exists with the same name but different credit status
                revert InvalidSubAccount(name_, isGroup_, isCredit_);
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
        emit SubAccountAdded(_root, parent_, name_, isGroup_, isCredit_);
    }

    function removeSubAccount(address parent_, string memory name_) internal returns (address) {
        address _sub = toGroupAddress(parent_, name_);
        if (!isGroup(parent_)) revert InvalidAccountGroup(parent_);
        if (!isGroup(_sub)) revert InvalidAccountGroup(_sub);

        // Must exist and belong to this parent
        if (parent(_sub) != parent_) {
            revert SubAccountNotFound(name_);
        }

        if (hasSubAccount(_sub)) revert HasSubAccount(name_);
        if (hasBalance(_sub)) revert HasBalance(name_);

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
        emit SubAccountRemoved(_root, parent_, name_);

        return _sub;
    }

    function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) internal {
        if (!isValidString(name_) || !isValidString(symbol_) || decimals_ == 0) {
            revert InvalidToken(name_, symbol_, decimals_);
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
            revert InvalidToken(name_, symbol_, decimals_);
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

        emit LedgerAdded(token_, name_, symbol_, decimals_);
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function debit(address parent_, address ledger_, uint256 amount_, bool emitEvent_)
        internal
        returns (address _currentAccount)
    {
        checkAccountGroup(parent_);
        _currentAccount = toLedgerAddress(parent_, ledger_);

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
        if (emitEvent_) emit Debit(parent_, ledger_, amount_);
        revert MaxDepthExceeded();
    }

    function credit(address parent_, address ledger_, uint256 amount_, bool emitEvent_)
        internal
        returns (address _currentAccount)
    {
        checkAccountGroup(parent_);
        _currentAccount = toLedgerAddress(parent_, ledger_);

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
        if (emitEvent_) emit Credit(parent_, ledger_, amount_);
        revert MaxDepthExceeded();
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
        if (creditRoot != debitRoot) revert DifferentRoots(creditRoot, debitRoot);
        return true;
    }

    function mint(address toParent_, address to_, uint256 amount_) internal returns (bool) {
        address _token = root(toParent_);
        transfer(_token, Lib.SUPPLY_ADDRESS, toParent_, to_, amount_, true);
        return true;
    }

    function burn(address fromParent_, address from_, uint256 amount_) internal returns (bool) {
        address _token = root(fromParent_);
        transfer(fromParent_, from_, _token, Lib.SUPPLY_ADDRESS, amount_, true);
        return true;
    }

    //==================================================================
    //                         Approvals
    //==================================================================

    function approve(
        address ownerParent_,
        address owner_,
        address spenderParent_,
        address spender_,
        uint256 amount_,
        bool emitEvent_
    ) internal returns (bool) {
        checkAccountGroup(ownerParent_);
        checkAccountGroup(spenderParent_);
        address _owner = toLedgerAddress(ownerParent_, owner_);
        address _spender = toLedgerAddress(spenderParent_, spender_);

        store().allowances[_owner][_spender] = amount_;
        if (emitEvent_) emit InternalApproval(_owner, _spender, amount_);
        return true;
    }

    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        internal
        view
        returns (uint256)
    {
        address _ownerAddress = toLedgerAddress(ownerParent_, owner_);
        if (hasSubAccount(_ownerAddress)) {
            revert HasSubAccount(name(_ownerAddress));
        }
        address _spenderAddress = toLedgerAddress(spenderParent_, spender_);
        if (hasSubAccount(_spenderAddress)) {
            revert HasSubAccount(name(_spenderAddress));
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
        Store storage s = store();

        address _ownerAddress = toLedgerAddress(fromParent_, from_);
        address _spenderAddress = toLedgerAddress(spenderParent_, spender_);
        s.allowances[_ownerAddress][_spenderAddress] -= amount_;

        return transfer(fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }
}

contract Ledgers is Module, Initializable {
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    uint8 internal immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledgers.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function commands() public pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](26);
        _commands[n++] = Lib.INITIALIZE_LEDGERS;
        _commands[n++] = Lib.NAME;
        _commands[n++] = Lib.SYMBOL;
        _commands[n++] = Lib.DECIMALS;
        _commands[n++] = Lib.ROOT;
        _commands[n++] = Lib.PARENT;
        _commands[n++] = Lib.IS_GROUP;
        _commands[n++] = Lib.SUBACCOUNTS;
        _commands[n++] = Lib.HAS_SUBACCOUNT;
        _commands[n++] = Lib.SUBACCOUNT_INDEX;
        _commands[n++] = Lib.BASE_NAME;
        _commands[n++] = Lib.BASE_SYMBOL;
        _commands[n++] = Lib.BASE_DECIMALS;
        _commands[n++] = Lib.GROUP_BALANCE_OF;
        _commands[n++] = Lib.BALANCE_OF;
        _commands[n++] = Lib.BASE_BALANCE_OF;
        _commands[n++] = Lib.TOTAL_SUPPLY;
        _commands[n++] = Lib.BASE_TOTAL_SUPPLY;
        _commands[n++] = Lib.TRANSFER;
        _commands[n++] = Lib.BASE_TRANSFER;
        _commands[n++] = Lib.APPROVE;
        _commands[n++] = Lib.BASE_APPROVE;
        _commands[n++] = Lib.ALLOWANCE;
        _commands[n++] = Lib.BASE_ALLOWANCE;
        _commands[n++] = Lib.TRANSFER_FROM;
        _commands[n++] = Lib.BASE_TRANSFER_FROM;
    }

    function initializeLedgers_unchained() public onlyInitializing {
        enforceIsOwner();

        Lib.addLedger(address(this), "Scale", unicode"𝑆", 18);
    }

    function initializeLedgers() public initializer {
        initializeLedgers_unchained();
    }

    //==========
    // Metadata
    //==========
    function name(address addr_) public view returns (string memory) {
        return Lib.name(addr_);
    }

    function symbol(address addr_) public view returns (string memory) {
        return Lib.symbol(addr_);
    }

    function decimals(address addr_) public view returns (uint8) {
        return Lib.decimals(addr_);
    }

    function root(address addr_) public view returns (address) {
        return Lib.root(addr_);
    }

    function parent(address addr_) public view returns (address) {
        return Lib.parent(addr_);
    }

    function isGroup(address addr_) public view returns (bool) {
        return Lib.isGroup(addr_);
    }

    function subAccounts(address parent_) public view returns (address[] memory) {
        return Lib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) public view returns (bool) {
        return Lib.hasSubAccount(parent_);
    }

    function subAccountIndex(address addr_) public view returns (uint32) {
        return Lib.subAccountIndex(addr_);
    }

    //================
    // ERC20 Metadata
    //================
    function name() public view returns (string memory) {
        return Lib.name(address(this));
    }

    function symbol() public view returns (string memory) {
        return Lib.symbol(address(this));
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //======================
    // Balances & Transfers
    //======================

    // Subaccount balances
    function balanceOf(address parent_, string memory subName_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toGroupAddress(parent_, subName_));
    }

    // Ledger account balances
    function balanceOf(address parent_, address owner_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(parent_, owner_));
    }

    // ERC20 compatibility
    function balanceOf(address owner_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(address(this), owner_));
    }

    function totalSupply(address token_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(token_, Lib.SUPPLY_ADDRESS));
    }

    // ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(address(this), Lib.SUPPLY_ADDRESS));
    }

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) public returns (bool) {
        return Lib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    }

    // ERC20 compatibility
    function transfer(address to_, uint256 amount_) public returns (bool) {
        emit Lib.Transfer(msg.sender, to_, amount_);
        return Lib.transfer(address(this), msg.sender, address(this), to_, amount_, false);
    }

    function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        public
        returns (bool)
    {
        return Lib.approve(ownerParent_, msg.sender, spenderParent_, spender_, amount_, true);
    }

    // ERC20 compatibility
    function approve(address spender_, uint256 amount_) public returns (bool) {
        emit Lib.Approval(msg.sender, spender_, amount_);
        return Lib.approve(address(this), msg.sender, address(this), spender_, amount_, false);
    }

    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        public
        view
        returns (uint256)
    {
        return Lib.allowance(ownerParent_, owner_, spenderParent_, spender_);
    }

    // ERC20 compatibility
    function allowance(address owner_, address spender_) public view returns (uint256) {
        return Lib.allowance(address(this), owner_, address(this), spender_);
    }

    function transferFrom(
        address fromParent_,
        address from_,
        address spenderParent_,
        address toParent_,
        address to_,
        uint256 amount_
    ) public returns (bool) {
        return Lib.transferFrom(fromParent_, from_, spenderParent_, msg.sender, toParent_, to_, amount_, true);
    }

    // ERC20 compatibility
    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        return Lib.transferFrom(address(this), from_, address(this), msg.sender, address(this), to_, amount_, false);
    }
}
