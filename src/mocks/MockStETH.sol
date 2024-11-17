// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../external/IStETH.sol";

import {UnstructuredStorage} from "./DummyStorage.sol";

// 0xFe98dAA1947e23108d86d375316E890080e18f24

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStETH is ERC20 {
    using UnstructuredStorage for bytes32;

    bytes32 internal constant TOTAL_SHARES_POSITION = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e; // keccak256("lido.StETH.totalShares")
    bytes32 internal constant BUFFERED_ETHER_POSITION =
        0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0; // keccak256("lido.Lido.bufferedEther");
    bytes32 internal constant CL_BALANCE_POSITION = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483; // keccak256("lido.Lido.beaconBalance");
    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION =
        0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c; // keccak256("lido.Lido.depositedValidators");
    bytes32 internal constant CL_VALIDATORS_POSITION =
        0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10; // keccak256("lido.Lido.beaconValidators");

    // Storage position for shares mapping
    bytes32 internal constant SHARES_POSITION = keccak256("lido.StETH.shares");

    // Initial exchange rate: 1 share = 1 token
    uint256 private constant INITIAL_RATE = 1e18;

    constructor() ERC20("Liquid staked Ether 2.0", "stETH") {
        // Mint initial supply to deployer
        _mint(msg.sender, 1000 ether);
        _setShares(msg.sender, 1000 ether);
        TOTAL_SHARES_POSITION.setStorageUint256(1000 ether);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return getPooledEthByShares(sharesOf(_account));
    }

    function submit() external payable {
        require(msg.value > 0, "Cannot submit 0 ETH");

        uint256 sharesAmount = getSharesByPooledEth(msg.value);
        _setShares(msg.sender, sharesOf(msg.sender) + sharesAmount);
        TOTAL_SHARES_POSITION.setStorageUint256(getTotalShares() + sharesAmount);

        _mint(msg.sender, msg.value);
    }

    function getTotalShares() public view returns (uint256) {
        return TOTAL_SHARES_POSITION.getStorageUint256();
    }

    function sharesOf(address _account) public view returns (uint256) {
        return _getShares(_account);
    }

    function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
        if (totalSupply() == 0) {
            return _ethAmount;
        }
        return (_ethAmount * getTotalShares()) / totalSupply();
    }

    function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        if (getTotalShares() == 0) {
            return 0;
        }
        return (_sharesAmount * totalSupply()) / getTotalShares();
    }

    function distributeRewards(uint256 _rewardAmount) external {
        _mint(address(this), _rewardAmount);
    }

    function _getShares(address _account) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(_account, SHARES_POSITION));
        return UnstructuredStorage.getStorageUint256(slot);
    }

    function _setShares(address _account, uint256 _amount) internal {
        bytes32 slot = keccak256(abi.encodePacked(_account, SHARES_POSITION));
        UnstructuredStorage.setStorageUint256(slot, _amount);
    }
}
