// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RouterTestLib} from "../router/Router.t.sol";
import {Router} from "../../contracts/router/Router.sol";
import {ERC20TestLib} from "./ERC20.t.sol";
import {ERC20, ERC20Lib, Store as ERC20Store} from "../../contracts/ERC20/ERC20.sol";
import {ModuleLib} from "../../contracts/router/Module.sol";

import {Test, console} from "forge-std/src/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library TestTokenLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TOKEN =
        bytes4(keccak256("initializeTestToken(string,string,uint8)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract TestToken is ERC20 {
    address private immutable __self = address(this);
    address private immutable __owner = msg.sender;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](12);
        _commands[0] = TestTokenLib.INITIALIZE_TOKEN;
        _commands[1] = ERC20Lib.NAME;
        _commands[2] = ERC20Lib.SYMBOL;
        _commands[3] = ERC20Lib.DECIMALS;
        _commands[4] = ERC20Lib.TOTAL_SUPPLY;
        _commands[5] = ERC20Lib.BALANCE_OF;
        _commands[6] = ERC20Lib.TRANSFER;
        _commands[7] = ERC20Lib.ALLOWANCE;
        _commands[7] = ERC20Lib.APPROVE;
        _commands[9] = ERC20Lib.TRANSFER_FROM;
        _commands[10] = TestTokenLib.MINT;
        _commands[11] = TestTokenLib.BURN;
    }

    // Commands
    function initializeTestToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        enforceIsOwner();
        __ERC20_init(_name, _symbol);
        ERC20Store storage s = ERC20Lib.store();
        s.decimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        ERC20Store storage s = ERC20Lib.store();
        return s.decimals;
    }

    function mint(address _account, uint256 _amount) public {
        enforceIsOwner();
        ERC20Lib.mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        enforceIsOwner();
        ERC20Lib.burn(_account, _amount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        mint(_msgSender(), msg.value);
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(_msgSender()) >= wad);
        burn(_msgSender(), wad);
        (bool success, ) = payable(_msgSender()).call{value: wad}("");
        require(success, "Transfer failed");
        emit Withdrawal(_msgSender(), wad);
    }
}

library TestTokenTestLib {
    using RouterTestLib for Router;

    function initializeTestToken(
        Router router_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        router_.call(TestTokenLib.INITIALIZE_TOKEN, abi.encode(name_, symbol_, decimals_));
    }

    function mint(
        Router router_,
        address account_,
        uint256 amount_
    ) internal {
        router_.call(TestTokenLib.MINT, abi.encode(account_, amount_));
    }

    function burn(
        Router router_,
        address account_,
        uint256 amount_
    ) internal {
        router_.call(TestTokenLib.BURN, abi.encode(account_, amount_));
    }
}

contract TestTokenTest is Test {
    using ERC20TestLib for Router;
    using TestTokenTestLib for Router;

    TestToken token;
    Router router;

    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    bytes4[] commands_;

    function setUp() public {
        vm.startPrank(alice);
        token = new TestToken();
        router = new Router();
        router.addModule(address(token));

        router.initializeTestToken("TestToken", "TOKEN", 18);
    }

    function testTestTokenInit() public {
        commands_ = router.getCommands(address(token));
        assertEq(
            router.module(commands_[0]),
            address(token),
            "TestTokenTest: Initialize not set"
        );
        assertEq(
            router.module(commands_[1]),
            address(token),
            "TestTokenTest: Name not set"
        );
        assertEq(
            router.module(commands_[2]),
            address(token),
            "TestTokenTest: Symbol not set"
        );
        assertEq(
            router.module(commands_[3]),
            address(token),
            "TestTokenTest: Decimals not set"
        );
        assertEq(
            router.module(commands_[4]),
            address(token),
            "TestTokenTest: TotalSupply not set"
        );
        assertEq(
            router.module(commands_[5]),
            address(token),
            "TestTokenTest: BalanceOf not set"
        );
        assertEq(
            router.module(commands_[6]),
            address(token),
            "TestTokenTest: Transfer not set"
        );
        assertEq(
            router.module(commands_[7]),
            address(token),
            "TestTokenTest: TransferFrom not set"
        );
        assertEq(
            router.module(commands_[8]),
            address(token),
            "TestTokenTest: Approve not set"
        );
        assertEq(
            router.module(commands_[9]),
            address(token),
            "TestTokenTest: Allowance not set"
        );
        assertEq(
            router.module(commands_[10]),
            address(token),
            "TestTokenTest: Mint not set"
        );
        assertEq(
            router.module(commands_[11]),
            address(token),
            "TestTokenTest: Burn not set"
        );

        // commands_ = router.getCommands(address(factory));
        // assertEq(
        //     router.module(commands_[0]),
        //     address(factory),
        //     "TestTokenTest: Create not set"
        // );
    }

    function testTestTokenInitialize() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        router.initializeTestToken("TestToken", "TOKEN", 18);

        assertEq(router.name(), "TestToken");
        assertEq(router.symbol(), "TOKEN");
        assertEq(router.decimals(), 18);
        assertEq(router.totalSupply(), 0);
        assertEq(router.balanceOf(alice), 0);
    }

    function testTestTokenMint() public {
        vm.startPrank(alice);

        router.mint(bob, 1000);

        assertEq(router.totalSupply(), 1000);
        assertEq(router.balanceOf(bob), 1000);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleLib.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        router.mint(bob, 1000);
    }

    function testTestTokenBurn() public {
        vm.startPrank(alice);

        router.mint(bob, 1000);
        router.burn(bob, 700);

        assertEq(router.totalSupply(), 300);
        assertEq(router.balanceOf(bob), 300);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleLib.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        router.burn(bob, 300);
    }
}
