// SPDX-License-Identifier: MIT

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {IOFT, SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import {OFTMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "forge-std/src/console.sol";

import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {RstETHOFT} from "../src/RstETHOFT.sol";

contract RstETHOFTTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 private aEid = 1;
    uint32 private bEid = 2;

    RstETHOFT private aOFT;
    RstETHOFT private bOFT;

    address private userA = address(0x1);
    address private userB = address(0x2);
    uint256 private initialBalance = 100 ether;

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);

        super.setUp();

        setUpEndpoints(2, LibraryType.UltraLightNode);

        aOFT = new RstETHOFT("Test A", "TA", address(endpoints[aEid]), address(this));
        bOFT = new RstETHOFT("Test B", "TB", address(endpoints[aEid]), address(this));

        address[] memory ofts = new address[](2);
        ofts[0] = address(aOFT);
        ofts[1] = address(bOFT);
        this.wireOApps(ofts);

        // Mint initial tokens for userA and userB
        aOFT.mint(userA, initialBalance);
        bOFT.mint(userB, initialBalance);
    }

    function test_constructor() public {
        // Check that the contract owner is correctly set
        assertEq(aOFT.owner(), address(this));
        assertEq(bOFT.owner(), address(this));

        // Verify initial token balances for userA and userB
        assertEq(aOFT.balanceOf(userA), initialBalance);
        assertEq(bOFT.balanceOf(userB), initialBalance);

        // Verify that the token address is correctly set to the respective OFT instances
        assertEq(aOFT.token(), address(aOFT));
        assertEq(bOFT.token(), address(bOFT));
    }

    function test_send_oft() public {
        uint256 tokensToSend = 1 ether;

        // Build options for the send operation
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        // Set up parameters for the send operation
        SendParam memory sendParam =
            SendParam(bEid, addressToBytes32(userB), tokensToSend, tokensToSend, options, "", "");

        // Quote the fee for sending tokens
        MessagingFee memory fee = aOFT.quoteSend(sendParam, false);

        // Verify initial balances before the send operation
        assertEq(aOFT.balanceOf(userA), initialBalance);
        assertEq(bOFT.balanceOf(userB), initialBalance);

        // Perform the send operation
        vm.prank(userA);
        aOFT.send{value: fee.nativeFee}(sendParam, fee, payable(address(this)));

        // Verify that the packets were correctly sent to the destination chain.
        // @param _dstEid The endpoint ID of the destination chain.
        // @param _dstAddress The OApp address on the destination chain.
        verifyPackets(bEid, addressToBytes32(address(bOFT)));

        // Check balances after the send operation
        assertEq(aOFT.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(bOFT.balanceOf(userB), initialBalance + tokensToSend);
    }
}
