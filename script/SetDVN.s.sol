// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

// Forge imports
import "forge-std/src/Script.sol";
import "forge-std/src/console.sol";

// LayerZero imports
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "lz-evm-messagelib/contracts/uln/UlnBase.sol";

contract SetDVN is Script {
    uint32 public constant ULN_CONFIG_TYPE = 2;

    address rstETH = 0x8eE74Bfc34e7e2e257887d54a59DAD1b2BD80Cc3;
    ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(0x6EDCE65403992e310A62460808c4b910D972f10f);
    address dvn = 0xbf6FF58f60606EdB2F190769B951D825BCb214E2;
    uint32 remoteEid = 4294967295;
    address signer = 0x1c46D242755040a0032505fD33C6e8b83293a332;


    function run() external {
        address[] memory requiredDvns = new address[](1);
        address[] memory optDvns;
        requiredDvns[0] = dvn;

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 0,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDvns,
            optionalDVNs: optDvns
        });

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](1);

        setConfigParams[0] = SetConfigParam({
            eid: remoteEid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        uint256 deployerPrivKey = vm.envUint("KEY");
        vm.startBroadcast(deployerPrivKey);

        endpoint.setConfig(rstETH, 0xC1868e054425D378095A003EcbA3823a5D0135C9, setConfigParams);

        vm.stopBroadcast();
    }
}