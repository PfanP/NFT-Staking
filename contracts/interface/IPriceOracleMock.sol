// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPriceOracleMock {
    function getPrice(address, uint256) external returns (uint256);
}