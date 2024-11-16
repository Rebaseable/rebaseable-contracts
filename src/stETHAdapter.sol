// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStETH} from "./external/IStETH.sol";

/// @notice OFTAdapter uses a deployed ERC-20 token and safeERC20 to interact with the OFTCore contract.
contract stETHAdapter is OFTAdapter {
    mapping(address => uint256) public sharesPerUser;

    constructor(address _token, address _lzEndpoint, address _owner)
        OFTAdapter(_token, _lzEndpoint, _owner)
        Ownable(_owner)
    {}

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        uint256 userShares = IStETH(address(innerToken)).sharesOf(msg.sender);
        sharesPerUser[msg.sender] += userShares;

        super._debit(_from, _amountLD, _minAmountLD, _dstEid);
    }

    function _credit(address _to, uint256 _amountLD, uint32 /*_srcEid*/ )
        internal
        virtual
        override
        returns (uint256 amountReceivedLD)
    {
        uint256 userShares = getSharesByEth(_amountLD);
        sharesPerUser[msg.sender] -= userShares;

        innerToken.transfer(_to, _amountLD);
    }

    function getEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        return
            (_sharesAmount * IStETH(address(innerToken)).totalSupply()) / IStETH(address(innerToken)).getTotalShares();
    }

    function getSharesByEth(uint256 _eth) public view returns (uint256) {
        return (_eth * IStETH(address(innerToken)).getTotalShares()) / IStETH(address(innerToken)).totalSupply();
    }
}
