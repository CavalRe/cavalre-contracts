// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "@cavalre/router/Router.sol";
import {Module} from "@cavalre/router/Module.sol";
import {Sentry} from "@cavalre/sentry/Sentry.sol";
import {Test} from "forge-std/Test.sol";

contract SentryTest is Test {
    // Commands
    bytes4 internal constant TRANSFER_OWNERSHIP =
        bytes4(keccak256("transferOwnership(address)"));
    bytes4 internal constant ACCEPT_OWNERSHIP =
        bytes4(keccak256("acceptOwnership()"));
    bytes4 internal constant RENOUNCE_OWNERSHIP =
        bytes4(keccak256("renounceOwnership()"));
    bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP =
        bytes4(keccak256("confirmRenounceOwnership()"));
    bytes4 internal constant OWNER = bytes4(keccak256("owner()"));
    bytes4 internal constant PENDING_OWNER =
        bytes4(keccak256("pendingOwner()"));

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
        assertEq(router.owner(), alice, "SentryTest: Owner not set");
        assertEq(
            router.module(TRANSFER_OWNERSHIP),
            address(sentry),
            "SentryTest: TransferOwnership not set"
        );
        assertEq(
            router.module(ACCEPT_OWNERSHIP),
            address(sentry),
            "SentryTest: AcceptOwnership not set"
        );
        assertEq(
            router.module(RENOUNCE_OWNERSHIP),
            address(sentry),
            "SentryTest: RenounceOwnership not set"
        );
        assertEq(
            router.module(CONFIRM_RENOUNCE_OWNERSHIP),
            address(sentry),
            "SentryTest: ConfirmRenounceOwnership not set"
        );
    }

    function testSentryOwner() public {
        (success, data) = address(router).call(abi.encodePacked(OWNER));
        require(success, "SentryTest: Owner failed");
        assertEq(abi.decode(data, (address)), alice);
    }

    function testSentryWrongOwner() public {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Module.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        router.addModule(address(sentry));
    }

    function testSentryTransferOwnership() public {
        vm.startPrank(alice);
        // Alice starts the transfer to Bob
        (success, ) = address(router).call(
            abi.encodePacked(TRANSFER_OWNERSHIP, abi.encode(bob))
        );
        require(success, "SentryTest: TransferOwnership failed");

        // Bob is now the pending owner
        (success, data) = address(router).call(
            abi.encodePacked(PENDING_OWNER)
        );
        require(success, "SentryTest: PendingOwner failed");
        assertEq(abi.decode(data, (address)), bob);

        vm.startPrank(bob);
        // Bob accepts the transfer
        (success, ) = address(router).call(abi.encodePacked(ACCEPT_OWNERSHIP));
        require(success, "SentryTest: AcceptOwnership failed");

        // Bob is now the owner
        (success, data) = address(router).call(abi.encodePacked(OWNER));
        require(success, "SentryTest: Owner failed");
        assertEq(abi.decode(data, (address)), bob);
    }
}
