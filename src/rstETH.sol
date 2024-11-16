// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OAppRead} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppRead.sol";
import {MessagingFee, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    EVMCallRequestV1,
    EVMCallComputeV1,
    ReadCodecV1
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/ReadCodecV1.sol";
import {OptionsBuilder} from "@lz-oapp-v2/libs/OptionsBuilder.sol";
import {IStETH} from "./external/IStETH.sol";
import {IRstETH} from "./IRstETH.sol";

/* 
TODO:
- first integrate lzRead OK
- get data from stETH on mainnet OK
- then integrate the OFT
- implement getting data every time someone bridges stETH 
 */

// 0xE5f73B6f182Cf072EBf623a473404298A1ACD5Fa
contract RstETH is OAppRead, IRstETH {
    using OptionsBuilder for bytes;

    uint8 internal constant COMPUTE_SETTING_MAP_ONLY = 0;
    uint8 internal constant COMPUTE_SETTING_REDUCE_ONLY = 1;
    uint8 internal constant COMPUTE_SETTING_MAP_REDUCE = 2;
    uint8 internal constant COMPUTE_SETTING_NONE = 3;

    uint8 private constant READ_MSG_TYPE = 1;
    uint32 constant READ_CHANNEL = 4294967295;
    uint32 constant READ_CHANNEL_EID_THRESHOLD = 4294965694;

    address public stETH;

    uint32 public mainnetEid = 40161; // sepolia: 40161, mainnet: 30101;

    uint256 public lastTotalSupply;
    uint256 public lastTotalShares;
    uint256 public lastUpdateTimestamp;

    // --constructor-args "0x6EDCE65403992e310A62460808c4b910D972f10f" "0x1c46D242755040a0032505fD33C6e8b83293a332" "0xFe98dAA1947e23108d86d375316E890080e18f24"

    constructor(address _endpoint, address _delegate, address _stETH)
        OAppRead(_endpoint, _delegate)
        Ownable(_delegate)
    {
        stETH = _stETH;
    }

    function getRebaseInfo(bytes calldata _extraOps) external payable {
        bytes memory cmd = getCmd();
        bytes memory _options = _createLzSendOpts(250_000, 0);

        _lzSend(
            READ_CHANNEL,
            cmd,
            _options,
            MessagingFee(msg.value, 0), /* quote(READ_CHANNEL, _options, false) */
            payable(msg.sender)
        );
    }

    function getCmd() public view returns (bytes memory) {
        EVMCallRequestV1[] memory readRequests = new EVMCallRequestV1[](2);

        readRequests[0] = EVMCallRequestV1({
            appRequestLabel: 1,
            targetEid: mainnetEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: stETH,
            callData: abi.encodeWithSelector(IStETH.totalSupply.selector)
        });

        readRequests[1] = EVMCallRequestV1({
            appRequestLabel: 2,
            targetEid: mainnetEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: stETH,
            callData: abi.encodeWithSelector(IStETH.getTotalShares.selector)
        });

        EVMCallComputeV1 memory computeSettings = EVMCallComputeV1({
            computeSetting: COMPUTE_SETTING_REDUCE_ONLY,
            targetEid: mainnetEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: address(this)
        });

        return ReadCodecV1.encode(0, readRequests, computeSettings);
    }

    function lzReduce(bytes calldata, bytes[] calldata _responses) external pure returns (bytes memory) {
        require(_responses.length == 2, "Must provide exactly 2 responses");
        return bytes.concat(_responses[0], _responses[1]);
    }

    function _createLzSendOpts(uint128 _gas, uint128 _value) private pure returns (bytes memory) {
        return OptionsBuilder.newOptions().addExecutorLzReceiveOption(_gas, _value);
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        /**
         * @dev The `srcEid` (source Endpoint ID) is used to determine the type of incoming message.
         * - If `srcEid` is greater than READ_CHANNEL_EID_THRESHOLD (4294965694),
         *   it corresponds to arbitrary channel IDs for lzRead responses.
         * - All other `srcEid` values correspond to standard LayerZero messages.
         */
        if (_origin.srcEid > READ_CHANNEL_EID_THRESHOLD) {
            // Handle lzRead responses from arbitrary channels.
            _readLzReceive(_origin, _guid, _message, _executor, _extraData);
        } else {
            // Handle standard LayerZero messages.
            _messageLzReceive(_origin, _guid, _message, _executor, _extraData);
        }
    }

    function _messageLzReceive(
        Origin calldata, /* _origin */
        bytes32, /* _guid */
        bytes calldata _message,
        address, /* _executor */
        bytes calldata /* _extraData */
    ) internal virtual {
        // Implement message handling logic here.
        bool _messageDoSomething = abi.decode(_message, (bool));
    }

    function _readLzReceive(
        Origin calldata, /* _origin */
        bytes32, /* _guid */
        bytes calldata _message,
        address, /* _executor */
        bytes calldata /* _extraData */
    ) internal virtual {
        (uint256 _totalSupply, uint256 _totalShares) = abi.decode(_message, (uint256, uint256));
        lastTotalSupply = _totalSupply;
        lastTotalShares = _totalShares;
        lastUpdateTimestamp = block.timestamp;
    }

    function quote(uint32 _channelId, bytes memory _options, bool _payInLzToken)
        public
        view
        returns (MessagingFee memory fee)
    {
        bytes memory cmd = getCmd();
        fee = _quote(_channelId, cmd, _options, _payInLzToken);
    }

    function quoteWrite(uint32 _channelId, bytes memory _options, bool _payInLzToken)
        public
        returns (MessagingFee memory fee)
    {
        bytes memory cmd = getCmd();
        fee = _quote(_channelId, cmd, _options, _payInLzToken);
        lastUpdateTimestamp = block.timestamp;
    }
}
