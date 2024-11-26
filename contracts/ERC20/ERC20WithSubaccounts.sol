// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "@cavalre/contracts/router/Module.sol";

struct Store {
    mapping(bytes32 rootKey => string) name;
    mapping(bytes32 rootKey => string) symbol;
    mapping(bytes32 rootKey => uint8) decimals;
    mapping(bytes32 accountUserKey => uint256) balances;
    mapping(bytes32 accountKey => bytes32) parent;
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

    // Compute a unique key for storage
    function rootKey(address tokenAddress_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress_, "Root"));
    }

    // Compute a unique key for storage
    function accountKey(
        address tokenAddress_,
        string memory accountName_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress_, accountName_));
    }

    // Compute a unique key for storage
    function accountUserKey(
        address tokenAddress_,
        string memory accountName_,
        address userAddress_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(tokenAddress_, accountName_, userAddress_)
            );
    }

    // Compute a unique key for storage
    function allowanceKey(
        address tokenAddress_,
        string memory ownerAccountName_,
        address ownerAddress_,
        string memory spenderAccountName_,
        address spenderAddress_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    tokenAddress_,
                    ownerAccountName_,
                    ownerAddress_,
                    spenderAccountName_,
                    spenderAddress_
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

    // Set token metadata
    function setTokenMetadata(
        address tokenAddress_,
        string memory name_,
        string memory symbol_
    ) public {
        enforceIsOwner();
        Store storage s = Lib.store();

        bytes32 _rootKey = Lib.rootKey(tokenAddress_);
        s.name[_rootKey] = name_;
        s.symbol[_rootKey] = symbol_;
    }

    // Get token metadata
    function name(address tokenAddress_) public view returns (string memory) {
        Store storage s = Lib.store();
        bytes32 _rootKey = Lib.rootKey(tokenAddress_);
        return s.name[_rootKey];
    }

    // Get token metadata for ERC20 compatibility
    function name() public view returns (string memory) {
        return name(address(this));
    }

    // Get token metadata
    function symbol(address tokenAddress_) public view returns (string memory) {
        Store storage s = Lib.store();
        bytes32 _rootKey = Lib.rootKey(tokenAddress_);
        return s.symbol[_rootKey];
    }

    // Get token metadata for ERC20 compatibility
    function symbol() public view returns (string memory) {
        return symbol(address(this));
    }

    // Get token metadata
    function decimals(address tokenAddress_) public view returns (uint8) {
        Store storage s = Lib.store();
        bytes32 _rootKey = Lib.rootKey(tokenAddress_);
        return s.decimals[_rootKey];
    }

    // Get token metadata for ERC20 compatibility
    function decimals() public view returns (uint8) {
        return decimals(address(this));
    }

    // Add a subaccount with a parent
    function addSubaccount(
        address tokenAddress_,
        string memory parentName_,
        string memory accountName_
    ) public {
        enforceIsOwner();
        Store storage s = Lib.store();

        bytes32 _accountKey = Lib.accountKey(tokenAddress_, accountName_);
        if (s.balances[_accountKey] != 0) {
            revert("Account already exists");
        }
        bytes32 _parentKey = Lib.accountKey(tokenAddress_, parentName_);
        s.parent[_accountKey] = _parentKey;
    }

    // Get the balance of an account
    function balanceOf(
        address tokenAddress_,
        string memory accountName_,
        address ownerAddress_
    ) public view returns (uint256) {
        Store storage s = Lib.store();
        bytes32 _accountUserKey = Lib.accountUserKey(
            tokenAddress_,
            accountName_,
            ownerAddress_
        );
        return s.balances[_accountUserKey];
    }

    // Get the balance of an account (default to root subaccount for ERC20 compatibility)
    function balanceOf(address ownerAddress_) public view returns (uint256) {
        return balanceOf(address(this), "Root", ownerAddress_);
    }

    // Get the total balance of an account
    function totalBalanceOf(
        address tokenAddress_,
        string memory accountName_
    ) public view returns (uint256) {
        Store storage s = Lib.store();
        bytes32 _accountKey = Lib.accountKey(tokenAddress_, accountName_);
        return s.balances[_accountKey];
    }

    // Get the total supply of a token
    function totalSupply(address tokenAddress_) public view returns (uint256) {
        return totalBalanceOf(tokenAddress_, "Root");
    }

    // Get the total supply of a token for ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return totalSupply(address(this));
    }

    // Update parent balances recursively
    function updateParentBalances(
        bytes32 parentAccountKey_,
        int256 delta_
    ) internal {
        Store storage s = Lib.store();
        if (parentAccountKey_ == 0) {
            return;
        }
        int256 _newBalance = int256(s.balances[parentAccountKey_]) + delta_;
        if (_newBalance < 0) {
            revert("Insufficient balance");
        }
        s.balances[parentAccountKey_] = uint256(_newBalance);
        updateParentBalances(s.parent[parentAccountKey_], delta_);
    }

    // Transfer between subaccounts
    function transfer(
        address tokenAddress_,
        string memory fromAccountName_,
        string memory toAccountName_,
        address recipientAddress_,
        uint256 amount_
    ) public {
        Store storage s = Lib.store();

        bytes32 _fromAccountKey = Lib.accountKey(
            tokenAddress_,
            fromAccountName_
        );

        bytes32 _toAccountKey = Lib.accountKey(tokenAddress_, toAccountName_);

        bytes32 _fromAccountUserKey = Lib.accountUserKey(
            tokenAddress_,
            fromAccountName_,
            msg.sender
        );
        bytes32 _toAccountUserKey = Lib.accountUserKey(
            tokenAddress_,
            toAccountName_,
            recipientAddress_
        );

        require(
            s.balances[_fromAccountUserKey] >= amount_,
            "Insufficient balance"
        );

        s.balances[_fromAccountUserKey] -= amount_;
        s.balances[_toAccountUserKey] += amount_;

        updateParentBalances(s.parent[_fromAccountKey], -int256(amount_));
        updateParentBalances(s.parent[_toAccountKey], int256(amount_));

        emit Transfer(msg.sender, recipientAddress_, amount_);
    }

    // ERC20 Transfer
    function transfer(
        address recipientAddress_,
        uint256 amount_
    ) public returns (bool) {
        transfer(address(this), "Root", "Root", recipientAddress_, amount_);
        return true;
    }

    // Approve a spender for a subaccount
    function approve(
        address tokenAddress_,
        string memory ownerAccountName_,
        string memory spenderAccountName_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        Store storage s = Lib.store();

        bytes32 _allowanceKey = Lib.allowanceKey(
            tokenAddress_,
            ownerAccountName_,
            msg.sender,
            spenderAccountName_,
            spenderAddress_
        );
        s.allowances[_allowanceKey] = amount_;

        emit Approval(msg.sender, spenderAddress_, amount_);
        return true;
    }

    // ERC20 Approve
    function approve(address spender, uint256 amount) public returns (bool) {
        return approve(address(this), "Root", "Root", spender, amount);
    }

    // Allowance Query
    function allowance(
        address tokenAddress_,
        string memory ownerAccountName_,
        address ownerAddress_,
        string memory spenderAccountName_,
        address spenderAddress_
    ) public view returns (uint256) {
        Store storage s = Lib.store();

        bytes32 _allowanceKey = Lib.allowanceKey(
            tokenAddress_,
            ownerAccountName_,
            ownerAddress_,
            spenderAccountName_,
            spenderAddress_
        );
        return s.allowances[_allowanceKey];
    }

    // ERC20 Allowance Query
    function allowance(address spender) public view returns (uint256) {
        return allowance(address(this), "Root", msg.sender, "Root", spender);
    }

    // Transfer From
    function transferFrom(
        address tokenAddress_,
        string memory ownerAccountName_,
        string memory spenderAccountName_,
        address spenderAddress_,
        uint256 amount_
    ) public returns (bool) {
        Store storage s = Lib.store();

        bytes32 _ownerAccountUserKey = Lib.accountUserKey(
            tokenAddress_,
            ownerAccountName_,
            msg.sender
        );
        bytes32 _spenderAccountUserKey = Lib.accountUserKey(
            tokenAddress_,
            spenderAccountName_,
            spenderAddress_
        );

        bytes32 _allowanceKey = Lib.allowanceKey(
            tokenAddress_,
            ownerAccountName_,
            msg.sender,
            spenderAccountName_,
            spenderAddress_
        );

        require(
            s.balances[_ownerAccountUserKey] >= amount_,
            "Insufficient balance"
        );
        require(s.allowances[_allowanceKey] >= amount_, "Allowance exceeded");

        s.balances[_ownerAccountUserKey] -= amount_;
        s.balances[_spenderAccountUserKey] += amount_;
        s.allowances[_allowanceKey] -= amount_;

        updateParentBalances(s.parent[_ownerAccountUserKey], -int256(amount_));
        updateParentBalances(s.parent[_spenderAccountUserKey], int256(amount_));

        emit Transfer(msg.sender, spenderAddress_, amount_);
        return true;
    }

    // ERC20 Transfer From
    function transferFrom(
        address spender,
        uint256 amount
    ) public returns (bool) {
        return transferFrom(address(this), "Root", "Root", spender, amount);
    }
}
