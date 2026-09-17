// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";

contract LedgerKindHarness {
    function pack(LedgerLib.TokenKind kind_, address metadata_, uint8 depth_) external pure returns (uint256) {
        return LedgerLib.flags(metadata_, LedgerLib.AccountKind.DebitGroup, kind_, depth_);
    }

    function kind(uint256 flags_) external pure returns (LedgerLib.TokenKind) {
        return LedgerLib.tokenKind(flags_);
    }
}

contract LedgerFlagsTest is Test {
    LedgerKindHarness internal harness_ = new LedgerKindHarness();

    function testFuzzTypedKindPacking(uint8 kind_, address metadata_, uint8 depth_) public view {
        LedgerLib.TokenKind expected_ = LedgerLib.TokenKind(kind_ % 4);
        uint256 flags_ = harness_.pack(expected_, metadata_, depth_);
        LedgerLib.TokenKind actual_ = harness_.kind(flags_);
        assertEq(uint8(actual_), uint8(expected_));
        assertEq(LedgerLib.packedAddress(flags_), metadata_);
        assertEq(LedgerLib.depth(flags_), depth_);
        assertEq(LedgerLib.isNative(flags_), expected_ == LedgerLib.TokenKind.Native);
        assertEq(LedgerLib.isExternal(flags_), expected_ == LedgerLib.TokenKind.External);
        assertEq(LedgerLib.isInternal(flags_), expected_ == LedgerLib.TokenKind.Internal);
        assertEq(LedgerLib.isUnregisteredToken(flags_), expected_ == LedgerLib.TokenKind.Unregistered);
    }

    function testUndefinedTokenKindRejected() public {
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x21));
        harness_.kind(4 << 3);
    }

    function testInvalidEnumArgumentRejected() public {
        (bool success_,) = address(harness_).call(abi.encodeWithSelector(harness_.pack.selector, 4, address(0), 2));
        assertFalse(success_);
    }
}
