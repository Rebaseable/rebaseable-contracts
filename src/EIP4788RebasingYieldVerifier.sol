// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILidoOracle {
    /// @notice Returns last completed report data
    /// @return epochId - Epoch for which last report was pushed
    /// @return beaconBalance - ETH balance of the Lido validators on the beacon chain
    /// @return beaconValidators - Number of Lido validators on the beacon chain
    /// @return rewardsVaultBalance - Balance of the ExecutionLayerRewardsVault contract
    /// @return exitedValidatorsCount - Number of exited validators
    /// @return timestamp - Timestamp of when the last report was pushed
    function getLastCompletedReport()
        external
        view
        returns (
            uint256 epochId,
            uint256 beaconBalance,
            uint256 beaconValidators,
            uint256 rewardsVaultBalance,
            uint256 exitedValidatorsCount,
            uint256 timestamp
        );

    /// @notice Returns last completed epoch id
    function getLastCompletedEpochId() external view returns (uint256);
}

contract BeaconChainParams {
    // Beacon chain constants
    uint256 constant SECONDS_PER_SLOT = 12;
    uint256 constant SLOTS_PER_EPOCH = 32;
    uint256 constant SECONDS_PER_EPOCH = SECONDS_PER_SLOT * SLOTS_PER_EPOCH; // 384 seconds

    // Genesis timestamps
    uint256 constant BEACON_GENESIS_TIMESTAMP = 1606824023; // Dec-01-2020 12:00:23 PM +UTC
    uint256 constant MERGE_TIMESTAMP = 1663224162; // Sep-15-2022 06:42:42 AM +UTC

    // Merge block number on execution chain
    uint256 constant MERGE_BLOCK = 15537393;

    /**
     * @notice Verify epoch consistency with detailed checks
     * @param epochId Oracle report epoch
     * @param blockNumber Execution layer block number
     * @param blockTimestamp Timestamp of the execution block
     * @return bool Whether the epoch is consistent
     */
    function isEpochConsistent(uint256 epochId, uint256 blockNumber, uint256 blockTimestamp)
        public
        pure
        returns (bool)
    {
        // 1. Basic sanity checks
        // Ensure block is after merge
        if (blockNumber < MERGE_BLOCK || blockTimestamp < MERGE_TIMESTAMP) {
            return false;
        }

        // 2. Calculate expected epoch range based on block timestamp
        // Get epochs since genesis
        uint256 epochsSinceGenesis = (blockTimestamp - BEACON_GENESIS_TIMESTAMP) / SECONDS_PER_EPOCH;

        // 3. Calculate acceptable epoch range
        // We allow for some drift due to:
        // - Block time variations
        // - Network delays
        // - Oracle processing time
        uint256 expectedEpochMin = epochsSinceGenesis > 2 ? epochsSinceGenesis - 2 : 0;
        uint256 expectedEpochMax = epochsSinceGenesis + 1; // Allow one epoch ahead due to block times

        // 4. Additional checks for block/epoch alignment
        uint256 blocksSinceMerge = blockNumber - MERGE_BLOCK;
        uint256 expectedEpochsFromBlocks = blocksSinceMerge * SECONDS_PER_SLOT / SECONDS_PER_EPOCH;

        // 5. Verify the reported epoch is within acceptable ranges
        bool withinTimestampRange = epochId >= expectedEpochMin && epochId <= expectedEpochMax;

        // 6. Verify reasonable alignment with block numbers
        // Allow some deviation due to block time variations
        bool reasonableBlockAlignment =
            epochId >= expectedEpochsFromBlocks - 3 && epochId <= expectedEpochsFromBlocks + 3;

        // 7. Additional timing checks
        uint256 epochStartTime = BEACON_GENESIS_TIMESTAMP + (epochId * SECONDS_PER_EPOCH);

        // Epoch start time should be before block timestamp
        bool validEpochTiming = epochStartTime <= blockTimestamp;

        // 8. Final duration sanity check
        // Ensure the time difference between epoch start and block
        // is not unreasonably large
        bool reasonableDuration = blockTimestamp - epochStartTime <= SECONDS_PER_EPOCH * 3;

        return withinTimestampRange && reasonableBlockAlignment && validEpochTiming && reasonableDuration;
    }

    /**
     * @notice Get estimated current epoch from block details
     * @param blockTimestamp Block timestamp
     * @return Current epoch estimation
     */
    function estimateCurrentEpoch(uint256 blockTimestamp) public pure returns (uint256) {
        require(blockTimestamp >= BEACON_GENESIS_TIMESTAMP, "Invalid timestamp");
        return (blockTimestamp - BEACON_GENESIS_TIMESTAMP) / SECONDS_PER_EPOCH;
    }
}

contract EIP4788RebasingYieldVerifier is BeaconChainParams {
    error RootNotFound();

    address public immutable BEACON_BLOCK_ROOT_PROVIDER;

    // Mapping of verified reports by epoch
    mapping(uint256 => bool) public verifiedEpochs;

    // Latest verified state
    uint256 public lastVerifiedBalance;
    uint256 public lastVerifiedEpoch;

    event ReportVerified(uint256 epochId, uint256 beaconBalance, bytes32 blockRoot, uint256 blockNumber);

    constructor(address beaconBlockRootProvider) {
        BEACON_BLOCK_ROOT_PROVIDER = beaconBlockRootProvider;
    }

    /**
     * @notice Verify Lido oracle report against block root
     * @param blockNumber Block number containing the oracle report
     * @param epochId Epoch ID from the oracle report
     * @param beaconBalance Balance reported by Lido oracle
     * @param beaconValidators Number of validators reported
     */
    function verifyReport(uint256 blockNumber, uint256 blockTimestamp, uint256 epochId, uint256 beaconBalance, uint256 beaconValidators)
        external
    {
        require(epochId > lastVerifiedEpoch, "Old epoch");
        require(!verifiedEpochs[epochId], "Already verified");

        // Get block root from EIP-4788
        bytes32 blockRoot = getParentBlockRoot(uint64(blockTimestamp));
        require(blockRoot != bytes32(0), "Invalid block root");

        // Verify the epoch is consistent with the block
        require(isEpochConsistent(epochId, blockNumber, blockTimestamp), "Invalid epoch");

        // Store verified state
        verifiedEpochs[epochId] = true;
        lastVerifiedBalance = beaconBalance;
        lastVerifiedEpoch = epochId;

        emit ReportVerified(epochId, beaconBalance, blockRoot, blockNumber);
    }

    function getParentBlockRoot(uint64 blockNumber) internal view returns (bytes32 root) {
        (bool success, bytes memory data) = BEACON_BLOCK_ROOT_PROVIDER.staticcall(abi.encode(blockNumber));

        if (!success || data.length == 0) {
            revert RootNotFound();
        }

        root = abi.decode(data, (bytes32));
    }

    /**
     * @notice Check if epoch is consistent with execution block
     * @param epochId Oracle report epoch
     * @param blockNumber Execution layer block number
     */
}
