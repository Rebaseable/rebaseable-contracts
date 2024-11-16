// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IRstETH {
    struct EvmReadRequest {
        uint16 appRequestLabel;
        uint32 targetEid;
        bool isBlockNum;
        uint64 blockNumOrTimestamp;
        uint16 confirmations;
        address to;
    }

    struct EvmComputeRequest {
        uint8 computeSetting;
        uint32 targetEid;
        bool isBlockNum;
        uint64 blockNumOrTimestamp;
        uint16 confirmations;
        address to;
    }
/* 
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    } */

    function getRebaseInfo(bytes calldata _extraOps) external payable;

    function lastTotalSupply() external view returns (uint256);
    function lastTotalShares() external view returns (uint256);
// 0x8eE74Bfc34e7e2e257887d54a59DAD1b2BD80Cc3
/*     function quote(uint32 _channelId, bytes memory _options, bool _payInLzToken)
        external
        view
        returns (MessagingFee memory fee);

    function getOps(bytes calldata _extraOps) external view returns (bytes memory);

    function getCmd() external view returns (bytes memory);

    function setReadChannel(uint32 _channelId, bool _active) external;

    function quoteWrite(uint32 _channelId, bytes memory _options, bool _payInLzToken)
        external 
        returns (MessagingFee memory fee); */
}
