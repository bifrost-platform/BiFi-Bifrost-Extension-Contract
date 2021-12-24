// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../libs/proxy/ProxyStorage.sol";
import "../bitcoin/state/BTCDataStructure.sol";

import "../interfaces/IERC20.sol";

import "../bitcoin/utils/L_PendingHeights.sol";

/**
* @title BiFi-Bifrost-Extension ExternalDataBase Contract
* @notice Contract for Bitcoin external database
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract ExternalDataBase is ProxyStorage, BTCDataStructure {
    using L_PendingHeights for S_PendingHeights;

    mapping(uint256 => S_RetargetContext) public difficultyTargetHistory;

    mapping(uint256 => bytes32) heightToHash;
    mapping(bytes32 => uint64 ) hashToHeight;

    mapping(bytes32 => S_Unit[]) public unitIDsAtHeight;

    mapping(bytes32 => uint256) heightByUnitID;


    mapping(address => S_Outflow) outflowInfo;
    mapping(address => uint256) inflowPending;

    mapping(bytes32 => S_ChallengeContext) public challengeHistory;

    constructor() {
        // using proxy, do not init storage here
    }

    function edit_RetargetHistory(uint256 key, S_RetargetContext memory data) onlyAdmin external returns (bool) {
        if(data.nBits !=0         ) difficultyTargetHistory[key].nBits         = data.nBits;
        if(data.epochTailTime !=0 ) difficultyTargetHistory[key].epochTailTime = data.epochTailTime;
        if(data.epochHeadTime !=0 ) difficultyTargetHistory[key].epochHeadTime = data.epochHeadTime;
        return true;
    }

    function update_RetargetHistory(uint256 key, S_RetargetContext memory data) onlyAdmin external returns (bool) {
        difficultyTargetHistory[key] = data;
        return true;
    }

    function update_RetargetHistoryTime(uint256 key, uint32 data) onlyAdmin external returns (bool) {
        uint32 dTime = difficultyTargetHistory[key].epochTailTime;
        difficultyTargetHistory[key].epochTailTime = data;
        return true;
    }
    function update_RetargetHistoryNBITS(uint256 key, uint32 data) onlyAdmin external returns (bool) {
        uint32 dnBits = difficultyTargetHistory[key].nBits;
        difficultyTargetHistory[key].nBits = data;
        return true;
    }
    function get_RetargetHistory(uint256 key) external view returns (S_RetargetContext memory) {
        return difficultyTargetHistory[key];
    }

    function set_challengeHistory(bytes32 key, S_ChallengeContext memory data) onlyAdmin external returns (bool) {
        require(!challengeHistory[key].challenged, "challenge history collision");
        challengeHistory[key] = data;
        return true;
    }
    function get_challengeHistory(bytes32 key) external view returns (S_ChallengeContext memory) {
        return challengeHistory[key];
    }

    function get_hashByHeight(uint256 key) external view returns (bytes32) {
        return heightToHash[key];
    }
    function get_heightByHash(bytes32 key) external view returns (uint64) {
        return hashToHeight[key];
    }
    function get_heightByUnitID(bytes32 key) external view returns (uint256) {
        return heightByUnitID[key];
    }
    function get_outflowInfo(address key) external view returns (S_Outflow memory) {
        return outflowInfo[key];
    }
    function pop_outflowInfo(address key) onlyAdmin external returns (S_Outflow memory returnData) {
        _isZeroAddress(key);
        returnData = outflowInfo[key];
        delete outflowInfo[key];
    }
    function get_inflowPending(address key) external view returns (uint256) {
        return inflowPending[key];
    }

    function set_hashByHeight(uint256 key, bytes32 data) onlyAdmin external returns (bool) {
        heightToHash[key] = data;
        return true;
    }

    function set_hashAndHeightInfo(bytes32 hash, uint64 number) onlyAdmin external returns (bool) {
        heightToHash[number] = hash;
        hashToHeight[hash] = number;
        return true;
    }

    function register_units(bytes32 headerHash, bytes32 txHash, uint256[] memory unitIDXs, S_Unit[] memory units) onlyAdmin external returns (bool) {
        uint256 blockNumber = hashToHeight[headerHash];
        require(blockNumber != 0, "not found pending height");

        bytes32 unitIDHash;
        for(uint256 i; i<unitIDXs.length; i++) {
            unitIDHash = _makeUnitID(headerHash, txHash, unitIDXs[i]);
            require(heightByUnitID[ unitIDHash ] == 0, "relay unitID collisions");

            unitIDsAtHeight[headerHash].push( units[i] );
            heightByUnitID[ unitIDHash ] = blockNumber;
        }
        return true;
    }

    function _makeUnitID(bytes32 headerHash, bytes32 txHash, uint256 unitIDX) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(headerHash, txHash, unitIDX));
    }

    function get_unitIDsAtHeight(uint256 blockNumber) external view returns (S_Unit[] memory returnData) {
        bytes32 headerHash = heightToHash[blockNumber];
        returnData = unitIDsAtHeight[headerHash];
    }

    function pop_unitIDsAtHeight(uint256 blockNumber) onlyAdmin external returns (S_Unit[] memory returnData) {
        bytes32 headerHash = heightToHash[blockNumber];
        require(hashToHeight[headerHash] != 0, "err: pop_unitIDsAtHeight1");
        returnData = unitIDsAtHeight[headerHash];
        delete unitIDsAtHeight[headerHash];
    }

    function pop_unitIDsAtHeight(uint256 blockNumber, uint256 count) onlyAdmin external returns (S_Unit[] memory returnData) {
        bytes32 headerHash = heightToHash[blockNumber];
        require(hashToHeight[headerHash] != 0, "err: pop_unitIDsAtHeight2");
        returnData = new S_Unit[](count);

        uint256 idx;
        for(uint256 i; i<count; i++) {
            idx = unitIDsAtHeight[headerHash].length-1;

            returnData[i] = unitIDsAtHeight[headerHash][idx];
            delete unitIDsAtHeight[headerHash][idx];
        }
    }

    function set_outflowInfo(address key, S_Outflow memory data) onlyAdmin external returns (bool) {
        _isZeroAddress(key);
        require(data.pendingAmount != 0, "outflow zero amount");
        outflowInfo[key] = data;
        return true;
    }
    function set_inflowPending(address key, uint256 data) onlyAdmin external returns (bool) {
        _isZeroAddress(key);
        inflowPending[key] = data;
        return true;
    }
    function add_inflowPending(address key, uint256 data) onlyAdmin external returns (bool) {
        _isZeroAddress(key);
        inflowPending[key] += data;
        return true;
    }
    function sub_inflowPending(address key, uint256 data) onlyAdmin external returns (bool) {
        _isZeroAddress(key);
        inflowPending[key] -= data;
        return true;
    }

    function _isZeroAddress(address addr) internal pure {
        require(addr != address(0), "zero address");
    }
}