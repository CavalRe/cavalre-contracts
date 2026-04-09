// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {MemoryLib} from "../../libraries/MemoryLib.sol";

contract MemoryLibTest is Test {
    using MemoryLib for MemoryLib.AddressSet;
    using MemoryLib for MemoryLib.AddressDict;

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant CAROL = address(0xCA401);
    address internal constant DAVE = address(0xDA7E);

    function insertAddress(MemoryLib.AddressSet memory set_, address addr_) external pure {
        set_.insert(addr_);
    }

    function setAddressValue(MemoryLib.AddressDict memory dict_, address addr_, uint256 value_) external pure {
        dict_.set(addr_, value_);
    }

    function testAddressSetInsertAndContains() public pure {
        MemoryLib.AddressSet memory _set = MemoryLib.addressSet(4);

        _set.insert(ALICE);
        _set.insert(BOB);
        _set.insert(CAROL);

        assertTrue(_set.contains(ALICE));
        assertTrue(_set.contains(BOB));
        assertTrue(_set.contains(CAROL));
        assertFalse(_set.contains(DAVE));
        assertFalse(_set.contains(address(0)));
    }

    function testAddressSetRejectsDuplicate() public {
        MemoryLib.AddressSet memory _set = MemoryLib.addressSet(2);

        _set.insert(ALICE);

        vm.expectRevert(abi.encodeWithSelector(MemoryLib.DuplicateAddress.selector, ALICE));
        this.insertAddress(_set, ALICE);
    }

    function testAddressSetRejectsZeroAddress() public {
        MemoryLib.AddressSet memory _set = MemoryLib.addressSet(1);

        vm.expectRevert(MemoryLib.ZeroAddress.selector);
        this.insertAddress(_set, address(0));
    }

    function testAddressDictSetAndGet() public pure {
        MemoryLib.AddressDict memory _dict = MemoryLib.addressDict(4);

        _dict.set(ALICE, 11);
        _dict.set(BOB, 22);
        _dict.set(CAROL, 33);

        (bool _foundA, uint256 _valueA) = _dict.get(ALICE);
        (bool _foundB, uint256 _valueB) = _dict.get(BOB);
        (bool _foundC, uint256 _valueC) = _dict.get(CAROL);
        (bool _foundD, uint256 _valueD) = _dict.get(DAVE);

        assertTrue(_foundA);
        assertEq(_valueA, 11);
        assertTrue(_foundB);
        assertEq(_valueB, 22);
        assertTrue(_foundC);
        assertEq(_valueC, 33);
        assertFalse(_foundD);
        assertEq(_valueD, 0);
    }

    function testAddressDictSetOverwritesExistingValue() public pure {
        MemoryLib.AddressDict memory _dict = MemoryLib.addressDict(2);

        _dict.set(ALICE, 11);
        _dict.set(ALICE, 99);

        (bool _found, uint256 _value) = _dict.get(ALICE);
        assertTrue(_found);
        assertEq(_value, 99);
    }

    function testAddressDictRejectsZeroAddress() public {
        MemoryLib.AddressDict memory _dict = MemoryLib.addressDict(1);

        vm.expectRevert(MemoryLib.ZeroAddress.selector);
        this.setAddressValue(_dict, address(0), 1);
    }
}
