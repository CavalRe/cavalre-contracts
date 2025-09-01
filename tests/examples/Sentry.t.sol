// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../modules/Router.sol";
import {Module, Lib as ML} from "../../modules/Module.sol";
import {Sentry, Lib as SL} from "../../examples/Sentry.sol";
import {Test} from "forge-std/src/Test.sol";

contract SentryTest is Test {
    Router router;
    Sentry sentry;

    address routerAddress;
    address sentryAddress;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    function setUp() public {
        vm.startPrank(alice);

        sentry = new Sentry();
        sentryAddress = address(sentry);

        router = new Router(alice);
        routerAddress = address(router);

        router.addModule(sentryAddress);

        sentry = Sentry(payable(router));
    }

    function testSentryInit() public view {
        assertEq(router.owner(address(router)), alice, "SentryTest: Owner not set");
        assertEq(router.module(SL.TRANSFER_OWNERSHIP), sentryAddress, "SentryTest: TransferOwnership not set");
        assertEq(router.module(SL.ACCEPT_OWNERSHIP), sentryAddress, "SentryTest: AcceptOwnership not set");
        assertEq(router.module(SL.RENOUNCE_OWNERSHIP), sentryAddress, "SentryTest: RenounceOwnership not set");
        assertEq(
            router.module(SL.CONFIRM_RENOUNCE_OWNERSHIP), sentryAddress, "SentryTest: ConfirmRenounceOwnership not set"
        );
    }

    function testSentryOwner() public view {
        assertEq(router.owner(sentryAddress), alice);
    }

    function testSentryWrongOwner() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(Module.OwnableUnauthorizedAccount.selector, bob));
        router.addModule(sentryAddress);
    }

    function testSentryTransferOwnership() public {
        vm.startPrank(alice);
        // emit log("Alice starts the transfer to Bob");
        sentry.transferOwnership(routerAddress, bob);

        // emit log("Verify Bob is now the pending owner");
        assertEq(sentry.pendingOwner(routerAddress), bob);

        vm.startPrank(bob);
        // emit log("Bob accepts the transfer");
        sentry.acceptOwnership(routerAddress);

        // emit log("Verify Bob is now the owner");
        assertEq(router.owner(routerAddress), bob);
    }
}
