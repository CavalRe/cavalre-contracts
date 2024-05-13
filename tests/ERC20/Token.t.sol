// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RouterTest} from "../router/Router.t.sol";
import {IRouter, Router} from "../../contracts/router/Router.sol";
import {ERC20, ERC20Lib, Store as ERC20Store} from "../../contracts/ERC20/ERC20.sol";
import {ModuleLib} from "../../contracts/router/Module.sol";

import {Test, console} from "forge-std/src/Test.sol";

library TokenLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TOKEN =
        bytes4(keccak256("initializeToken(string,string,uint8)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract Token is ERC20 {
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
        _commands[0] = TokenLib.INITIALIZE_TOKEN;
        _commands[1] = ERC20Lib.NAME;
        _commands[2] = ERC20Lib.SYMBOL;
        _commands[3] = ERC20Lib.DECIMALS;
        _commands[4] = ERC20Lib.TOTAL_SUPPLY;
        _commands[5] = ERC20Lib.BALANCE_OF;
        _commands[6] = ERC20Lib.TRANSFER;
        _commands[7] = ERC20Lib.ALLOWANCE;
        _commands[7] = ERC20Lib.APPROVE;
        _commands[9] = ERC20Lib.TRANSFER_FROM;
        _commands[10] = TokenLib.MINT;
        _commands[11] = TokenLib.BURN;
    }

    // Commands
    function initializeToken(
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

contract TokenTest is RouterTest, Token {
    Token token;
    Router router;

    bytes4[] commands_;

    function setUp() public {
        vm.startPrank(alice);
        token = new Token();
        router = new Router();
        router.addModule(address(token));

        call(router, TokenLib.INITIALIZE_TOKEN, abi.encode("Token", "TOKEN", 18));
    }

    function testTokenInit() public {
        commands_ = router.getCommands(address(token));
        assertEq(
            router.module(commands_[0]),
            address(token),
            "TokenTest: Initialize not set"
        );
        assertEq(
            router.module(commands_[1]),
            address(token),
            "TokenTest: Name not set"
        );
        assertEq(
            router.module(commands_[2]),
            address(token),
            "TokenTest: Symbol not set"
        );
        assertEq(
            router.module(commands_[3]),
            address(token),
            "TokenTest: Decimals not set"
        );
        assertEq(
            router.module(commands_[4]),
            address(token),
            "TokenTest: TotalSupply not set"
        );
        assertEq(
            router.module(commands_[5]),
            address(token),
            "TokenTest: BalanceOf not set"
        );
        assertEq(
            router.module(commands_[6]),
            address(token),
            "TokenTest: Transfer not set"
        );
        assertEq(
            router.module(commands_[7]),
            address(token),
            "TokenTest: TransferFrom not set"
        );
        assertEq(
            router.module(commands_[8]),
            address(token),
            "TokenTest: Approve not set"
        );
        assertEq(
            router.module(commands_[9]),
            address(token),
            "TokenTest: Allowance not set"
        );
        assertEq(
            router.module(commands_[10]),
            address(token),
            "TokenTest: Mint not set"
        );
        assertEq(
            router.module(commands_[11]),
            address(token),
            "TokenTest: Burn not set"
        );

        // commands_ = router.getCommands(address(factory));
        // assertEq(
        //     router.module(commands_[0]),
        //     address(factory),
        //     "TokenTest: Create not set"
        // );
    }

    function testTokenInitialize() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        call(router, TokenLib.INITIALIZE_TOKEN, abi.encode("Token", "TOKEN", 18));

        call(router, ERC20Lib.NAME, abi.encode(address(token)));
        assertEq(abi.decode(data, (string)), "Token");

        call(router, ERC20Lib.SYMBOL, abi.encode(address(token)));
        assertEq(abi.decode(data, (string)), "TOKEN");

        call(router, ERC20Lib.DECIMALS, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint8)), 18);

        call(router, ERC20Lib.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 0);

        call(router, ERC20Lib.BALANCE_OF, abi.encode(address(token), alice));
        assertEq(abi.decode(data, (uint256)), 0);
    }

    function testTokenMint() public {
        vm.startPrank(alice);

        call(router, TokenLib.MINT, abi.encode(bob, 1000));

        call(router, ERC20Lib.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 1000);

        call(router, ERC20Lib.BALANCE_OF, abi.encode(bob));
        assertEq(abi.decode(data, (uint256)), 1000);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleLib.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        call(router, TokenLib.MINT, abi.encode(bob, 1000));
    }

    function testTokenBurn() public {
        vm.startPrank(alice);

        call(router, TokenLib.MINT, abi.encode(bob, 1000));

        call(router, TokenLib.BURN, abi.encode(bob, 700));

        call(router, ERC20Lib.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 300);

        call(router, ERC20Lib.BALANCE_OF, abi.encode(bob));
        assertEq(abi.decode(data, (uint256)), 300);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ModuleLib.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        call(router, TokenLib.BURN, abi.encode(bob, 300));
    }
}
