// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../external/IStETH.sol";


// 0xFe98dAA1947e23108d86d375316E890080e18f24

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStETH is ERC20 {
    // Track shares for each account
    mapping(address => uint256) private _shares;
    uint256 private _totalShares;
    
    // Initial exchange rate: 1 share = 1 token
    uint256 private constant INITIAL_RATE = 1e18;
    
    constructor() ERC20("Liquid staked Ether 2.0", "stETH") {
        // Mint initial supply to deployer
        _mint(msg.sender, 1000 ether);
        _shares[msg.sender] = 1000 ether;
        _totalShares = 1000 ether;
    }
    
    // Submit ETH to the protocol and receive stETH tokens
    function submit() external payable {
        require(msg.value > 0, "Cannot submit 0 ETH");
        
        uint256 sharesAmount = getSharesByPooledEth(msg.value);
        _shares[msg.sender] += sharesAmount;
        _totalShares += sharesAmount;
        
        _mint(msg.sender, msg.value);
    }
    
    // Get total supply (inherited from ERC20)
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }
    
    // Get total shares
    function getTotalShares() external view returns (uint256) {
        return _totalShares;
    }
    
    // Get shares of specific account
    function sharesOf(address _account) external view returns (uint256) {
        return _shares[_account];
    }
    
    // Helper function to calculate shares based on ETH amount
    function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
        if (totalSupply() == 0) {
            return _ethAmount;
        }
        return (_ethAmount * _totalShares) / totalSupply();
    }
    
    // Helper function to calculate ETH amount based on shares
    function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        if (_totalShares == 0) {
            return 0;
        }
        return (_sharesAmount * totalSupply()) / _totalShares;
    }
    
    // Function to simulate staking rewards (for testing)
    function distributeRewards(uint256 _rewardAmount) external {
        _mint(address(this), _rewardAmount);
    }
}