// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension BTCDataStructure Contract
* @notice Struct definition collection
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract BTCDataStructure {
    /**
	* @dev struct that holds challenge context
    * @notice challengeHash will be stored in external database contract
	*/
    struct S_ChallengeContext {
        address challenger;
        bool    challenged;
        uint64  challengeBTCheight;
        uint64  challengeETHheight;
        bytes32 challengeHash;  // used for rejecting the challenge with same data(i.e. Dos Attack)
        uint256 challengeFeeAmount;
    }

    /**
	* @dev struct that holds retarget context, for update and rollback
	*/
    struct S_RetargetContext {
        /// @notice nBits: bitcoin difficulty of this 2016-epoch
        uint32 nBits;
        /// @notice epochTailTime: time of 2015-th block in this epoch
        uint32 epochTailTime;
        /// @notice epochTailTime: time of first block in this epoch
        uint32 epochHeadTime;
    }

    /**
	* @dev relayed data submitted by Relayer
	*/
    struct S_TxProof {
        bytes[]   rawTXs;
        bytes32[] merkleProof;
        bytes     proofSwitches;
    }

    /**
	* @dev struct that holds unit of transaction out that parsing from bitcoin transaction output
	*/
    struct S_Unit {
        // btc tx status: err(0), outflow(1), transferIn(2), deposit(3), repay(4)
        uint32 status;
        uint64 amount;  // in Satoshi
        address BTCaddr;  // recipient's address (in actual, PubKeyHash)
    }

    /**
	* @dev struct that holds outflow information
	* @notice it will be emitted by event when outflow process completes
	*/
    struct S_Outflow {
        bool requested;
        uint64 pendingAmount;
        uint128 timeLimit;
    }
}