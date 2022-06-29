import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { NFTStaking, RewardToken, StakeNFT } from "../typechain";

describe("NFT staking", function () {
  let nftStaking: NFTStaking, stakeNFT: StakeNFT, rewardToken: RewardToken;
  let user1: SignerWithAddress,
    user2: SignerWithAddress,
    user3: SignerWithAddress;

  before(async () => {
    const PriceOracleMock = await ethers.getContractFactory("PriceOracleMock");
    const priceOracleMock = await PriceOracleMock.deploy();
    await priceOracleMock.deployed();

    const StakeNFT = await ethers.getContractFactory("StakeNFT");
    stakeNFT = await StakeNFT.deploy("Test NFT", "TNFT");
    await stakeNFT.deployed();

    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    nftStaking = await NFTStaking.deploy(
      stakeNFT.address,
      priceOracleMock.address
    );
    await nftStaking.deployed();

    const RewardToken = await ethers.getContractFactory("RewardToken");
    rewardToken = await RewardToken.deploy(nftStaking.address);
    await rewardToken.deployed();

    [user1, user2, user3] = await ethers.getSigners();

    // should mint nft for user1, user2, user3
    stakeNFT.connect(user1).mint("test");
    stakeNFT.connect(user2).mint("test");
    stakeNFT.connect(user3).mint("test");
  });

  it("Should set reward token to nft staking", async function () {
    await nftStaking.setRewardToken(rewardToken.address);
  });

  it("Should set collection", async () => {
    await nftStaking.setCollection(true, stakeNFT.address);
  });

  it("Should stake nft for user1", async () => {
    await stakeNFT.connect(user1).approve(nftStaking.address, 1);
    await nftStaking.connect(user1).stake(0, 1);
  });

  it("Should unstake nft", async () => {
    await nftStaking.connect(user1).unstake(0, 1);
    const user1Balance = await rewardToken.balanceOf(user1.address);
    console.log(user1Balance.toString());
  });
});
