// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "@cavalre/contracts/router/Module.sol";

struct Store {
    mapping(address accountAddress => address) parent;
    mapping(address accountAddress => string) name;
    mapping(address accountAddress => string) symbol;
    mapping(address accountAddress => uint8) decimals;
    mapping(address accountUserAddress => uint256) balances;
    mapping(bytes32 allowanceKey => uint256) allowances;
}

library Lib {
    // Selectors
    bytes4 internal constant SET_TOKEN_METADATA =
        bytes4(keccak256("setTokenMetadata(address,string,string)"));
    bytes4 internal constant NAME = bytes4(keccak256("name()"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant TOTAL_SUPPLY =
        bytes4(keccak256("totalSupply(address)"));
    bytes4 internal constant BALANCE_OF =
        bytes4(keccak256("balanceOf(address,address,address)"));
    bytes4 internal constant TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant ALLOWANCE =
        bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,uint256)"));

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
    // Events for ERC20 compatibility
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](10);
        _commands[0] = Lib.NAME;
        _commands[1] = Lib.SYMBOL;
        _commands[2] = Lib.DECIMALS;
        _commands[3] = Lib.TOTAL_SUPPLY;
        _commands[4] = Lib.BALANCE_OF;
        _commands[5] = Lib.TRANSFER;
        _commands[6] = Lib.APPROVE;
        _commands[7] = Lib.ALLOWANCE;
        _commands[8] = Lib.TRANSFER_FROM;
        _commands[9] = Lib.SET_TOKEN_METADATA;
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

    function decimals(address accountAddress_, uint8 decimals_) public {
        enforceIsOwner();
        Store storage s = Lib.store();
        s.decimals[accountAddress_] = decimals_;
    }

    //==================
    // Metadata Getters
    //==================
    function name(
        address accountAddress_
    ) internal view returns (string memory) {
        return Lib.store().name[accountAddress_];
    }

    function symbol(
        address accountAddress_
    ) public view returns (string memory) {
        return Lib.store().symbol[accountAddress_];
    }

    function decimals(address accountAddress_) public view returns (uint8) {
        return Lib.store().decimals[accountAddress_];
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
    function balanceOf(address accountAddress_) public view returns (uint256) {
        Store storage s = Lib.store();
        return s.balances[accountAddress_];
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return balanceOf(address(this));
    }

    // Update parent balances recursively
    function updateParentBalances(
        address parentAccountAddress_,
        int256 delta_
    ) internal returns (address) {
        if (parentAccountAddress_ == address(0)) revert("Invalid parent");

        Store storage s = Lib.store();

        if (s.parent[parentAccountAddress_] != address(0)) {
            int256 _newBalance = int256(s.balances[parentAccountAddress_]) +
                delta_;
            if (_newBalance < 0) {
                revert("Insufficient balance");
            }
            s.balances[parentAccountAddress_] = uint256(_newBalance);

            updateParentBalances(s.parent[parentAccountAddress_], delta_);
        }

        return parentAccountAddress_;
    }

    function transfer(
        address fromParentAddress_,
        address fromAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _fromRoot = updateParentBalances(
            fromParentAddress_,
            -int256(amount_)
        );
        address _toRoot = updateParentBalances(
            toParentAddress_,
            int256(amount_)
        );
        if (_fromRoot != _toRoot)
            revert("ERC20WithSubaccounts: Different roots");

        Store storage s = Lib.store();

        address _fromAddress = Lib.toAddress(fromParentAddress_, fromAddress_);
        address _toAddress = Lib.toAddress(toParentAddress_, toAddress_);

        require(
            s.balances[_fromAddress] >= amount_,
            "ERC20WithSubaccounts: Insufficient balance"
        );

        s.balances[_fromAddress] -= amount_;
        s.balances[_toAddress] += amount_;

        emit Transfer(msg.sender, toAddress_, amount_);
        return true;
    }

    function transfer(
        address fromParentAddress_,
        address toParentAddress_,
        address toAddress_,
        uint256 amount_
    ) public returns (bool) {
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
    ) public returns (bool) {
        return
            transfer(
                address(this),
                msg.sender,
                address(this),
                recipientAddress_,
                amount_
            );
    }

    // Approve a spender for a subaccount
    function approve(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        Store storage s = Lib.store();

        bytes32 _allowanceKey = keccak256(
            abi.encodePacked(
                ownerParentAddress_,
                msg.sender,
                spenderParentAddress_,
                spenderAddress_
            )
        );

        s.allowances[_allowanceKey] = amount_;

        emit Approval(msg.sender, spenderAddress_, amount_);
        return true;
    }

    // ERC20 Approve
    function approve(address spender_, uint256 amount_) public returns (bool) {
        return approve(address(this), address(this), spender_, amount_);
    }

    // Allowance Query
    function allowance(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_
    ) public view returns (uint256) {
        Store storage s = Lib.store();

        bytes32 _allowanceKey = keccak256(
            abi.encodePacked(
                ownerParentAddress_,
                msg.sender,
                spenderParentAddress_,
                spenderAddress_
            )
        );
        return s.allowances[_allowanceKey];
    }

    // ERC20 Allowance Query
    function allowance(address spenderAddress_) public view returns (uint256) {
        return allowance(address(this), address(this), spenderAddress_);
    }

    // Transfer From
    function transferFrom(
        address ownerParentAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        Store storage s = Lib.store();

        bytes32 _allowanceKey = keccak256(
            abi.encodePacked(
                ownerParentAddress_,
                msg.sender,
                spenderParentAddress_,
                spenderAddress_
            )
        );

        uint256 _allowance = s.allowances[_allowanceKey];
        require(
            _allowance >= amount_,
            "ERC20WithSubaccounts: Insufficient allowance"
        );

        s.allowances[_allowanceKey] = _allowance - amount_;

        return
            transfer(
                ownerParentAddress_,
                msg.sender,
                spenderParentAddress_,
                spenderAddress_,
                amount_
            );
    }

    // ERC20 Transfer From
    function transferFrom(
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        return
            transferFrom(
                address(this),
                address(this),
                spenderAddress_,
                amount_
            );
    }
}
