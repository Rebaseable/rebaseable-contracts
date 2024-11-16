// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OAppRead} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppRead.sol";
import {Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/* 
TODO:
- first integrate lzRead
- get data from stETH on mainnet
- then integrate the OFT
- implement getting data every time someone bridges stETH 
 */

contract rstETH is OAppRead {
    uint32 constant READ_CHANNEL_EID_THRESHOLD = 4294965694;

    constructor(address _endpoint, address _delegate) OAppRead(_endpoint, _delegate) Ownable(_delegate) {}

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
        // Implement lzRead response handling logic here.
        bool _readDoSomething = abi.decode(_message, (bool));
    }
}
