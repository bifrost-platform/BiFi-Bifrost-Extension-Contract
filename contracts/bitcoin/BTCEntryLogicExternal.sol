// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./BTCEntryLogicInternal.sol";

/**
* @title BiFi-Bifrost-Extension BTCEntryLogicExternal Contract
* @notice Entry functions of Bitcoin contract
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract BTCEntryLogicExternal is
    BTCEntryLogicInternal
{
    using L_Bytes for bytes;

    /**
	* @dev set a confirmed Bitcoin header
	* @param blockHeight the Bitcoin block height
    * @param rawHeader the Bitcoin header binary
    * @param epochBaseTime The timestamp of starting block header of 2016-epoch.
	* @return true
	*/
    function setConfirmedHeader(uint256 blockHeight, bytes calldata rawHeader, uint256 epochBaseTime) onlyAdmin external returns (bool) {
        S_External_Contracts memory cons = _loadExternalContracts();

        // update retarget context if a block later than the latest block is submitted
        if( latestHeight < blockHeight ) {
            S_RetargetContext memory memRetargetCTX;
            memRetargetCTX.nBits = rawHeader.parseUint32_bigend(72);

            if(_modRetargetBlockInterval(blockHeight) == 0) {
                memRetargetCTX.epochHeadTime = rawHeader.parseTimestamp();
            } else {
                require(epochBaseTime!=0, "invalid: epochBaseTime");
                memRetargetCTX.epochHeadTime = uint32( epochBaseTime );
            }
            // update retarget context
            _db_edit_RetargetHistory(cons.db, blockHeight -_modRetargetBlockInterval(blockHeight), memRetargetCTX);
            latestHeight = blockHeight;
        }

        // update pendingHeight
        _updatePendingHeight(cons.db, blockHeight, rawHeader.hash256_bigend());

        // confirm pending units (transaction output) over 6 block-aged
        _confirmPendingHeights(cons, latestHeight, 0);

        return true;
    }

    /**
	* @dev confirm units (transaction out) belongs to specific header by force
	* @param blockHeight the bitcoin block height
    * @param count the number of pending unit to confirm
	* @return true
	*/
    function confirmUnitsAtCheckpoints(uint256 blockHeight, uint256 count) onlyAdmin external returns (bool) {
        S_External_Contracts memory cons = _loadExternalContracts();
        _confirmPendingHeights(cons, blockHeight, count);
        return true;
    }

    /**
	* @dev entry function for requesting swap-out by an user
	* @param recipient user eth address (allow an address different from msg.sender)
    * @param btcAmount amount of bitcoin in Satoshi
	* @return true
	*/
    function swapOut(address recipient, uint256 btcAmount) external returns (bool) {
        address sender = msg.sender;
        if(recipient == address(0)) recipient = sender;
        return _outflowInternal(sender, sender, recipient, btcAmount, 1);
    }

    /**
	* @dev entry function for requesting swap-out by a BiFi handler contract
	* @param userAddr the user's eth address
    * @param btcAmount amount of bitcoin in Satoshi
    * @param actionType type indicator (withdraw, borrow or transferOut)
	* @return true
	*/
    function executeOutflow(address userAddr, uint256 btcAmount, uint256 actionType) external returns (bool) {
        _onlyContract(); // modifier
        return _outflowInternal(msg.sender, userAddr, userAddr, btcAmount, actionType);
    }

    /**
	* @dev Entry function to submit new Bitcoin block header and Bitcoin transaction
	* @param submitAt the index of target block header in block headers relayed
	* @param rawHeaders the binary of concatenated raw block headers
	* @param varsTX the Bitcoin txs and its proofs
	* @param output_indices an array of indices, each of indices is used for selecting target units (bitcoin_tx_out)
	* @return true
	*/
    function relay(
        uint256 submitAt,
        bytes calldata rawHeaders,
        S_TxProof calldata varsTX,
        uint256[][] calldata output_indices
    ) external returns (bool) {
        S_Memory_Context memory vars;
        // load external contracts
        S_External_Contracts memory cons = _loadExternalContracts();

        // TODO: improve code readability
        // "vars.targetHeight" does not mean any block height (since code size issue)
        // However it becomes target height after executing _checkHeaderChain function.
        require(submitAt < rawHeaders.length/Header_Length, "submit target height err");
        vars.targetHeight = submitAt;
        vars = _checkHeaderChain(cons, vars, _notChallenged(), rawHeaders);

        // "vars.challengeControl" is assigned by _checkChallenge() called by _checkHeaderChain()
        if(vars.challengeControl) return false;

        // push target header hash to pendingHeight
        _updatePendingHeight(cons.db, vars.targetHeight, vars.targetHash);

        // verify relayed transaction
        if( varsTX.rawTXs.length != 0 ) {
            bytes32[] memory txHashes = new bytes32[](varsTX.rawTXs.length);
            // merkle leaves by hashing each transactions
            for(uint256 tmp; tmp < varsTX.rawTXs.length; tmp++) {
                txHashes[tmp] = varsTX.rawTXs[tmp].hash256_littleend();
            }

            // verify merkle proof
            require(vars.targetHeader.parseMerkleRoot() == cons.libs.computeMultiMerkleRoot(txHashes, varsTX.merkleProof, varsTX.proofSwitches), "merkleRoot fail");

            // parsing units (transaction outputs) and store them
            for(uint256 i; i < txHashes.length; i++) {
                _storePendingUnits(cons, vars.targetHash, txHashes[i], varsTX.rawTXs[i], output_indices[i]);
            }
        }

        // update latest height
        vars.tmpUint = latestHeight;
        if(vars.tmpUint < vars.endHeight ) latestHeight = vars.tmpUint = vars.endHeight;

        // confirm pending units (transaction out) which is older than 6 block-aged
        _confirmPendingHeights(cons, vars.tmpUint, 0);

        // None-Relayer and Challenger cannot pass this line.
        _onlyRelayers();
        return true;
    }

    /**
    * @dev Entry function to submit Bitcoin transaction in the block header which has already been submitted
	* @param rawHeader the binary of a block header
	* @param varsTX the Bitcoin txs and its proofs
	* @param output_indices an array of indices, each of indices is used for selecting target units (bitcoin_tx_out)
	* @return true
	*/
    function relay_exist(
        bytes calldata rawHeader,
        S_TxProof calldata varsTX,
        uint256[][] calldata output_indices
    ) external returns (bool) {
        // cannot execute in challenge phase
        _notChallenged();
        // Relayer Only
        _onlyRelayers();

        // load external contracts
        S_External_Contracts memory cons = _loadExternalContracts();

        // check whether submitted header has been submitted before
        bytes32 targetHash = rawHeader.hash256_bigend();
        uint256 targetHeight = _db_get_heightByHash(cons.db, targetHash);
        require( targetHeight != 0, "not found target hash");

        // verify relayed transaction
        bytes32[] memory txHashes = new bytes32[](varsTX.rawTXs.length);
        // merkle leaves by hashing each transactions
        for(uint256 tmp; tmp<varsTX.rawTXs.length; tmp++) {
            txHashes[tmp] = varsTX.rawTXs[tmp].hash256_littleend();
        }

        // verify merkle proof
        require(rawHeader.parseMerkleRoot() == cons.libs.computeMultiMerkleRoot(txHashes, varsTX.merkleProof, varsTX.proofSwitches), "merkleRoot fail");

        // parsing units (transaction outputs) and store them
        for(uint256 i; i<varsTX.rawTXs.length; i++) {
            // TODO opti: optimization DS call count
            _storePendingUnits(cons, targetHash, txHashes[i], varsTX.rawTXs[i], output_indices[i]);
        }

        // confirm pending units (transaction out) which is older than 6 block-aged
        // TODO _updatePendingHeight(cons.db, targetHeight, targetHash);
        _confirmPendingHeights(cons, latestHeight, 0);

        return true;
    }

    /**
	* @dev determine which branch is the main branch between the existing branch and the challenge branch.
	* @param rawHeaders the binary of concatenated raw block headers
	* @return true
	*/
    function resolveChallenge(
        bytes calldata rawHeaders
    ) external returns (bool) {
        S_Memory_Context memory vars;
        // load external contracts
        S_External_Contracts memory cons = _loadExternalContracts();

        // TODO: improve code readability
        // "vars.targetHeight" does not mean any block height (since code size issue)
        // However it becomes target height after executing _checkHeaderChain function.
        vars.targetHeight = (rawHeaders.length / Header_Length) -1;
        vars = _checkHeaderChain(cons, vars, _challenged(), rawHeaders);

        // it is always linked to the latest header when a header is submitted with this function
        latestHeight = vars.endHeight;

        // push target header hash to pendingHeight
        _updatePendingHeight(cons.db, vars.endHeight, vars.endHash);

        // confirm pending units (transaction output) over 6 block-aged
        _confirmPendingHeights(cons, vars.endHeight, 0);
        return true;
    }

    /**
	* @dev return the pending block heights
	* @return array of pendingHeights
	*/
    function getPendingHeights() external view returns (uint64[] memory) {
        return pendingHeights.data;
    }
}