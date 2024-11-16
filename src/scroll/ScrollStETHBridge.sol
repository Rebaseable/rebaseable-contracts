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
    ScrollMessenger public immutable scrollMessenger;
    IERC20 public immutable stETH;

    address public scrollRstETH;

    uint256 constant MSG_VAL = 1000000000000000;
    uint256 constant GAS_LIMIT = 2000000;

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
        if (scrollRstETH != address(0)) {
            revert("AlreadySet");
        }

        scrollRstETH = _scrollStETH;
    }

    function bridgeRStETH(uint256 amount) external payable {
        stETH.transferFrom(msg.sender, address(this), amount);

        BridgeStETHMessage memory bridgeMsg = BridgeStETHMessage({user: msg.sender, amount: amount});

        bytes memory encodedMsg = abi.encode(bridgeMsg);

        scrollMessenger.sendMessage{value: msg.value}(
            scrollRstETH, MSG_VAL, abi.encodeWithSelector(IScrollRstETH.receiveRstETH.selector, encodedMsg), GAS_LIMIT
        );
    }

    function payOutRstETH(bytes memory encodedMsg) external onlyScrollMessenger {
        BridgeStETHMessage memory decodedMsg = abi.decode(encodedMsg, (BridgeStETHMessage));
        (bool success) = stETH.transfer(decodedMsg.user, decodedMsg.amount);
        if (!success) {
            revert("Transfer failed");
        }
    }
}
