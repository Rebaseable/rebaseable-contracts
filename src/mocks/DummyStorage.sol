// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}

contract DummyStorage {
    using UnstructuredStorage for bytes32;

    bytes32 internal constant TOTAL_SHARES_POSITION = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

    function getTotalShares() public view returns (uint256) {
        return TOTAL_SHARES_POSITION.getStorageUint256();
    }

    function setTotalShares(uint256 _new) public {
        TOTAL_SHARES_POSITION.setStorageUint256(_new);
    }
} // 0xF7Ac55C3590abcB280C45Eae3865e31E506BB339