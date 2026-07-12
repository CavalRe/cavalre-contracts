// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {Sentry, SentryLib} from "../../examples/Sentry.sol";
import {Test} from "forge-std/src/Test.sol";

contract SentryTest is Test {
    Dispatcher dispatcher;
    Sentry sentry;

    address dispatcherAddress;
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

        dispatcher = new Dispatcher(alice);
        dispatcherAddress = address(dispatcher);
        dispatcher.addModule(sentryAddress);

        sentry = Sentry(payable(dispatcher));
    }

    function testSentryInit() public view {
        assertEq(dispatcher.owner(address(dispatcher)), alice, "SentryTest: Owner not set");
        assertEq(dispatcher.module(SentryLib.TRANSFER_OWNERSHIP), sentryAddress, "SentryTest: TransferOwnership not set");
        assertEq(dispatcher.module(SentryLib.ACCEPT_OWNERSHIP), sentryAddress, "SentryTest: AcceptOwnership not set");
        assertEq(dispatcher.module(SentryLib.RENOUNCE_OWNERSHIP), sentryAddress, "SentryTest: RenounceOwnership not set");
        assertEq(
            dispatcher.module(SentryLib.CONFIRM_RENOUNCE_OWNERSHIP),
            sentryAddress,
            "SentryTest: ConfirmRenounceOwnership not set"
        );
    }

    function testSentryOwner() public view {
        assertEq(dispatcher.owner(sentryAddress), alice);
    }

    function testSentryWrongOwner() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, bob));
        dispatcher.addModule(sentryAddress);
    }

    function testSentryTransferOwnership() public {
        vm.startPrank(alice);
        // emit log("Alice starts the transfer to Bob");
        sentry.transferOwnership(dispatcherAddress, bob);

        // emit log("Verify Bob is now the pending owner");
        assertEq(sentry.pendingOwner(dispatcherAddress), bob);

        vm.startPrank(bob);
        // emit log("Bob accepts the transfer");
        sentry.acceptOwnership(dispatcherAddress);

        // emit log("Verify Bob is now the owner");
        assertEq(dispatcher.owner(dispatcherAddress), bob);
    }
}
