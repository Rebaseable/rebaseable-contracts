// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ScrollMessenger} from "./ScrollStETHBridge.sol";
import {IScrollRstETH} from "./ScrollStETHBridge.sol";

interface IStETHAdapter {
    function payOutRstETH(bytes memory encodedMsg) external;
}

contract ScrollRstETH is ERC20, IScrollRstETH {
    bytes32 internal constant TOTAL_SHARES_POSITION = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e; // keccak256("lido.StETH.totalShares")
    bytes32 internal constant BUFFERED_ETHER_POSITION =
        0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0; // keccak256("lido.Lido.bufferedEther");
    bytes32 internal constant CL_BALANCE_POSITION = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483; // keccak256("lido.Lido.beaconBalance");
    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION =
        0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c; // keccak256("lido.Lido.depositedValidators");
    bytes32 internal constant CL_VALIDATORS_POSITION =
        0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10; // keccak256("lido.Lido.beaconValidators");

    uint256 private constant DEPOSIT_SIZE = 32 ether;

    address constant L1_BLOCKS_ADDRESS = 0x5300000000000000000000000000000000000001;
    address constant L1_SLOAD_ADDRESS = 0x0000000000000000000000000000000000000101;
    address immutable stETHAddress;

    ScrollMessenger public scrollMessenger;

    IStETHAdapter public stETHAdapter;

    uint256 GAS_LIMIT = 1000000;

    mapping(address => uint256) public sharesPerUser;

    struct BridgeStETHMessage {
        address user;
        uint256 amount;
    }

    modifier onlyScrollMessenger() {
        if (msg.sender != address(scrollMessenger)) {
            revert("Invalid sender");
        }
        _;
    }

    constructor(address _stETHAddress, IStETHAdapter _stETHAdapter, ScrollMessenger _scrollMessenger ) ERC20("Rebaseable Staked Ether", "rstETH") {
        stETHAddress = _stETHAddress;
        stETHAdapter = _stETHAdapter;
        scrollMessenger = _scrollMessenger;
    }

    function setScrollMessenger(ScrollMessenger _scrollMessenger) external  {
        scrollMessenger = _scrollMessenger;
    }

    function setGasLimit(uint256 _gasLimit) external  {
        GAS_LIMIT = _gasLimit;
    }

    function receiveRstETH(bytes memory encodedMsg) external {
        BridgeStETHMessage memory decodedMsg = abi.decode(encodedMsg, (BridgeStETHMessage));
        _mint(decodedMsg.user, decodedMsg.amount);

        sharesPerUser[decodedMsg.user] += getSharesByEth(decodedMsg.amount);
    }

    function payoutRstETH(uint256 amount) external payable {
        _burn(msg.sender, amount);
        sharesPerUser[msg.sender] -= getSharesByEth(amount);

        BridgeStETHMessage memory bridgeMsg = BridgeStETHMessage({user: msg.sender, amount: amount});

        bytes memory encodedMsg = abi.encode(bridgeMsg);

        scrollMessenger.sendMessage{value: msg.value}(
            address(stETHAdapter), 0, abi.encodeWithSelector(IStETHAdapter.payOutRstETH.selector, encodedMsg), GAS_LIMIT
        );
    }

    function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        if (getValForPosition(TOTAL_SHARES_POSITION) == 0) return 0;
        return (_sharesAmount * getTotalPooledEther()) / getValForPosition(TOTAL_SHARES_POSITION);
    }

    function getValForPosition(bytes32 _position) public view returns (uint256) {
        (bool success, bytes memory returnValue) =
            L1_SLOAD_ADDRESS.staticcall(abi.encodePacked(stETHAddress, _position));
        if (!success) {
            revert("L1SLOAD failed");
        }
        return abi.decode(returnValue, (uint256));
    }

    function getTotalPooledEther() public view returns (uint256) {
        return
            getValForPosition(BUFFERED_ETHER_POSITION) + getValForPosition(CL_BALANCE_POSITION) + _getTransientBalance();
    }

    function _getTransientBalance() internal view returns (uint256) {
        uint256 depositedValidators = getValForPosition(DEPOSITED_VALIDATORS_POSITION);
        uint256 clValidators = getValForPosition(CL_VALIDATORS_POSITION);

        // clValidators can never be less than deposited ones.
        assert(depositedValidators >= clValidators);

        return (depositedValidators - clValidators) * DEPOSIT_SIZE;
    }

    function getSharesByEth(uint256 _eth) public view returns (uint256) {
        if (getTotalPooledEther() == 0) return _eth;
        return (_eth * getValForPosition(TOTAL_SHARES_POSITION)) / getTotalPooledEther();
    }

    function withdraw() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable { }
}
