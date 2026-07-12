// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library MemoryLib {
    error DuplicateAddress(address addr_);
    error ZeroAddress();

    struct AddressSet {
        address[] slots;
        uint256 mask;
    }

    struct AddressDict {
        address[] keys;
        uint256[] values;
        uint256 mask;
    }

    // -- Constructors --

    function addressSet(uint256 n_) internal pure returns (AddressSet memory set_) {
        uint256 _size = 1;
        while (_size < n_ * 2) _size <<= 1;
        set_.slots = new address[](_size);
        set_.mask = _size - 1;
    }

    function addressDict(uint256 n_) internal pure returns (AddressDict memory dict_) {
        uint256 _size = 1;
        while (_size < n_ * 2) _size <<= 1;
        dict_.keys = new address[](_size);
        dict_.values = new uint256[](_size);
        dict_.mask = _size - 1;
    }

    // -- AddressSet --

    function insert(AddressSet memory set_, address addr_) internal pure {
        if (addr_ == address(0)) revert ZeroAddress();

        uint256 _idx;
        assembly ("memory-safe") {
            mstore(0x00, addr_)
            _idx := and(keccak256(0x00, 0x20), mload(add(set_, 0x20)))
        }

        while (true) {
            address _slot = set_.slots[_idx];
            if (_slot == address(0)) {
                set_.slots[_idx] = addr_;
                return;
            }
            if (_slot == addr_) revert DuplicateAddress(addr_);
            unchecked {
                _idx = (_idx + 1) & set_.mask;
            }
        }
    }

    function contains(AddressSet memory set_, address addr_) internal pure returns (bool) {
        if (addr_ == address(0)) return false;

        uint256 _idx;
        assembly ("memory-safe") {
            mstore(0x00, addr_)
            _idx := and(keccak256(0x00, 0x20), mload(add(set_, 0x20)))
        }

        while (true) {
            address _slot = set_.slots[_idx];
            if (_slot == address(0)) return false;
            if (_slot == addr_) return true;
            unchecked {
                _idx = (_idx + 1) & set_.mask;
            }
        }

        return false;
    }

    // -- AddressDict --

    function set(AddressDict memory dict_, address key_, uint256 value_) internal pure {
        if (key_ == address(0)) revert ZeroAddress();

        uint256 _idx;
        assembly ("memory-safe") {
            mstore(0x00, key_)
            _idx := and(keccak256(0x00, 0x20), mload(add(dict_, 0x40)))
        }

        while (true) {
            address _key = dict_.keys[_idx];
            if (_key == address(0) || _key == key_) {
                dict_.keys[_idx] = key_;
                dict_.values[_idx] = value_;
                return;
            }
            unchecked {
                _idx = (_idx + 1) & dict_.mask;
            }
        }
    }

    function get(AddressDict memory dict_, address key_) internal pure returns (bool found_, uint256 value_) {
        if (key_ == address(0)) return (false, 0);

        uint256 _idx;
        assembly ("memory-safe") {
            mstore(0x00, key_)
            _idx := and(keccak256(0x00, 0x20), mload(add(dict_, 0x40)))
        }

        while (true) {
            address _key = dict_.keys[_idx];
            if (_key == address(0)) return (false, 0);
            if (_key == key_) return (true, dict_.values[_idx]);
            unchecked {
                _idx = (_idx + 1) & dict_.mask;
            }
        }
    }
}
