// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib} from "./FloatLib.sol";

library RandomLib {
    using FloatLib for Float;

    struct Store {
        uint256 seed;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Random")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ==================================================
    // Pure functions to derive a Float from a given seed
    // ==================================================
    function nextSeed(uint256 seed_) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed_)));
    }

    function random(uint256 seed_) internal pure returns (Float) {
        int80 _rand = int80(int256(seed_));

        int256 _mantissa = int256(int72(_rand));
        int256 _exponent = int256(_rand >> FloatLib.MANTISSA_BITS);

        return FloatLib.normalize(_mantissa, _exponent);
    }

    function randomPositive(uint256 seed_) internal pure returns (Float) {
        Float _f = random(seed_);
        return _f.abs(); // ensures mantissa >= 0
    }

    // Pseudo‑uniform Float in [0,1]
    function randomUnit(uint256 seed_) internal pure returns (Float) {
        uint256 _mantissa = seed_ % (1e18 + 1); // 0..1e18 inclusive
        return FloatLib.toFloat(_mantissa, 18);
    }

    function randomInterval(uint256 seed_, Float low_, Float high_) internal pure returns (Float) {
        // Ensure bounds are ordered
        if (low_.isGT(high_)) (low_, high_) = (high_, low_);

        Float _span = high_.minus(low_);
        Float _u = randomUnit(seed_); // in [0,1]
        return low_.plus(_span.times(_u)); // in [low, high]
    }

    function randomUnitNormal(uint256 seed_) internal pure returns (Float, uint256) {
        Float z1;
        Float z2;
        while (true) {
            // Sample (-1,1)
            Float u = randomInterval(seed_, FloatLib.ONE.minus(), FloatLib.ONE);
            uint256 nextSeed_ = nextSeed(seed_);
            Float v = randomInterval(nextSeed_, FloatLib.ONE.minus(), FloatLib.ONE);

            Float s = u.times(u).plus(v.times(v));

            // Reject if s == 0 or s >= 1
            if (s.isZero() || !s.isLT(FloatLib.ONE)) {
                seed_ = nextSeed(nextSeed_);
                continue;
            }

            // factor = sqrt(-2 * ln(s) / s)
            Float factor = (FloatLib.TWO.minus().times(s.log()).divide(s)).sqrt();

            z1 = u.times(factor);
            z2 = v.times(factor);
            break;
        }
        return (z1, seed_);
    }

    function randomNormal(uint256 seed_, Float mean_, Float stddev_) internal pure returns (Float, uint256) {
        (Float z, uint256 nextSeed_) = randomUnitNormal(seed_);
        Float value = mean_.plus(z.times(stddev_));
        return (value, nextSeed_);
    }

    function randomLogNormal(uint256 seed_, Float mean_, Float stddev_) internal pure returns (Float, uint256) {
        (Float normalValue, uint256 nextSeed_) = randomNormal(seed_, mean_, stddev_);
        Float logNormalValue = normalValue.exp();
        return (logNormalValue, nextSeed_);
    }

    // ==============================================
    // Stateful functions that update the stored seed
    // ==============================================

    function random() internal returns (Float) {
        store().seed = nextSeed(store().seed);
        return random(store().seed);
    }

    function randomPositive() internal returns (Float) {
        store().seed = nextSeed(store().seed);
        return randomPositive(store().seed);
    }

    function randomUnit() internal returns (Float) {
        store().seed = nextSeed(store().seed);
        return randomUnit(store().seed);
    }

    function randomInterval(Float low, Float high) internal returns (Float) {
        store().seed = nextSeed(store().seed);
        return randomInterval(store().seed, low, high);
    }

    function randomUnitNormal() internal returns (Float _float) {
        uint256 _seed = nextSeed(store().seed);
        (_float, _seed) = randomUnitNormal(_seed);
        store().seed = _seed;
        return _float;
    }

    function randomNormal(Float mean, Float stddev) internal returns (Float _float) {
        uint256 _seed = nextSeed(store().seed);
        (_float, _seed) = randomNormal(_seed, mean, stddev);
        store().seed = _seed;
        return _float;
    }

    function randomLogNormal(Float mean, Float stddev) internal returns (Float _float) {
        uint256 _seed = nextSeed(store().seed);
        (_float, _seed) = randomLogNormal(_seed, mean, stddev);
        store().seed = _seed;
        return _float;
    }
}
