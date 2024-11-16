// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IStETH {
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function sharesOf(address _account) external view returns (uint256);
}