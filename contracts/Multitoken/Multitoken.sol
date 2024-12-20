// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "@cavalre/contracts/router/Module.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {console} from "forge-std/src/Test.sol";

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
    bytes4 internal constant GET_HAS_CHILD =
        bytes4(keccak256("hasChild(address)"));
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
    event ParentAdded(
        address indexed root,
        address indexed parent,
        address indexed child
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Custom errors
    error HasBalance(address child);
    error HasChild(address child);
    error DifferentRoots(address a, address b);
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
        _commands = new bytes4[](23);
        _commands[0] = Lib.INITIALIZE_MULTITOKEN;
        _commands[1] = Lib.SET_NAME;
        _commands[2] = Lib.SET_SYMBOL;
        _commands[3] = Lib.GET_ROOT;
        _commands[4] = Lib.GET_NAME;
        _commands[5] = Lib.GET_SYMBOL;
        _commands[6] = Lib.GET_DECIMALS;
        _commands[7] = Lib.GET_PARENT;
        _commands[8] = Lib.GET_HAS_CHILD;
        _commands[9] = Lib.GET_BASE_NAME;
        _commands[10] = Lib.GET_BASE_SYMBOL;
        _commands[11] = Lib.GET_BASE_DECIMALS;
        _commands[12] = Lib.BALANCE_OF;
        _commands[13] = Lib.BASE_BALANCE_OF;
        _commands[14] = Lib.TOTAL_SUPPLY;
        _commands[15] = Lib.BASE_TOTAL_SUPPLY;
        _commands[16] = Lib.TRANSFER;
        _commands[17] = Lib.BASE_TRANSFER;
        _commands[18] = Lib.APPROVE;
        _commands[19] = Lib.BASE_APPROVE;
        _commands[20] = Lib.ALLOWANCE;
        _commands[21] = Lib.TRANSFER_FROM;
        _commands[22] = Lib.BASE_TRANSFER_FROM;
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

    function __checkRoots(address a_, address b_) internal view {
        if (root(a_) != root(b_)) revert DifferentRoots(a_, b_);
    }

    // Only leaf accounts can hold and transfer balances
    function __checkChild(address parent_) internal view {
        if (Lib.store().hasChild[parent_]) revert HasChild(parent_);
    }

    function __addChild(address parent_, address child_) internal returns (address) {
        if (parent_ == child_) revert InvalidParent();
        if (parent_ == address(0) || child_ == address(0))
            revert InvalidAddress();

        address _child = Lib.toAddress(parent_, child_);
        // Must build tree from the top down
        if (Lib.store().hasChild[_child]) revert HasChild(_child);
        // Cannot redirect a balance to a new parent
        if (Lib.store().balance[_child] != 0) revert HasBalance(_child);
        Lib.store().parent[_child] = parent_;
        Lib.store().hasChild[parent_] = true;
        address _root = root(_child);
        emit ParentAdded(_root, parent_, child_);
        return _child;
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
        address _balanceAddress = Lib.toAddress(parentAddress_, ownerAddress_);
        bool _isCredit = Lib.store().isCredit[_balanceAddress];
        int256 _balance = Lib.store().balance[_balanceAddress];
        return _isCredit ? uint256(-_balance) : uint256(_balance);
    }

    // Get the balance of an account for ERC20 compatibility
    function balanceOf(address ownerAddress_) public view returns (uint256) {
        return balanceOf(address(this), ownerAddress_);
    }

    function totalSupply(address assetAddress_) public view returns (uint256) {
        return
            uint256(
                -Lib.store().balance[
                    Lib.toAddress(assetAddress_, _totalSupplyAddress)
                ]
            );
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return totalSupply(address(this));
    }

    function __updateBalances(
        address parent_,
        address current_,
        int256 delta_
    ) internal returns (address _root) {
        if (parent_ == address(0) || current_ == address(0))
            revert InvalidAddress();
        __checkChild(current_);

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
        __checkRoots(fromParentAddress_, toParentAddress_);
        address _fromAddress = Lib.toAddress(fromParentAddress_, fromAddress_);
        address _toAddress = Lib.toAddress(toParentAddress_, toAddress_);

        int256 _amount = int256(amount_);
        __updateBalances(fromParentAddress_, _fromAddress, -_amount);
        __updateBalances(toParentAddress_, _toAddress, _amount);

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
                toAddress_,
                amount_
            );
    }

    // ERC20 Transfer
    function transfer(
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _fromAddress = Lib.toAddress(address(this), msg.sender);

        Store storage s = Lib.store();
        require(
            s.balance[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
        emit Transfer(msg.sender, recipientAddress_, amount_);
        return
            __transfer(
                address(this),
                msg.sender,
                address(this),
                recipientAddress_,
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

    function __approve(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _ownerAddress = Lib.toAddress(
            ownerParentAddress_,
            ownerAddress_
        );
        __checkChild(_ownerAddress);
        address _spenderAddress = Lib.toAddress(
            spenderParentAddress_,
            spenderAddress_
        );

        Store storage s = Lib.store();
        s.allowances[_ownerAddress][_spenderAddress] = amount_;

        return true;
    }

    // Approve a spender for a subaccount
    function approve(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _ownerAddress = Lib.toAddress(
            ownerParentAddress_,
            ownerAddress_
        );
        address _spenderAddress = Lib.toAddress(
            spenderParentAddress_,
            msg.sender
        );
        emit InternalApproval(_ownerAddress, _spenderAddress, amount_);
        return
            __approve(
                ownerParentAddress_,
                ownerAddress_,
                spenderParentAddress_,
                msg.sender,
                amount_
            );
    }

    // ERC20 Approve
    function approve(
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        emit Approval(msg.sender, spenderAddress_, amount_);
        return
            __approve(
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
    ) public view returns (uint256) {
        address _ownerAddress = Lib.toAddress(
            ownerParentAddress_,
            ownerAddress_
        );
        if (hasChild(_ownerAddress)) revert HasChild(_ownerAddress);
        address _spenderAddress = Lib.toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        if (hasChild(_spenderAddress)) revert HasChild(_spenderAddress);
        return Lib.store().allowances[_ownerAddress][_spenderAddress];
    }

    // ERC20 Allowance Query
    function allowance(
        address ownerAddress_,
        address spenderAddress_
    ) public view returns (uint256) {
        return
            allowance(
                address(this),
                ownerAddress_,
                address(this),
                spenderAddress_
            );
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
