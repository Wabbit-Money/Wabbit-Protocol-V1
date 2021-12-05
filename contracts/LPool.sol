//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolToken.sol";

// **** There actually needs to be some sort of incentive if I want there to be a main token - whether this be in the form of liquidity tokens for them to redeem rewards from, maybe it will be required for voting ? maybe its value tracks the value of the treasury or the profits generated by the treasury ?
// **** What does AAVE's token actually do ? Maybe I can have it as an airdrop and an aditional minting reward which can be used for voting ?
// **** Perhaps stakers get occasionally rewarded with tokens proportional to the amount they deposited and the amount of time they staked for after a given amount of time
// **** Maybe this is not even necessary at all and it can just be a decentralized lending platform

contract LPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => address) private approvedAssetsMap;
    address[] private approvedAssets;

    constructor() {}

    /**
     *  @notice approves an asset to be used throughout the protocol and generate a new pool token for it
     *  @param _token address
     */
    function approveAsset(address _token, string memory _name, string memory _symbol) public onlyOwner {
        require(!isApprovedAsset(_token), "This token has already been approved");
        address newFarmToken = address(new PoolToken(_name, _symbol, 0)); 
        approvedAssets.push(_token);
        approvedAssetsMap[_token] = newFarmToken;
    }

    /**
     *  @notice returns whether a specified asset is approved
     *  @param _token address
     *  @return _isApproved bool
     */
    function isApprovedAsset(address _token) public view returns (bool _isApproved) {
        _isApproved = approvedAssetsMap[_token] != address(0);
    }

    /**
     *  @notice return the list of assets the protocol may accept
     *  @return _approvedAssets address[]
     */
    function getApproveAssets() public view returns (address[] memory _approvedAssets) {
        _approvedAssets = approvedAssets;
    }

    /**
     *  @notice returns the pool token that corresponds to an approved asset
     *  @param _token address
     *  @return _poolToken address
     */
    function getPoolToken(address _token) public view returns (address _poolToken) {
        require(isApprovedAsset(_token), "This asset is not approved");
        _poolToken = approvedAssetsMap[_token];
    }

    /**
     *  @notice deposits a given amount of assets into the pool and mints a portion of tokens to represent the share
     *  @param _token address
     *  @param _amount uint256
     */
    function deposit(address _token, uint256 _amount) public {
        // Make sure that the token is approved
        require(isApprovedAsset(_token), "This asset is not approved");
        address _poolToken = getPoolToken(_token);

        // Calculate the compensation tokens
        uint256 numerator = _amount.mul(IERC20(_poolToken).totalSupply());
        uint256 denominator = IERC20(_token).balanceOf(address(this));
        uint256 compensationTokens = numerator.div(denominator.add(1));

        // Deposit to the pool and mint new compensation tokens
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        PoolToken(_poolToken).mint(_msgSender(), compensationTokens);

        // Emit an event
    }

    /**
     * @notice withdraws tokens in exchange for the percentage worth in the pool
     */
    function withdraw(address _token, uint256 _amount) public {

    }

    // ======== Events ========
    event Deposit(address indexed from, address indexed token, uint256 depositAmount, uint256 tokensCompensated);
}