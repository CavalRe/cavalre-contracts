// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "@cavalre/contracts/router/Module.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct Store {
    mapping(address => address) parent;
    mapping(address => bool) hasChild;
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;
    mapping(address => int256) balance;
    mapping(address owner => mapping(address spender => uint256)) allowances;
}

library Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_MULTITOKEN =
        bytes4(keccak256("initializeMultitoken(string,string)"));
    bytes4 internal constant SET_NAME =
        bytes4(keccak256("name(address,string)"));
    bytes4 internal constant SET_SYMBOL =
        bytes4(keccak256("symbol(address,string)"));
    bytes4 internal constant GET_ROOT = bytes4(keccak256("root(address)"));
    bytes4 internal constant ADD_CHILD =
        bytes4(keccak256("addChild(address,address)"));
    bytes4 internal constant GET_NAME = bytes4(keccak256("name(address)"));
    bytes4 internal constant GET_SYMBOL = bytes4(keccak256("symbol(address)"));
    bytes4 internal constant GET_DECIMALS =
        bytes4(keccak256("decimals(address)"));
    bytes4 internal constant GET_PARENT = bytes4(keccak256("parent(address)"));
    bytes4 internal constant GET_HAS_CHILD = bytes4(keccak256("hasChild(address)"));
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
        bytes4(keccak256("transfer(address,address,uint256)"));
    bytes4 internal constant BASE_TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant APPROVE =
        bytes4(keccak256("approve(address,address,uint256)"));
    bytes4 internal constant BASE_APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant ALLOWANCE =
        bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,address,uint256)"));
    bytes4 internal constant BASE_TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,uint256)"));

    // Stores
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(
                uint256(keccak256("cavalre.storage.ERC20WithSubaccounts")) - 1
            )
        ) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function toAddress(
        string memory originalId_
    ) internal pure returns (address) {
        return
            address(uint160(uint256(keccak256(abi.encodePacked(originalId_)))));
    }

    function toAddress(
        address parentAddress_,
        address originalAddress_
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(parentAddress_, originalAddress_)
                        )
                    )
                )
            );
    }

    function toAddress(
        address parentAddress_,
        string memory originalId_
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(parentAddress_, originalId_))
                    )
                )
            );
    }
}

contract Multitoken is Module, Initializable {
    uint8 internal immutable _decimals;
    uint8 internal immutable _maxDepth;
    address internal immutable _totalSupplyAddress =
        Lib.toAddress("Total Supply");

    // Events for ERC20 compatibility
    event InternalTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event ParentAdded(address indexed root, address indexed parent, address indexed child);

    // Custom errors
    error HasBalance(address child);
    error HasChild(address child);
    error HasParent(address parent, address child);
    error InvalidAddress();
    error InvalidParent();
    error InsufficientBalance();
    error MaxDepthExceeded();

    constructor(uint8 decimals_, uint8 maxDepth_) {
        _decimals = decimals_;
        _maxDepth = maxDepth_;
    }

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](24);
        _commands[0] = Lib.INITIALIZE_MULTITOKEN;
        _commands[1] = Lib.SET_NAME;
        _commands[2] = Lib.SET_SYMBOL;
        _commands[3] = Lib.GET_ROOT;
        _commands[4] = Lib.ADD_CHILD;
        _commands[5] = Lib.GET_NAME;
        _commands[6] = Lib.GET_SYMBOL;
        _commands[7] = Lib.GET_DECIMALS;
        _commands[8] = Lib.GET_PARENT;
        _commands[9] = Lib.GET_HAS_CHILD;
        _commands[10] = Lib.GET_BASE_NAME;
        _commands[11] = Lib.GET_BASE_SYMBOL;
        _commands[12] = Lib.GET_BASE_DECIMALS;
        _commands[13] = Lib.BALANCE_OF;
        _commands[14] = Lib.BASE_BALANCE_OF;
        _commands[15] = Lib.TOTAL_SUPPLY;
        _commands[16] = Lib.BASE_TOTAL_SUPPLY;
        _commands[17] = Lib.TRANSFER;
        _commands[18] = Lib.BASE_TRANSFER;
        _commands[19] = Lib.APPROVE;
        _commands[20] = Lib.BASE_APPROVE;
        _commands[21] = Lib.ALLOWANCE;
        _commands[22] = Lib.TRANSFER_FROM;
        _commands[23] = Lib.BASE_TRANSFER_FROM;
    }

    function initializeMultitoken(
        string memory name_,
        string memory symbol_
    ) public initializer {
        enforceIsOwner();
        Store storage s = Lib.store();
        s.name[address(this)] = name_;
        s.symbol[address(this)] = symbol_;
    }

    //==================
    // Metadata Setters
    //==================
    function name(address accountAddress_, string memory name_) public {
        enforceIsOwner();
        Store storage s = Lib.store();
        s.name[accountAddress_] = name_;
    }

    function symbol(address accountAddress_, string memory symbol_) public {
        enforceIsOwner();
        Store storage s = Lib.store();
        s.symbol[accountAddress_] = symbol_;
    }

    function root(address current_) public view returns (address) {
        if (current_ == address(0)) revert InvalidAddress();

        Store storage s = Lib.store();
        uint256 _depth;
        while (_depth < _maxDepth) {
            _depth++;
            address _parent = s.parent[current_];
            if (_parent == address(0)) {
                // Root found
                return current_;
            }
            current_ = _parent;
        }
        revert MaxDepthExceeded();
    }

    function addChild(address parent_, address child_) public {
        enforceIsOwner();
        if (parent_ == child_) revert InvalidParent();
        if (parent_ == address(0) || child_ == address(0))
            revert InvalidAddress();
        // Child can only have 1 parent
        if (Lib.store().parent[child_] != address(0))
            revert HasParent(parent_, child_);
        // Must build tree from the top down
        if (Lib.store().hasChild[child_]) revert HasChild(child_);
        // Cannot redirect a balance to a new parent
        if (Lib.store().balance[child_] != 0) revert HasBalance(child_);
        Lib.store().parent[child_] = parent_;
        Lib.store().hasChild[parent_] = true;
        address _root = root(child_);
        emit ParentAdded(_root, parent_, child_);
    }

    //==================
    // Metadata Getters
    //==================
    function name(address accountAddress_) public view returns (string memory) {
        return Lib.store().name[root(accountAddress_)];
    }

    function symbol(
        address accountAddress_
    ) public view returns (string memory) {
        return Lib.store().symbol[root(accountAddress_)];
    }

    function decimals(address accountAddress_) public view returns (uint8) {
        return Lib.store().decimals[root(accountAddress_)];
    }

    function parent(address child_) public view returns (address) {
        return Lib.store().parent[child_];
    }

    function hasChild(address parent_) public view returns (bool) {
        return Lib.store().hasChild[parent_];
    }

    //========================
    // ERC20 Metadata Getters
    //========================
    function name() public view returns (string memory) {
        return name(address(this));
    }

    function symbol() public view returns (string memory) {
        return symbol(address(this));
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
        address _parentAccountAddress = Lib.toAddress(
            parentAddress_,
            ownerAddress_
        );
        bool _isCredit = Lib.store().isCredit[_parentAccountAddress];
        int256 _balance = Lib.store().balance[_parentAccountAddress];
        return _isCredit ? uint256(-_balance) : uint256(_balance);
    }

    // Get the balance of an account for ERC20 compatibility
    function balanceOf(address ownerAddress_) public view returns (uint256) {
        return balanceOf(address(this), ownerAddress_);
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return
            uint256(
                -Lib.store().balance[
                    Lib.toAddress(address(this), _totalSupplyAddress)
                ]
            );
    }

    function __updateBalances(
        address parent_,
        address current_,
        int256 delta_
    ) internal returns (address _root) {
        if (parent_ == address(0) || current_ == address(0))
            revert InvalidAddress();

        Store storage s = Lib.store();
        uint8 _depth;
        while (_depth < _maxDepth) {
            // Do not update the balance of the root
            if (parent_ == address(0)) {
                // Root found
                return current_;
            }
            s.balance[current_] += delta_;
            current_ = parent_;
            parent_ = s.parent[parent_];
            _depth++;
        }
        revert MaxDepthExceeded();
    }

    function __transfer(
        address fromParentAddress_,
        address fromAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _fromAddress = Lib.toAddress(fromParentAddress_, fromAddress_);
        address _toAddress = Lib.toAddress(toParentAddress_, toAddress_);

        int256 _amount = int256(amount_);
        address _fromRoot = __updateBalances(
            fromParentAddress_,
            _fromAddress,
            -_amount
        );
        address _toRoot = __updateBalances(
            toParentAddress_,
            _toAddress,
            _amount
        );
        if (_fromRoot != _toRoot)
            revert("ERC20WithSubaccounts: Different roots");

        return true;
    }

    function transfer(
        address fromParentAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _fromAddress = Lib.toAddress(fromParentAddress_, msg.sender);
        address _toAddress = Lib.toAddress(toParentAddress_, toAddress_);

        Store storage s = Lib.store();
        require(
            s.balance[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
        emit InternalTransfer(_fromAddress, _toAddress, amount_);
        return
            __transfer(
                fromParentAddress_,
                msg.sender,
                toParentAddress_,
                _toAddress,
                amount_
            );
    }

    // ERC20 Transfer
    function transfer(
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _fromAddress = Lib.toAddress(address(this), msg.sender);
        address _toAddress = Lib.toAddress(address(this), recipientAddress_);

        Store storage s = Lib.store();
        require(
            s.balance[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
        emit Transfer(msg.sender, recipientAddress_, amount_);
        return
            __transfer(
                address(this),
                _fromAddress,
                address(this),
                _toAddress,
                amount_
            );
    }

    function __mint(
        address assetAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        if (assetAddress_ == address(0) || toAddress_ == address(0))
            revert InvalidAddress();
        if (Lib.store().parent[assetAddress_] != address(0))
            revert InvalidParent();

        __transfer(
            assetAddress_,
            _totalSupplyAddress,
            assetAddress_,
            toAddress_,
            amount_
        );
        return true;
    }

    function __burn(
        address assetAddress_,
        address fromAddress_,
        uint256 amount_
    ) internal returns (bool) {
        if (assetAddress_ == address(0) || fromAddress_ == address(0))
            revert InvalidAddress();
        if (Lib.store().parent[assetAddress_] != address(0))
            revert InvalidParent();

        __transfer(
            assetAddress_,
            fromAddress_,
            assetAddress_,
            _totalSupplyAddress,
            amount_
        );
        return true;
    }

    // Approve a spender for a subaccount
    function approve(
        address ownerParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _ownerAddress = Lib.toAddress(ownerParentAddress_, msg.sender);

        Store storage s = Lib.store();
        s.allowances[_ownerAddress][spenderAddress_] = amount_;

        emit Approval(_ownerAddress, spenderAddress_, amount_);
        return true;
    }

    // ERC20 Approve
    function approve(
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _spenderAddress = Lib.toAddress(address(this), spenderAddress_);
        return approve(address(this), _spenderAddress, amount_);
    }

    // ERC20 Allowance Query
    function allowance(
        address ownerAddress_,
        address spenderAddress_
    ) public view returns (uint256) {
        Store storage s = Lib.store();
        return s.allowances[ownerAddress_][spenderAddress_];
    }

    // Transfer From
    function __transferFrom(
        address ownerParentAddress_,
        address ownerAddress_,
        address recipientParentAddress_,
        address recipientAddress_,
        uint256 amount_
    ) internal returns (bool) {
        Store storage s = Lib.store();

        address _ownerAddress = Lib.toAddress(
            ownerParentAddress_,
            ownerAddress_
        );
        s.allowances[_ownerAddress][msg.sender] -= amount_;

        return
            __transfer(
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
        address recipientParentAddress_,
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _ownerAddress = Lib.toAddress(
            ownerParentAddress_,
            ownerAddress_
        );
        address _recipientAddress = Lib.toAddress(
            recipientParentAddress_,
            recipientAddress_
        );

        emit InternalTransfer(_ownerAddress, _recipientAddress, amount_);
        return
            __transferFrom(
                ownerParentAddress_,
                ownerAddress_,
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
        emit Transfer(ownerAddress_, recipientAddress_, amount_);
        return
            __transferFrom(
                address(this),
                ownerAddress_,
                address(this),
                recipientAddress_,
                amount_
            );
    }
}
