// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {ERC20, ERC20Lib} from "../../contracts/ERC20/ERC20.sol";
import {ModuleLib} from "../../contracts/router/Module.sol";

import {Test, console} from "forge-std/src/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library TestTokenLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TOKEN =
        bytes4(keccak256("initializeTestToken(string,string)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract TestToken is ERC20 {

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    uint8 immutable private _decimals;

    constructor(uint8 _decimals_) {
        _decimals = _decimals_;
    }

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
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initializeTestToken(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
    }

    function mint(address _account, uint256 _amount) public {
        super._mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        super._burn(_account, _amount);
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

contract TestTokenTest is Test {
    TestToken token;
    Router router;

    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    function setUp() public {
        vm.startPrank(alice);
        token = new TestToken(18);
        router = new Router(alice);
        router.addModule(address(token));

        token = TestToken(payable(router));

        token.initializeTestToken("TestToken", "TOKEN");
    }

    function testTestTokenInitialize() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        token.initializeTestToken("TestToken", "TOKEN");

        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TOKEN");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(alice), 0);
    }

    function testTestTokenMint() public {
        vm.startPrank(alice);

        token.mint(bob, 1000);

        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(bob), 1000);
    }

    function testTestTokenBurn() public {
        vm.startPrank(alice);

        token.mint(bob, 1000);
        token.burn(bob, 700);

        assertEq(token.totalSupply(), 300);
        assertEq(token.balanceOf(bob), 300);
    }
}
