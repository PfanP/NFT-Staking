//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRewardToken {
    function mint(address, uint256) external;
}