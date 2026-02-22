// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library UtilityLib {
    uint256 internal constant ERC_7201_SLOT_MASK = 0xff;

    function erc7201Slot(string memory namespace_) internal pure returns (bytes32) {
        return keccak256(abi.encode(uint256(keccak256(bytes(namespace_))) - 1))
            & ~bytes32(uint256(ERC_7201_SLOT_MASK));
    }

    function isZeroAddress(address addr_) internal pure returns (bool) {
        return addr_ == address(0);
    }

    function hasLengthInRange(string memory value_, uint256 min_, uint256 max_) internal pure returns (bool) {
        uint256 length = bytes(value_).length;
        return length >= min_ && length <= max_;
    }

    function hasLengthInRange(bytes memory value_, uint256 min_, uint256 max_) internal pure returns (bool) {
        uint256 length = value_.length;
        return length >= min_ && length <= max_;
    }

    function selector(string memory signature_) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(signature_)));
    }
}
