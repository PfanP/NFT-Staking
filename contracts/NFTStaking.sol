//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libs/Array.sol";
import "./interface/IRewardToken.sol";
import "./interface/IPriceOracleMock.sol";

contract NFTStaking is ERC721Holder, Ownable {
    using Address for address;
    using Array for uint256[];

    /// @notice keep track of each user and their info
    struct UserInfo {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256) timeStaked;
        uint256 amountStaked;
    }

     /// @notice keep track of each collection and their info
    struct CollectionInfo {
        bool isStakable;
        address collectionAddress;
        uint256 amountOfStakers;
    }

    address public immutable nftToken;
    /// @notice ERC20 reward token
    address public rewardToken;
    /// @notice price oracle contract
    address public priceOracle;
    /// @dev wallet address => tokenId
    mapping(address => uint[]) public stakingInfo;
    /// @notice map user addresses over their info
    mapping(address => UserInfo) public userInfo;

    CollectionInfo[] public collectionInfo;
    /// @notice collection address => (staked nft => user address)
    mapping(address => mapping(uint256 => address)) public tokenOwners;
    
    event Stake(address indexed user, uint256 tokenId);
    event UnStake(address indexed user, uint256 tokenId);
    event Liquidated(address indexed user, uint256 tokenId);

    constructor(
        address _nftToken,
        address _priceOracle
    ) Ownable() {
        nftToken = _nftToken;
        priceOracle = _priceOracle;
    }

    function calculateNFTValue() internal {

    }

    /**
     *   @notice external stake function, for single stake request
     *   @param _cid => collection address
     *   @param _id => nft id
     */
    function stake(uint256 _cid, uint256 _id) external payable {
        _stake(msg.sender, _cid, _id);
    }

    /**
     *   @notice external unstake function, for single unstake request
     *   @param _cid => collection address
     *   @param _id => nft id
     */
    function unstake(uint256 _cid, uint256 _id) external {
        _unstake(msg.sender, _cid, _id);
    }

    /**
     *    @notice internal unstake function, called in external unstake and batchUnstake
     *    @param _user => msg.sender
     *    @param _cid => collection id
     *    @param _id => nft id
     */
    function _unstake(
        address _user,
        uint256 _cid,
        uint256 _id
    ) internal {
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];

        require(
            tokenOwners[collection.collectionAddress][_id] == _user,
            "Masterdemon._unstake: Sender doesn't owns this token"
        );

        user.stakedTokens[collection.collectionAddress].removeElement(_id);

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers -= 1;
        }

        delete tokenOwners[collection.collectionAddress][_id];
        IRewardToken(rewardToken).mint(_user, block.timestamp - user.timeStaked[collection.collectionAddress]);
        user.timeStaked[collection.collectionAddress] = block.timestamp;
        user.amountStaked -= 1;

        if (user.amountStaked == 0) {
            delete userInfo[_user];
        }

        IERC721(collection.collectionAddress).transferFrom(
            address(this),
            _user,
            _id
        );
        emit UnStake(_user, _id);
    }

    /**
     *    @notice internal stake function
     *    @param _user => msg.sender
     *    @param _cid => collection id
     *    @param _id => nft id
     */
    function _stake(
        address _user,
        uint256 _cid,
        uint256 _id
    ) internal {
        if (IPriceOracleMock(priceOracle).getPrice(address(0), 0) > 1) {
            emit Liquidated(_user, _id);
            return;
        }
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];

        IERC721(collection.collectionAddress).transferFrom(
            _user,
            address(this),
            _id
        );

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers += 1;
        }

        user.amountStaked += 1;
        user.timeStaked[collection.collectionAddress] = block.timestamp;
        user.stakedTokens[collection.collectionAddress].push(_id);
        tokenOwners[collection.collectionAddress][_id] = _user;

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers += 1;
        }
        emit Stake(_user, _id);
    }

    /// @notice reward token set
    /// @param _rewardToken ERC20 reward token address
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    /**
     *    @notice initialize new collection
     *    @param _isStakable => is pool active?
     *    @param _collectionAddress => address of nft collection
     */
    function setCollection(
        bool _isStakable,
        address _collectionAddress
    ) public onlyOwner {
        collectionInfo.push(
            CollectionInfo({
                isStakable: _isStakable,
                collectionAddress: _collectionAddress,
                amountOfStakers: 0
            })
        );
    }

    /// @notice Check if ERC721 token is supported in staking contract
    /// @param operator minter or transfer for ERC721
    /// @param from address representing the previous owner of the given token ID
    /// @param tokenId uint256 ID of the token to be transferred
    /// @param data bytes optional data to send along with the call
    /// @return Documents the return variables of a contract’s function state variable
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes memory data
    ) public override returns (bytes4) {
        require(msg.sender == nftToken, "Not whitelisted");
        stakingInfo[operator].push(tokenId);
        return super.onERC721Received(operator, from, tokenId, data);
    }
}