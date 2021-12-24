// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../bitcoin/state/BTCDataStructure.sol";

/**
* @title BiFi-Bifrost-Extension IBTC_DB Interface
* @notice Interface for Bitcoin External Database Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IBTC_DB {
    function edit_RetargetHistory(uint256 key, BTCDataStructure.S_RetargetContext memory data) external returns (bool);
    function update_RetargetHistory(uint256 key, BTCDataStructure.S_RetargetContext memory data) external returns (bool);
    function update_RetargetHistoryTime(uint256 key, uint32 data) external returns (bool);
    function update_RetargetHistoryNBITS(uint256 key, uint32 data) external returns (bool);
    function get_RetargetHistory(uint256 key) external returns (BTCDataStructure.S_RetargetContext memory);

    function set_challengeHistory(bytes32 key, BTCDataStructure.S_ChallengeContext memory data) external returns (bool);
    function get_challengeHistory(bytes32 key) external returns (BTCDataStructure.S_ChallengeContext memory);

    function get_hashByHeight(uint256 key) external returns (bytes32);
    function get_heightByHash(bytes32 key) external view returns (uint64);

    function get_heightByUnitID(bytes32 key) external returns (uint256);

    function get_outflowInfo(address key) external returns (BTCDataStructure.S_Outflow memory);
    function pop_outflowInfo(address key) external returns (BTCDataStructure.S_Outflow memory returnData);

    function get_inflowPending(address key) external returns (uint256);

    // function set_(bytes32 data) external returns (bool);
    function set_hashByHeight(uint256 key, bytes32 data) external returns (bool);
    function set_hashToHeight(bytes32 key, uint64 data) external returns (bool);
    function set_hashAndHeightInfo(bytes32 hash, uint64 number) external returns (bool);
    function register_units(bytes32 headerHash, bytes32 txHash, uint256[] memory unitIDXs, BTCDataStructure.S_Unit[] memory units) external returns (bool);
    function pop_unitIDsAtHeight(uint256 blockNumber) external returns (BTCDataStructure.S_Unit[] memory returnData);
    function pop_unitIDsAtHeight(uint256 blockNumber, uint256 count) external returns (BTCDataStructure.S_Unit[] memory returnData);
    function set_outflowInfo(address key, BTCDataStructure.S_Outflow memory data) external returns (bool);
    function set_inflowPending(address key, uint256 data) external returns (bool);
    function add_inflowPending(address key, uint256 data) external returns (bool);
    function sub_inflowPending(address key, uint256 data) external returns (bool);
}