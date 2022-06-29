//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {

    /// @param _stakingAddress NFT staking contract address
    constructor(address _stakingAddress) ERC20("RewardToken", "RTOKEN") Ownable() {
        transferOwnership(_stakingAddress);
    }

    /// @dev mint _amount of token to _to address. Must be called by only staking contract
    /// @param _to token minting address
    /// @param _amount mint token amount
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}