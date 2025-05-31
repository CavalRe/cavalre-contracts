// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "@cavalre/contracts/router/Module.sol";
import {Initializable} from "@cavalre/contracts/Initializable/Initializable.sol";

struct Store {
    mapping(address => bool) isAccountGroup;
    mapping(address subAccount => address) parentAccount;
    mapping(address subAccount => uint32) subAccountIndex;
    mapping(address parentAccount => address[]) subAccounts;
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;
    mapping(address => uint256) balance;
    mapping(address owner => mapping(address spender => uint256)) allowances;
}

library Lib {
    event SourceAdded(string indexed appName);
    event SourceRemoved(string indexed appName);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event InternalApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event InternalTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event SubAccountAdded(
        address indexed root,
        address indexed parentAccount,
        address indexed subAccount
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Custom errors
    error SubAccountNotFound(address subAccount);
    error HasBalance(string subAccountName);
    error HasSubAccount(string subAccountName);
    error DifferentRoots(address a, address b);
    error DuplicateSubAccount(address subAccount);
    error InvalidAddress();
    error InvalidSubAccount(string subAccountName, bool isCredit);
    error InvalidToken(string name, string symbol, uint8 decimals);
    error InsufficientBalance();
    error MaxDepthExceeded();

    uint8 internal constant MAX_DEPTH = 10;
    address internal constant ROOT_ADDRESS =
        0xFE99DF08Ff3B677df31fFB23cD04828AA70d2de5;
    address internal constant TOTAL_ADDRESS =
        0xa763678a2e868D872d408672C9f80B77F4d1d14B;

    // Selectors
    bytes4 internal constant INITIALIZE_MULTITOKEN =
        bytes4(keccak256("initializeMultitoken(string,string)"));
    bytes4 internal constant SET_NAME =
        bytes4(keccak256("name(address,string)"));
    bytes4 internal constant SET_SYMBOL =
        bytes4(keccak256("symbol(address,string)"));
    bytes4 internal constant GET_ROOT = bytes4(keccak256("root(address)"));
    bytes4 internal constant ADD_SUBACCOUNT =
        bytes4(keccak256("addSubAccount(address,address)"));
    bytes4 internal constant GET_NAME = bytes4(keccak256("name(address)"));
    bytes4 internal constant GET_SYMBOL = bytes4(keccak256("symbol(address)"));
    bytes4 internal constant GET_DECIMALS =
        bytes4(keccak256("decimals(address)"));
    bytes4 internal constant GET_PARENTACCOUNT =
        bytes4(keccak256("parentAccount(address)"));
    bytes4 internal constant GET_SUBACCOUNTS =
        bytes4(keccak256("subAccounts(address)"));
    bytes4 internal constant GET_HAS_SUBACCOUNT =
        bytes4(keccak256("hasSubAccount(address)"));
    bytes4 internal constant GET_SUBACCOUNT_INDEX =
        bytes4(keccak256("subAccountIndex(address)"));
    bytes4 internal constant GET_BASE_NAME = bytes4(keccak256("name()"));
    bytes4 internal constant GET_BASE_SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant GET_BASE_DECIMALS =
        bytes4(keccak256("decimals()"));
    bytes4 internal constant BALANCE_OF =
        bytes4(keccak256("balanceOf(address,address)"));
    bytes4 internal constant BASE_BALANCE_OF =
        bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant TOTAL_SUPPLY =
        bytes4(keccak256("totalSupply(address)"));
    bytes4 internal constant BASE_TOTAL_SUPPLY =
        bytes4(keccak256("totalSupply()"));
    bytes4 internal constant TRANSFER =
        bytes4(keccak256("transfer(address,address,address,uint256)"));
    bytes4 internal constant BASE_TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant APPROVE =
        bytes4(keccak256("approve(address,address,address,uint256)"));
    bytes4 internal constant BASE_APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant ALLOWANCE =
        bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(
            keccak256(
                "transferFrom(address,address,address,address,address,uint256)"
            )
        );
    bytes4 internal constant BASE_TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,uint256)"));

    // Stores
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("cavalre.storage.Multitoken")) - 1)
        ) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function toAddress(string memory name_) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(name_)))));
    }

    function toAddress(
        address parentAccount_,
        address subAccount_
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(parentAccount_, subAccount_))
                    )
                )
            );
    }

    function toAddress(
        address parentAccount_,
        string memory name_
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(parentAccount_, name_)))
                )
            );
    }

    //==================
    // Metadata Setters
    //==================
    function name(address absoluteAddress_, string memory name_) internal {
        store().name[absoluteAddress_] = name_;
    }

    function symbol(address absoluteAddress_, string memory symbol_) internal {
        store().symbol[absoluteAddress_] = symbol_;
    }

    function decimals(address absoluteAddress_, uint8 decimals_) internal {
        if (absoluteAddress_ == address(this)) revert InvalidAddress();
        store().decimals[absoluteAddress_] = decimals_;
    }

    //==================
    // Metadata Getters
    //==================
    function name(
        address absoluteAddress_
    ) internal view returns (string memory) {
        return store().name[absoluteAddress_];
    }

    function symbol(
        address absoluteAddress_
    ) internal view returns (string memory) {
        return store().symbol[root(absoluteAddress_)];
    }

    function decimals(address absoluteAddress_) internal view returns (uint8) {
        return store().decimals[root(absoluteAddress_)];
    }

    function root(address currentAccount_) internal view returns (address) {
        if (currentAccount_ == address(0)) revert InvalidAddress();

        Store storage s = store();
        uint256 _depth;
        address _parentAccount;
        while (_depth < MAX_DEPTH) {
            _depth++;
            _parentAccount = s.parentAccount[currentAccount_];
            if (_parentAccount == address(0)) {
                // Root found
                return currentAccount_;
            }
            currentAccount_ = _parentAccount;
        }
        revert MaxDepthExceeded();
    }

    function parentAccount(
        address subAccount_
    ) internal view returns (address) {
        return store().parentAccount[subAccount_];
    }

    function subAccounts(
        address parentAccount_
    ) internal view returns (address[] memory) {
        return store().subAccounts[parentAccount_];
    }

    function hasSubAccount(
        address parentAccount_
    ) internal view returns (bool) {
        return store().subAccounts[parentAccount_].length > 0;
    }

    function subAccountIndex(
        address subAccount_
    ) internal view returns (uint32) {
        return store().subAccountIndex[subAccount_];
    }

    //==================================================================
    //                        Balance & Supply
    //==================================================================
    function balanceOf(
        address absoluteAddress_
    ) internal view returns (uint256) {
        return store().balance[absoluteAddress_];
    }

    function balanceOf(
        address parentAddress_,
        address ownerAddress_
    ) internal view returns (uint256) {
        return balanceOf(toAddress(parentAddress_, ownerAddress_));
    }

    function totalSupply(
        address tokenAddress_
    ) internal view returns (uint256) {
        return balanceOf(toAddress(tokenAddress_, TOTAL_ADDRESS));
    }

    function hasBalance(address absoluteAddress_) internal view returns (bool) {
        return store().balance[absoluteAddress_] > 0;
    }

    //==================================================================
    //                            Validation
    //==================================================================
    // Transfers can only occur within the same tree
    function checkRoots(address a_, address b_) internal view {
        if (root(a_) != root(b_)) revert DifferentRoots(a_, b_);
    }

    // Only leaf accounts can hold and transfer balances
    function checkSubAccount(address parentAccount_) internal view {
        if (hasSubAccount(parentAccount_))
            revert HasSubAccount(name(parentAccount_));
    }

    function isAccountGroup(
        address absoluteAddress_
    ) internal view returns (bool) {
        return store().isAccountGroup[absoluteAddress_];
    }

    function isAccountGroup(
        address absoluteAddress_,
        bool isAccountGroup_
    ) internal {
        store().isAccountGroup[absoluteAddress_] = isAccountGroup_;
    }

    function isLeaf(
        address parentAccount_,
        address subAccount_
    ) internal view returns (bool) {
        return
            parentAccount(toAddress(parentAccount_, subAccount_)) ==
            address(0) &&
            isAccountGroup(parentAccount_);
    }

    //==================================================================
    //                         Tree Manipulation
    //==================================================================

    function addSubAccount(
        string memory subAccountName_,
        address parentAccount_,
        address subAccount_,
        bool isCredit_
    ) internal returns (address) {
        if (
            parentAccount_ == subAccount_ ||
            parentAccount_ == address(0) ||
            subAccount_ == address(0)
        ) revert InvalidAddress();
        address _subAccount = toAddress(parentAccount_, subAccount_);
        // Return if subAccount already exists with same name and account type
        if (parentAccount(_subAccount) == parentAccount_) {
            if (
                keccak256(abi.encodePacked(name(_subAccount))) ==
                keccak256(abi.encodePacked(subAccountName_)) &&
                store().isCredit[_subAccount] == isCredit_
            ) {
                // No changes needed
                return _subAccount;
            }
            revert InvalidSubAccount(subAccountName_, isCredit_);
        }
        // Only leaves can hold balances
        if (hasBalance(parentAccount_)) revert HasBalance(name(parentAccount_));
        // Must build tree from the top down
        if (hasSubAccount(_subAccount)) revert HasSubAccount(subAccountName_);
        if (hasBalance(_subAccount)) revert HasBalance(subAccountName_);

        store().isAccountGroup[subAccount_] = true;
        store().name[_subAccount] = subAccountName_;
        store().parentAccount[_subAccount] = parentAccount_;
        store().subAccounts[parentAccount_].push(subAccount_);
        store().subAccountIndex[_subAccount] = uint32(
            store().subAccounts[parentAccount_].length
        );
        store().isCredit[_subAccount] = isCredit_;
        address _root = root(_subAccount);
        emit SubAccountAdded(_root, parentAccount_, subAccount_);
        return _subAccount;
    }

    function addSubAccount(
        string memory subAccountName_,
        address parentAccount_,
        address subAccount_
    ) internal returns (address) {
        return
            addSubAccount(subAccountName_, parentAccount_, subAccount_, false);
    }

    function removeSubAccount(
        address parentAccount_,
        address subAccount_
    ) internal returns (address) {
        if (
            parentAccount_ == subAccount_ ||
            parentAccount_ == address(0) ||
            subAccount_ == address(0)
        ) revert InvalidAddress();
        address _subAccount = toAddress(parentAccount_, subAccount_);
        if (parentAccount(_subAccount) != parentAccount_)
            revert SubAccountNotFound(subAccount_);
        // Must remove subAccounts from the bottom up
        if (hasSubAccount(_subAccount)) revert HasSubAccount(name(_subAccount));
        // Cannot remove a subAccount that has a balance
        if (hasBalance(_subAccount))
            revert HasBalance(store().name[_subAccount]);

        store().isAccountGroup[_subAccount] = false;
        store().name[_subAccount] = "";
        uint256 _index = store().subAccountIndex[_subAccount] - 1;
        address _lastSubAccount = store().subAccounts[parentAccount_][
            store().subAccounts[parentAccount_].length - 1
        ];

        // Move last subAccount to removed position
        store().subAccounts[parentAccount_][_index] = _lastSubAccount;
        store().subAccounts[parentAccount_].pop();
        store().subAccountIndex[
            toAddress(parentAccount_, _lastSubAccount)
        ] = uint32(_index + 1);

        store().parentAccount[_subAccount] = address(0);
        store().subAccountIndex[_subAccount] = 0;
        store().isCredit[_subAccount] = false;
        return _subAccount;
    }

    function addTokenSource(
        string memory sourceName_,
        address tokenAddress_
    ) internal {
        address _sourceAddress = toAddress(sourceName_);
        store().name[_sourceAddress] = sourceName_;
        name(_sourceAddress, sourceName_);
        addSubAccount(
            sourceName_,
            toAddress(tokenAddress_, TOTAL_ADDRESS),
            _sourceAddress,
            true
        );
        emit SourceAdded(sourceName_);
    }

    function removeTokenSource(
        string memory sourceName_,
        address tokenAddress_
    ) internal {
        address _sourceAddress = toAddress(sourceName_);
        removeSubAccount(
            toAddress(tokenAddress_, TOTAL_ADDRESS),
            _sourceAddress
        );
        emit SourceRemoved(sourceName_);
    }

    function sources(
        address tokenAddress_
    ) internal view returns (address[] memory) {
        return subAccounts(toAddress(tokenAddress_, TOTAL_ADDRESS));
    }

    function addToken(
        address tokenAddress_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        address _totalAbsoluteAddress = toAddress(tokenAddress_, TOTAL_ADDRESS);
        if (parentAccount(_totalAbsoluteAddress) == tokenAddress_) {
            // Token already exists
            if (
                keccak256(abi.encodePacked(name_)) ==
                keccak256(abi.encodePacked(name(tokenAddress_))) &&
                keccak256(abi.encodePacked(symbol_)) ==
                keccak256(abi.encodePacked(symbol(tokenAddress_))) &&
                decimals(tokenAddress_) == decimals_
            ) {
                // No changes needed
                return;
            } else {
                revert InvalidToken(name_, symbol_, decimals_);
            }
        }

        store().isAccountGroup[tokenAddress_] = true;
        store().name[tokenAddress_] = name_;
        store().symbol[tokenAddress_] = symbol_;
        store().decimals[tokenAddress_] = decimals_;

        store().isCredit[
            toAddress(
                addSubAccount("Total", tokenAddress_, TOTAL_ADDRESS, true),
                ROOT_ADDRESS
            )
        ] = true;
    }

    //==================================================================
    //                         Transfers
    //==================================================================

    function debit(
        address parentAccount_,
        address currentAccount_,
        uint256 amount_
    ) internal returns (address _root) {
        if (parentAccount_ == address(0) || currentAccount_ == address(0))
            revert InvalidAddress();
        checkSubAccount(currentAccount_);

        Store storage s = store();
        uint8 _depth;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (parentAccount_ == address(0)) {
                // Root found
                return currentAccount_;
            }
            if (s.isCredit[currentAccount_]) {
                require(
                    s.balance[currentAccount_] >= amount_,
                    "ERC20WithSubaccounts: Insufficient balance"
                );
                s.balance[currentAccount_] -= amount_;
            } else {
                s.balance[currentAccount_] += amount_;
            }
            currentAccount_ = parentAccount_;
            parentAccount_ = s.parentAccount[parentAccount_];
            _depth++;
        }
        revert MaxDepthExceeded();
    }

    function credit(
        address parentAccount_,
        address currentAccount_,
        uint256 amount_
    ) internal returns (address _root) {
        if (parentAccount_ == address(0) || currentAccount_ == address(0))
            revert InvalidAddress();
        checkSubAccount(currentAccount_);

        Store storage s = store();
        uint8 _depth;
        while (_depth < MAX_DEPTH) {
            // Do not update the balance of the root
            if (parentAccount_ == address(0)) {
                // Root found
                return currentAccount_;
            }
            if (s.isCredit[currentAccount_]) {
                s.balance[currentAccount_] += amount_;
            } else {
                require(
                    s.balance[currentAccount_] >= amount_,
                    "ERC20WithSubaccounts: Insufficient balance"
                );
                s.balance[currentAccount_] -= amount_;
            }
            currentAccount_ = parentAccount_;
            parentAccount_ = s.parentAccount[parentAccount_];
            _depth++;
        }
        revert MaxDepthExceeded();
    }

    function transfer(
        address fromParentAddress_,
        address fromAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        checkRoots(fromParentAddress_, toParentAddress_);
        address _fromAddress = toAddress(fromParentAddress_, fromAddress_);
        address _toAddress = toAddress(toParentAddress_, toAddress_);

        credit(fromParentAddress_, _fromAddress, amount_);
        debit(toParentAddress_, _toAddress, amount_);

        return true;
    }

    function transfer(
        address fromParentAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _fromAddress = toAddress(fromParentAddress_, msg.sender);
        address _toAddress = toAddress(toParentAddress_, toAddress_);

        emit InternalTransfer(_fromAddress, _toAddress, amount_);
        return
            transfer(
                fromParentAddress_,
                msg.sender,
                toParentAddress_,
                toAddress_,
                amount_
            );
    }

    // ERC20 Transfer
    function transfer(
        address recipientAddress_,
        uint256 amount_
    ) internal returns (bool) {
        emit Transfer(msg.sender, recipientAddress_, amount_);
        return
            transfer(
                address(this),
                msg.sender,
                address(this),
                recipientAddress_,
                amount_
            );
    }

    function mint(
        address sourceAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        if (toParentAddress_ == address(0) || toAddress_ == address(0))
            revert InvalidAddress();

        transfer(
            toAddress(root(toParentAddress_), TOTAL_ADDRESS),
            sourceAddress_,
            toParentAddress_,
            toAddress_,
            amount_
        );
        return true;
    }

    function mint(
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        return mint(ROOT_ADDRESS, toParentAddress_, toAddress_, amount_);
    }

    function burn(
        address sourceAddress_,
        address fromParentAddress_,
        address fromAddress_,
        uint256 amount_
    ) internal returns (bool) {
        if (fromParentAddress_ == address(0) || fromAddress_ == address(0))
            revert InvalidAddress();

        transfer(
            fromParentAddress_,
            fromAddress_,
            toAddress(root(fromParentAddress_), TOTAL_ADDRESS),
            sourceAddress_,
            amount_
        );
        return true;
    }

    function burn(
        address fromParentAddress_,
        address fromAddress_,
        uint256 amount_
    ) internal returns (bool) {
        return burn(ROOT_ADDRESS, fromParentAddress_, fromAddress_, amount_);
    }

    //==================================================================
    //                         Approvals
    //==================================================================

    function approve(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _ownerAddress = toAddress(ownerParentAddress_, ownerAddress_);
        checkSubAccount(_ownerAddress);
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        checkSubAccount(_spenderAddress);

        store().allowances[_ownerAddress][_spenderAddress] = amount_;

        return true;
    }

    function approve(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _ownerAddress = toAddress(ownerParentAddress_, msg.sender);
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        emit InternalApproval(_ownerAddress, _spenderAddress, amount_);
        return
            approve(
                ownerParentAddress_,
                msg.sender,
                spenderParentAddress_,
                spenderAddress_,
                amount_
            );
    }

    // ERC20 Approve
    function approve(
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        emit Approval(msg.sender, spenderAddress_, amount_);
        return
            approve(
                address(this),
                msg.sender,
                address(this),
                spenderAddress_,
                amount_
            );
    }

    function allowance(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_
    ) internal view returns (uint256) {
        address _ownerAddress = toAddress(ownerParentAddress_, ownerAddress_);
        if (hasSubAccount(_ownerAddress))
            revert HasSubAccount(name(_ownerAddress));
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        if (hasSubAccount(_spenderAddress))
            revert HasSubAccount(name(_spenderAddress));
        return store().allowances[_ownerAddress][_spenderAddress];
    }

    // Transfer From
    function transferFrom(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        address recipientParentAddress_,
        address recipientAddress_,
        uint256 amount_
    ) internal returns (bool) {
        Store storage s = store();

        address _ownerAddress = toAddress(ownerParentAddress_, ownerAddress_);
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        s.allowances[_ownerAddress][_spenderAddress] -= amount_;

        return
            transfer(
                ownerParentAddress_,
                ownerAddress_,
                recipientParentAddress_,
                recipientAddress_,
                amount_
            );
    }

    function transferFrom(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address recipientParentAddress_,
        address recipientAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _ownerAddress = toAddress(ownerParentAddress_, ownerAddress_);
        address _recipientAddress = toAddress(
            recipientParentAddress_,
            recipientAddress_
        );

        emit InternalTransfer(_ownerAddress, _recipientAddress, amount_);
        return
            transferFrom(
                ownerParentAddress_,
                ownerAddress_,
                spenderParentAddress_,
                msg.sender,
                recipientParentAddress_,
                recipientAddress_,
                amount_
            );
    }

    // ERC20 Transfer From
    function transferFrom(
        address ownerAddress_,
        address recipientAddress_,
        uint256 amount_
    ) internal returns (bool) {
        emit Transfer(ownerAddress_, recipientAddress_, amount_);
        return
            transferFrom(
                address(this),
                ownerAddress_,
                address(this),
                msg.sender,
                address(this),
                recipientAddress_,
                amount_
            );
    }
}

contract Multitoken is Module, Initializable {
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    uint8 internal immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(
            abi.encode(
                uint256(keccak256("cavalre.storage.Multitoken.Initializable")) -
                    1
            )
        ) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot()
        internal
        pure
        override
        returns (bytes32)
    {
        return INITIALIZABLE_STORAGE;
    }

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](25);
        _commands[0] = Lib.INITIALIZE_MULTITOKEN;
        _commands[1] = Lib.SET_NAME;
        _commands[2] = Lib.SET_SYMBOL;
        _commands[3] = Lib.GET_ROOT;
        _commands[4] = Lib.GET_NAME;
        _commands[5] = Lib.GET_SYMBOL;
        _commands[6] = Lib.GET_DECIMALS;
        _commands[7] = Lib.GET_PARENTACCOUNT;
        _commands[8] = Lib.GET_SUBACCOUNTS;
        _commands[9] = Lib.GET_HAS_SUBACCOUNT;
        _commands[10] = Lib.GET_SUBACCOUNT_INDEX;
        _commands[11] = Lib.GET_BASE_NAME;
        _commands[12] = Lib.GET_BASE_SYMBOL;
        _commands[13] = Lib.GET_BASE_DECIMALS;
        _commands[14] = Lib.BALANCE_OF;
        _commands[15] = Lib.BASE_BALANCE_OF;
        _commands[16] = Lib.TOTAL_SUPPLY;
        _commands[17] = Lib.BASE_TOTAL_SUPPLY;
        _commands[18] = Lib.TRANSFER;
        _commands[19] = Lib.BASE_TRANSFER;
        _commands[20] = Lib.APPROVE;
        _commands[21] = Lib.BASE_APPROVE;
        _commands[22] = Lib.ALLOWANCE;
        _commands[23] = Lib.TRANSFER_FROM;
        _commands[24] = Lib.BASE_TRANSFER_FROM;
    }

    function initializeMultitoken_unchained(
        string memory name_,
        string memory symbol_
    ) public onlyInitializing {
        enforceIsOwner();

        Lib.addToken(address(this), name_, symbol_, _decimals);
    }

    function initializeMultitoken(
        string memory name_,
        string memory symbol_
    ) public initializer {
        initializeMultitoken_unchained(name_, symbol_);
    }

    //==================
    // Metadata Setters
    //==================
    function name(address absoluteAddress_, string memory name_) public {
        enforceIsOwner();
        Lib.name(absoluteAddress_, name_);
    }

    function symbol(address absoluteAddress_, string memory symbol_) public {
        enforceIsOwner();
        Lib.symbol(absoluteAddress_, symbol_);
    }

    //==================
    // Metadata Getters
    //==================
    function name(
        address absoluteAddress_
    ) public view returns (string memory) {
        return Lib.name(absoluteAddress_);
    }

    function symbol(
        address absoluteAddress_
    ) public view returns (string memory) {
        return Lib.symbol(absoluteAddress_);
    }

    function decimals(address absoluteAddress_) public view returns (uint8) {
        return Lib.decimals(absoluteAddress_);
    }

    function root(address absoluteAddress_) public view returns (address) {
        return Lib.root(absoluteAddress_);
    }

    function parentAccount(address subAccount_) public view returns (address) {
        return Lib.parentAccount(subAccount_);
    }

    function subAccounts(
        address parentAccount_
    ) public view returns (address[] memory) {
        return Lib.subAccounts(parentAccount_);
    }

    function hasSubAccount(address parentAccount_) public view returns (bool) {
        return Lib.hasSubAccount(parentAccount_);
    }

    function subAccountIndex(address subAccount_) public view returns (uint32) {
        return Lib.subAccountIndex(subAccount_);
    }

    //========================
    // ERC20 Metadata Getters
    //========================
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

    // Get the balance of an account
    function balanceOf(
        address parentAddress_,
        address ownerAddress_
    ) public view returns (uint256) {
        return Lib.balanceOf(parentAddress_, ownerAddress_);
    }

    // Get the balance of an account for ERC20 compatibility
    function balanceOf(address ownerAddress_) public view returns (uint256) {
        return Lib.balanceOf(address(this), ownerAddress_);
    }

    function totalSupply(address assetAddress_) public view returns (uint256) {
        return Lib.totalSupply(assetAddress_);
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return Lib.totalSupply(address(this));
    }

    function transfer(
        address fromParentAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) public returns (bool) {
        return
            Lib.transfer(
                fromParentAddress_,
                toParentAddress_,
                toAddress_,
                amount_
            );
    }

    // ERC20 Transfer
    function transfer(
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        return Lib.transfer(recipientAddress_, amount_);
    }

    // Approve a spender for a subAccount
    function approve(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        return
            Lib.approve(
                ownerParentAddress_,
                spenderParentAddress_,
                spenderAddress_,
                amount_
            );
    }

    // ERC20 Approve
    function approve(
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        return Lib.approve(spenderAddress_, amount_);
    }

    function allowance(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_
    ) public view returns (uint256) {
        return
            Lib.allowance(
                ownerParentAddress_,
                ownerAddress_,
                spenderParentAddress_,
                spenderAddress_
            );
    }

    // ERC20 Allowance Query
    function allowance(
        address ownerAddress_,
        address spenderAddress_
    ) public view returns (uint256) {
        return
            Lib.allowance(
                address(this),
                ownerAddress_,
                address(this),
                spenderAddress_
            );
    }

    function transferFrom(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address recipientParentAddress_,
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        return
            Lib.transferFrom(
                ownerParentAddress_,
                ownerAddress_,
                spenderParentAddress_,
                recipientParentAddress_,
                recipientAddress_,
                amount_
            );
    }

    // ERC20 Transfer From
    function transferFrom(
        address ownerAddress_,
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        return Lib.transferFrom(ownerAddress_, recipientAddress_, amount_);
    }
}
