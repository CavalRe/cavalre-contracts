// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);
}