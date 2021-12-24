// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../bitcoin/state/BTCDataStructure.sol";

/**
* @title BiFi-Bifrost-Extension IBTCPureLib Interface
* @notice Interface for BTCPureLib Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IBTCPureLib {
    function computeMultiMerkleRoot(
        bytes32[] calldata targetTXHashes,
        bytes32[] calldata merkleProof,
        bytes calldata proofSwitches
    ) external pure returns (bytes32);

    function parse_unit_from_rawTX(
        bytes memory rawHex,
        uint256[] memory units_indices
    ) external pure returns (BTCDataStructure.S_Unit[] memory);

    function compareHeaderTarget(bytes memory rawHeader, bytes32 target) external pure returns (bool);
}