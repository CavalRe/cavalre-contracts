// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "@cavalre/contracts/router/Module.sol";

struct Store {
    mapping(address => address) parent;
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;
    mapping(address => int256) balances;
    mapping(address owner => mapping(address spender => uint256)) allowances;
}

library Lib {
    // Selectors
    bytes4 internal constant SET_NAME =
        bytes4(keccak256("name(address,string)"));
    bytes4 internal constant SET_SYMBOL =
        bytes4(keccak256("symbol(address,string)"));
    bytes4 internal constant GET_NAME = bytes4(keccak256("name(address)"));
    bytes4 internal constant GET_SYMBOL = bytes4(keccak256("symbol(address)"));
    bytes4 internal constant GET_DECIMALS =
        bytes4(keccak256("decimals(address)"));
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

contract ERC20WithSubaccounts is Module {
    uint8 internal immutable _maxDepth;
    address internal immutable _totalSupplyAddress =
        Lib.toAddress(address(this), "Total Supply");

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

    // Custom errors
    error InvalidAddress();
    error InvalidParent();
    error InsufficientBalance();
    error MaxDepthExceeded();

    constructor(uint8 maxDepth_) {
        _maxDepth = maxDepth_;
    }

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](19);
        _commands[0] = Lib.SET_NAME;
        _commands[1] = Lib.SET_SYMBOL;
        _commands[2] = Lib.GET_NAME;
        _commands[3] = Lib.GET_SYMBOL;
        _commands[4] = Lib.GET_DECIMALS;
        _commands[5] = Lib.GET_BASE_NAME;
        _commands[6] = Lib.GET_BASE_SYMBOL;
        _commands[7] = Lib.GET_BASE_DECIMALS;
        _commands[8] = Lib.BALANCE_OF;
        _commands[9] = Lib.BASE_BALANCE_OF;
        _commands[10] = Lib.TOTAL_SUPPLY;
        _commands[11] = Lib.BASE_TOTAL_SUPPLY;
        _commands[12] = Lib.TRANSFER;
        _commands[13] = Lib.BASE_TRANSFER;
        _commands[14] = Lib.APPROVE;
        _commands[15] = Lib.BASE_APPROVE;
        _commands[16] = Lib.ALLOWANCE;
        _commands[17] = Lib.TRANSFER_FROM;
        _commands[18] = Lib.BASE_TRANSFER_FROM;
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

    //==================
    // Metadata Getters
    //==================
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
        return decimals(address(this));
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
        int256 _balance = Lib.store().balances[_parentAccountAddress];
        return _isCredit ? uint256(-_balance) : uint256(_balance);
    }

    // Get the balance of an account for ERC20 compatibility
    function balanceOf(address ownerAddress_) public view returns (uint256) {
        return balanceOf(address(this), ownerAddress_);
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return balanceOf(_totalSupplyAddress);
    }

    function __updateBalances(
        address current_,
        int256 delta_
    ) internal returns (address _root) {
        if (current_ == address(0)) revert InvalidAddress();

        Store storage s = Lib.store();
        uint8 _depth;
        while (_depth < _maxDepth) {
            _depth++;
            address _parent = s.parent[current_];
            if (_parent == address(0)) {
                // Root found
                return current_;
            }
            s.balances[current_] += delta_;
            current_ = _parent;
        }
        revert MaxDepthExceeded();
    }

    function __transfer(
        address fromAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        int256 _amount = int256(amount_);
        address _fromRoot = __updateBalances(fromAddress_, -_amount);
        address _toRoot = __updateBalances(toAddress_, _amount);
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
            s.balances[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
        emit InternalTransfer(_fromAddress, _toAddress, amount_);
        return __transfer(_fromAddress, _toAddress, amount_);
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
            s.balances[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
        emit Transfer(msg.sender, recipientAddress_, amount_);
        return __transfer(_fromAddress, _toAddress, amount_);
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
        address ownerAddress_,
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        Store storage s = Lib.store();

        uint256 _allowance = s.allowances[ownerAddress_][spenderAddress_];
        require(
            _allowance >= amount_,
            "ERC20WithSubaccounts: Insufficient allowance"
        );

        s.allowances[ownerAddress_][spenderAddress_] -= amount_;

        return __transfer(ownerAddress_, spenderAddress_, amount_);
    }

    function transferFrom(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _ownerAddress = Lib.toAddress(ownerParentAddress_, msg.sender);
        address _spenderAddress = Lib.toAddress(
            spenderParentAddress_,
            spenderAddress_
        );

        emit InternalTransfer(_ownerAddress, _spenderAddress, amount_);
        return __transferFrom(_ownerAddress, _spenderAddress, amount_);
    }

    // ERC20 Transfer From
    function transferFrom(
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        address _ownerAddress = Lib.toAddress(address(this), msg.sender);
        address _spenderAddress = Lib.toAddress(address(this), spenderAddress_);

        emit Transfer(msg.sender, spenderAddress_, amount_);
        return __transferFrom(_ownerAddress, _spenderAddress, amount_);
    }
}
