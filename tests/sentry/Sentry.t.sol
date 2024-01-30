// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router, RouterLib as RL} from "@cavalre/router/Router.sol";
import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {Sentry, SentryLib as SL} from "@cavalre/sentry/Sentry.sol";
import {Test} from "forge-std/Test.sol";

contract SentryTest is Test {
    Router router;
    Sentry sentry;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    function setUp() public {
        vm.startPrank(alice);
        sentry = new Sentry();
        router = new Router();
        router.addModule(address(sentry));
    }

    function testSentryInit() public {
        assertEq(
            router.owner(address(router)),
            alice,
            "SentryTest: Owner not set"
        );
        assertEq(
            router.implementation(SL.TRANSFER_OWNERSHIP),
            address(sentry),
            "SentryTest: TransferOwnership not set"
        );
        assertEq(
            router.implementation(SL.ACCEPT_OWNERSHIP),
            address(sentry),
            "SentryTest: AcceptOwnership not set"
        );
        assertEq(
            router.implementation(SL.RENOUNCE_OWNERSHIP),
            address(sentry),
            "SentryTest: RenounceOwnership not set"
        );
        assertEq(
            router.implementation(SL.CONFIRM_RENOUNCE_OWNERSHIP),
            address(sentry),
            "SentryTest: ConfirmRenounceOwnership not set"
        );
    }

    function testSentryOwner() public {
        assertEq(router.owner(address(sentry)), alice);
    }

    function testSentryWrongOwner() public {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        router.addModule(address(sentry));
    }

    function testSentryTransferOwnership() public {
        vm.startPrank(alice);
        // Alice starts the transfer to Bob
        // emit log("Alice starts the transfer to Bob");
        (success, ) = address(router).call(
            abi.encodePacked(
                SL.TRANSFER_OWNERSHIP,
                abi.encode(address(router)),
                abi.encode(bob)
            )
        );
        require(success, "SentryTest: TransferOwnership failed");

        // Bob is now the pending owner
        // emit log("Verify Bob is now the pending owner");
        (success, data) = address(router).call(
            abi.encodePacked(SL.PENDING_OWNER, abi.encode(address(router)))
        );
        require(success, "SentryTest: PendingOwner failed");
        assertEq(abi.decode(data, (address)), bob);

        vm.startPrank(bob);
        // Bob accepts the transfer
        // emit log("Bob accepts the transfer");
        (success, ) = address(router).call(
            abi.encodePacked(SL.ACCEPT_OWNERSHIP, abi.encode(address(router)))
        );
        require(success, "SentryTest: AcceptOwnership failed");

        // Bob is now the owner
        // emit log("Verify Bob is now the owner");
        assertEq(router.owner(address(router)), bob);
    }
}
