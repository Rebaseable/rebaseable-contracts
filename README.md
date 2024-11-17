### Rebaseable contracts

Rebaseable is bringing rebasing staked tokens, starting with stETH, cross-chain.

This repo encompasses multiple solutions around this problem spectrum. 

## RstETH:
Here we tried to get the balance updates from the mainnet stETH using `lzRead` from LayerZero. The code itself is complete but we could not deploy this to any chain because lzRead did not work properly. We were running into many errors with the DVNs and the executors when sending the `lzRead` call cross-chain.

`RstETH`: `0x8eE74Bfc34e7e2e257887d54a59DAD1b2BD80Cc3` (Base Sepolia Testnet - not working)

## RstETHOFT and stETHAdapter:
These contracts use the OFT standard to accomplish cross-chain rebasing stETH. The `stETHAdapter` contract accepts users' stETH on mainnet and then send them cross-chain as OFT. The `RstETHOFT` contract is the cross-chain OFT. The rebasing info reaches the OFT by the `updateRebaseInfo` function. This ideally should be called by a piece of decentralized and secure off-chain architecture, such as EigenLayer AVS. We did not have the time to implement this piece of architecture.

Deployment addresses:

`stETHAdapter`: `0x19180d8aF15dd42a868840d9A31A09Ed98711422` (Ethereum Sepolia Testnet)    

`RstETHOFT`: `0x5F1A2810eDa7B75A8934Ae15b1c0ADcDAE315bc3` (Base Sepolia Testnet)

![lz](https://github.com/user-attachments/assets/d3eb5503-f473-4503-bddf-e4e8fd2cbdaa)

## Scroll:
On Scroll we used the `L1SLOAD` feature to cheaply and instantly access L1 state, and thus get real time balance updates from the mainnet `stETH` to the Scroll Devnet deployed rstETH`. This use case is specific to `L1SLOAD` and could not have been possible on any other chain or technology.   

For the cross-chain (L1 - L2) messaging we utilized the ScrollMessenger to pass `stETH` token bridging information from Scroll to L1 and vice versa.

Deployment addresses:

`ScrollStETHBridge`; `0x2b819A18d532456F273d59Ed4788d97b52fa6375` (Ethereum Sepolia Testnet)   

`ScrollRstETH`: `0xfbB5eb88a4C99ae2C5b84184C84460f172f0eC06` (Scroll Devnet)    


![scroll1](https://github.com/user-attachments/assets/cbc6bd1e-7c81-4082-872e-cc3e7726be36)

![scroll2](https://github.com/user-attachments/assets/19be7e16-5ee6-4034-8eb5-c28fdb4850ca)


