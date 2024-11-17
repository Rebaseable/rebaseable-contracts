// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStETH} from "../external/IStETH.sol";

interface ScrollMessenger {
    function sendMessage(address to, uint256 value, bytes memory message, uint256 gasLimit) external payable;
}

interface IScrollRstETH {
    function receiveRstETH(bytes memory encodedMsg) external;
}

contract ScrollStETHBridge {
    ScrollMessenger public scrollMessenger;
    IERC20 public immutable stETH;

    address public scrollRstETH;

    uint256 GAS_LIMIT = 1000000;

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

    constructor(ScrollMessenger _scrollMessenger, IERC20 _stETH) {
        scrollMessenger = _scrollMessenger;
        stETH = _stETH;
    }

    function setScrollRstETH(address _scrollStETH) external {
/*         if (scrollRstETH != address(0)) {
            revert("AlreadySet");
        } */

        scrollRstETH = _scrollStETH;
    }

    function setScrollMessenger(ScrollMessenger _scrollMessenger) external  {
        scrollMessenger = _scrollMessenger;
    }

    function setGasLimit(uint256 _gasLimit) external  {
        GAS_LIMIT = _gasLimit;
    }


    function bridgeRStETH(uint256 amount) external payable {
        stETH.transferFrom(msg.sender, address(this), amount);

        BridgeStETHMessage memory bridgeMsg = BridgeStETHMessage({user: msg.sender, amount: amount});

        bytes memory encodedMsg = abi.encode(bridgeMsg);

        scrollMessenger.sendMessage{value: msg.value}(
            scrollRstETH, 0, abi.encodeWithSelector(IScrollRstETH.receiveRstETH.selector, encodedMsg), GAS_LIMIT
        );
    }

    function payOutRstETH(bytes memory encodedMsg) external onlyScrollMessenger {
        BridgeStETHMessage memory decodedMsg = abi.decode(encodedMsg, (BridgeStETHMessage));
        (bool success) = stETH.transfer(decodedMsg.user, decodedMsg.amount);
        if (!success) {
            revert("Transfer failed");
        }
    }

    function withdraw() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable { }

    
}
