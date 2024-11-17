// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract RstETHOFT is OFT {
    uint256 public lastTotalSupply;
    uint256 public lastTotalShares;
    uint256 public lastUpdateTimestamp;

    mapping(address => uint256) public sharesPerUser;

    constructor(string memory _name, string memory _symbol, address _lzEndpoint, address _delegate)
        OFT(_name, _symbol, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    function balanceOf(address account) public view virtual override returns (uint256) {
        return getEthByShares(sharesPerUser[account]);
    }

    function updateRebaseInfo(uint256 _lastTotalSupply, uint256 _lastTotalShares) public {
        lastTotalSupply = _lastTotalSupply;
        lastTotalShares = _lastTotalShares;
        lastUpdateTimestamp = block.timestamp;
    }

    function getEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        return (_sharesAmount * lastTotalSupply) / lastTotalShares;
    }

    function getSharesByEth(uint256 _eth) public view returns (uint256) {
        return (_eth * lastTotalShares) / lastTotalSupply;
    }

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        uint256 userShares = getSharesByEth(_amountLD);
        sharesPerUser[msg.sender] -= userShares;

        super._debit(_from, _amountLD, _minAmountLD, _dstEid);
    }

    function _credit(address _to, uint256 _amountLD, uint32 _srcEid )
        internal
        virtual
        override
        returns (uint256 amountReceivedLD)
    {
        uint256 userShares = getSharesByEth(_amountLD);
        sharesPerUser[msg.sender] += userShares;

        super._credit(_to,_amountLD, _srcEid);
    }
}
