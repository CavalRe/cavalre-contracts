// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";

contract StorageSlotsTest is Test {
    function testProductionStorageSlotsAreUnique() public pure {
        bytes32[] memory slots_ = new bytes32[](5);
        slots_[0] = _erc7201("cavalre.storage.Dispatcher");
        slots_[1] = _erc7201("cavalre.storage.Ledger");
        slots_[2] = _erc7201("cavalre.storage.Ledger.Initializable");
        slots_[3] = _erc7201("cavalre.storage.Ledger.ReentrancyGuard");
        slots_[4] = _erc7201("cavalre.storage.Random");

        for (uint256 i_; i_ < slots_.length; i_++) {
            for (uint256 j_ = i_ + 1; j_ < slots_.length; j_++) {
                assertTrue(slots_[i_] != slots_[j_], "duplicate storage slot");
            }
        }
    }

    function _erc7201(string memory label_) private pure returns (bytes32) {
        return keccak256(abi.encode(uint256(keccak256(bytes(label_))) - 1)) & ~bytes32(uint256(0xff));
    }
}
