// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@cavalre/contracts/Initializable/Initializable.sol";

struct Store {
    mapping(address child => address) parent;
    mapping(address child => uint32) childIndex;
    mapping(address parent => address[]) children;
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;
    mapping(address => int256) balance;
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
    event ChildAdded(
        address indexed root,
        address indexed parent,
        address indexed child
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Custom errors
    error ApplicationNotFound(string appName);
    error ChildNotFound(address child);
    error HasBalance(string childName);
    error HasChild(string childName);
    error DifferentRoots(address a, address b);
    error DuplicateChild(address child);
    error InvalidAddress();
    error InvalidParent();
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
    bytes4 internal constant ADD_CHILD =
        bytes4(keccak256("addChild(address,address)"));
    bytes4 internal constant GET_NAME = bytes4(keccak256("name(address)"));
    bytes4 internal constant GET_SYMBOL = bytes4(keccak256("symbol(address)"));
    bytes4 internal constant GET_DECIMALS =
        bytes4(keccak256("decimals(address)"));
    bytes4 internal constant GET_PARENT = bytes4(keccak256("parent(address)"));
    bytes4 internal constant GET_CHILDREN =
        bytes4(keccak256("children(address)"));
    bytes4 internal constant GET_HAS_CHILD =
        bytes4(keccak256("hasChild(address)"));
    bytes4 internal constant GET_CHILD_INDEX =
        bytes4(keccak256("childIndex(address)"));
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

    //==================
    // Metadata Setters
    //==================
    function name(address accountAddress_, string memory name_) internal {
        store().name[accountAddress_] = name_;
    }

    function symbol(address accountAddress_, string memory symbol_) internal {
        store().symbol[accountAddress_] = symbol_;
    }

    function decimals(address accountAddress_, uint8 decimals_) internal {
        if (accountAddress_ == address(this)) revert InvalidAddress();
        store().decimals[accountAddress_] = decimals_;
    }

    //==================
    // Metadata Getters
    //==================
    function name(
        address accountAddress_
    ) internal view returns (string memory) {
        return store().name[accountAddress_];
    }

    function symbol(
        address accountAddress_
    ) internal view returns (string memory) {
        return store().symbol[root(accountAddress_)];
    }

    function decimals(address accountAddress_) internal view returns (uint8) {
        return store().decimals[root(accountAddress_)];
    }

    function root(address current_) internal view returns (address) {
        if (current_ == address(0)) revert InvalidAddress();

        Store storage s = store();
        uint256 _depth;
        while (_depth < MAX_DEPTH) {
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

    function parent(address child_) internal view returns (address) {
        return store().parent[child_];
    }

    function children(
        address parent_
    ) internal view returns (address[] memory) {
        return store().children[parent_];
    }

    function hasChild(address parent_) internal view returns (bool) {
        return store().children[parent_].length > 0;
    }

    function childIndex(address child_) internal view returns (uint32) {
        return store().childIndex[child_];
    }

    //==================================================================
    //                        Balance & Supply
    //==================================================================
    function balanceOfAbsoluteAddress(
        address absoluteAddress_
    ) internal view returns (uint256) {
        bool _isCredit = store().isCredit[absoluteAddress_];
        int256 _balance = store().balance[absoluteAddress_];
        return _isCredit ? uint256(-_balance) : uint256(_balance);
    }

    function totalSupply(
        address tokenAddress_
    ) internal view returns (uint256) {
        return
            balanceOfAbsoluteAddress(toAddress(tokenAddress_, TOTAL_ADDRESS));
    }

    function totalAppSupply(
        address tokenAddress_,
        string memory appName_
    ) internal view returns (uint256) {
        return
            balanceOfAbsoluteAddress(
                toAddress(
                    toAddress(tokenAddress_, TOTAL_ADDRESS),
                    toAddress(appName_)
                )
            );
    }

    function balanceOf(
        address parentAddress_,
        address ownerAddress_
    ) internal view returns (uint256) {
        return
            balanceOfAbsoluteAddress(toAddress(parentAddress_, ownerAddress_));
    }

    //==================================================================
    //                            Validation
    //==================================================================
    // Transfers can only occur within the same tree
    function checkRoots(address a_, address b_) internal view {
        if (root(a_) != root(b_)) revert DifferentRoots(a_, b_);
    }

    // Only leaf accounts can hold and transfer balances
    function checkChild(address parent_) internal view {
        if (hasChild(parent_)) revert HasChild(name(parent_));
    }

    //==================================================================
    //                         Tree Manipulation
    //==================================================================

    function addChild(
        string memory childName_,
        address parent_,
        address child_,
        bool isCredit_,
        bool includeChild_
    ) internal returns (address) {
        address _child = toAddress(parent_, child_);
        if (parent(_child) == parent_) return _child;
        if (parent_ == child_ || parent_ == address(0) || child_ == address(0))
            revert InvalidAddress();
        // Must build tree from the top down
        if (store().children[_child].length > 0) revert HasChild(childName_);
        // Only leaves can hold tokens
        if (store().balance[_child] != 0) revert HasBalance(childName_);

        store().name[_child] = childName_;
        store().parent[_child] = parent_;
        if (includeChild_) {
            store().children[parent_].push(child_);
            store().childIndex[_child] = uint32(
                store().children[parent_].length
            );
        }
        store().isCredit[_child] = isCredit_;
        address _root = root(_child);
        emit ChildAdded(_root, parent_, child_);
        return _child;
    }

    function addChild(
        string memory childName_,
        address parent_,
        address child_,
        bool isCredit_
    ) internal returns (address) {
        return addChild(childName_, parent_, child_, isCredit_, true);
    }

    function addChild(
        string memory childName_,
        address parent_,
        address child_
    ) internal returns (address) {
        return addChild(childName_, parent_, child_, false, true);
    }

    function removeChild(
        address parent_,
        address child_
    ) internal returns (address) {
        address _child = toAddress(parent_, child_);
        if (parent(_child) == address(0)) return _child;
        if (parent_ == child_ || parent_ == address(0) || child_ == address(0))
            revert InvalidAddress();
        if (store().parent[_child] != parent_) revert ChildNotFound(child_);
        if (hasChild(_child)) revert HasChild(name(_child));
        if (store().balance[_child] != 0)
            revert HasBalance(store().name[_child]);

        store().name[_child] = "";
        uint256 _index = store().childIndex[_child] - 1;
        address _lastChild = store().children[parent_][
            store().children[parent_].length - 1
        ];
        store().children[parent_][_index] = _lastChild;
        store().children[parent_].pop();
        store().childIndex[_lastChild] = uint32(_index + 1);

        store().parent[_child] = address(0);
        store().childIndex[_child] = 0;
        store().isCredit[_child] = false;
        return _child;
    }

    function addTokenSource(
        string memory sourceName_,
        address tokenAddress_
    ) internal {
        address _sourceAddress = toAddress(sourceName_);
        name(_sourceAddress, sourceName_);
        addChild(
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
        removeChild(toAddress(tokenAddress_, TOTAL_ADDRESS), _sourceAddress);
        emit SourceRemoved(sourceName_);
    }

    function sources(
        address tokenAddress_
    ) internal view returns (address[] memory) {
        return children(toAddress(tokenAddress_, TOTAL_ADDRESS));
    }

    function addToken(
        address tokenAddress_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        if (tokenAddress_ == address(this)) revert InvalidAddress();
        address _totalAbsoluteAddress = toAddress(tokenAddress_, TOTAL_ADDRESS);
        if (parent(_totalAbsoluteAddress) == tokenAddress_) return;

        name(tokenAddress_, name_);
        symbol(tokenAddress_, symbol_);
        decimals(tokenAddress_, decimals_);

        addChild("Total", tokenAddress_, TOTAL_ADDRESS, true, false);
        addChild(
            "Root",
            _totalAbsoluteAddress,
            ROOT_ADDRESS,
            true,
            false
        );
    }

    function updateBalances(
        address parent_,
        address current_,
        int256 delta_
    ) internal returns (address _root) {
        if (parent_ == address(0) || current_ == address(0))
            revert InvalidAddress();
        checkChild(current_);

        Store storage s = store();
        uint8 _depth;
        while (_depth < MAX_DEPTH) {
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

        int256 _amount = int256(amount_);
        updateBalances(fromParentAddress_, _fromAddress, -_amount);
        updateBalances(toParentAddress_, _toAddress, _amount);

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

        require(
            store().balance[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
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
        address _fromAddress = toAddress(address(this), msg.sender);

        require(
            store().balance[_fromAddress] >= int256(amount_),
            "ERC20WithSubaccounts: Insufficient balance"
        );
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

    function approve(
        address ownerParentAddress_,
        address ownerAddress_,
        address spenderParentAddress_,
        address spenderAddress_,
        uint256 amount_
    ) internal returns (bool) {
        address _ownerAddress = toAddress(ownerParentAddress_, ownerAddress_);
        checkChild(_ownerAddress);
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        checkChild(_spenderAddress);

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
        if (hasChild(_ownerAddress)) revert HasChild(name(_ownerAddress));
        address _spenderAddress = toAddress(
            spenderParentAddress_,
            spenderAddress_
        );
        if (hasChild(_spenderAddress)) revert HasChild(name(_spenderAddress));
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

contract Multitoken is Initializable {
    uint8 internal immutable _decimals;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
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
        _commands[7] = Lib.GET_PARENT;
        _commands[8] = Lib.GET_CHILDREN;
        _commands[9] = Lib.GET_HAS_CHILD;
        _commands[10] = Lib.GET_CHILD_INDEX;
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
        Store storage s = Lib.store();
        s.name[address(this)] = name_;
        s.symbol[address(this)] = symbol_;
        s.decimals[address(this)] = _decimals;

        name(address(this), name_);
        symbol(address(this), symbol_);

        Lib.addChild("Total", address(this), Lib.TOTAL_ADDRESS, true, false);
        Lib.addChild(
            "Root",
            Lib.toAddress(address(this), Lib.TOTAL_ADDRESS),
            Lib.ROOT_ADDRESS,
            true,
            false
        );
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
    function name(address accountAddress_, string memory name_) public {
        enforceIsOwner();
        Lib.name(accountAddress_, name_);
    }

    function symbol(address accountAddress_, string memory symbol_) public {
        enforceIsOwner();
        Lib.symbol(accountAddress_, symbol_);
    }

    //==================
    // Metadata Getters
    //==================
    function name(address accountAddress_) public view returns (string memory) {
        return Lib.name(accountAddress_);
    }

    function symbol(
        address accountAddress_
    ) public view returns (string memory) {
        return Lib.symbol(accountAddress_);
    }

    function decimals(address accountAddress_) public view returns (uint8) {
        return Lib.decimals(accountAddress_);
    }

    function root(address accountAddress_) public view returns (address) {
        return Lib.root(accountAddress_);
    }

    function parent(address child_) public view returns (address) {
        return Lib.parent(child_);
    }

    function children(address parent_) public view returns (address[] memory) {
        return Lib.children(parent_);
    }

    function hasChild(address parent_) public view returns (bool) {
        return Lib.hasChild(parent_);
    }

    function childIndex(address child_) public view returns (uint32) {
        return Lib.childIndex(child_);
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

    // Approve a spender for a subaccount
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
