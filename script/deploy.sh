#!/bin/bash
forge create src/RstETHOFT.sol:RstETHOFT --rpc-url https://base-sepolia.g.alchemy.com/v2/SeGqpLskn6HczGEJN-TsXicdbFrMVa0N --private-key 0xdbc90ac2c7dff415f62f0ef36e20b1875ed61acb405668a6e8c7b4e6c8864641 --verify --verifier blockscout --verifier-url https://base-sepolia.blockscout.com/api/ --constructor-args "Rebaseable Base Staked Ether" "rstETH" "0x6EDCE65403992e310A62460808c4b910D972f10f" "0x1c46D242755040a0032505fD33C6e8b83293a332"

