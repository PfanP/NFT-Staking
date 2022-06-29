// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract PriceOracleMock {
    /**
      * @param _nftTokenAddress NFT token address
      * @param _tokenId NFT token id
     */
    function getPrice(address _nftTokenAddress, uint256 _tokenId) external returns (uint256) {
        if (block.timestamp % 22 > 12) {
            return 1;
        } else {
            return 2;
        }
    }
}