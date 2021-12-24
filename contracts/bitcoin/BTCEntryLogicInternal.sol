// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./BTCModifier.sol";
import "./events/BTCEvents.sol";

import "./utils/L_Bytes.sol";
import "./utils/L_PendingHeights.sol";

/**
* @title BiFi-Bifrost-Extension BTCEntryLogicInternal Contract
* @notice Contract for Bitcoin Internal logics
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract BTCEntryLogicInternal is
    BTCModifier,
    BTCEvents
{
    using L_Bytes for bytes;
    using L_PendingHeights for S_PendingHeights;

    /**
	* @dev struct for avoid "Stack Too Deep" error
	*/
    struct S_Memory_Context {
        bool challengeControl;

        uint256 tmpUint;
        bytes tmpHeader;

        bytes32 tmpPreHash;
        bytes32 tmpHash;

        uint256 tmpTarget;

        uint256 thisEpochHeadUpdate;
        uint256 nextEpochHeadUpdate;
        uint256 retargetUpdateHeader;

        uint256 thisEpochHead;
        uint256 nextEpochHead;
        uint256 thisEpochTail;

        uint256 numHeaders;

        uint256 anchorHeight;
        bytes32 anchorHash;

        bytes targetHeader;
        uint256 targetHeight;
        bytes32 targetHash;

        uint256 endHeight;
        bytes32 endHash;
    }

    /**
	* @dev struct for avoid "Stack Too Deep" error
	*/
    struct S_Memory_RetargetCTX {
        S_RetargetContext current;
        S_RetargetContext next;
    }

    /**
	* @dev the struct contains interfaces of external contracts
	*/
    struct S_External_Contracts {
        IBTC_DB db;
        IBTCPureLib libs;
        IBIFIHandlerProxy handler;
        IFund fund;
        IERC20 BiBTC;
        IAddressResolver resolver;
    }

    /**
	* @dev load interfaces of external contracts from the storage
    * @return cons struct which has interfaces of external contracts
	*/
    function _loadExternalContracts() internal view returns (S_External_Contracts memory cons) {
        cons.db = database;
        cons.libs = btclib;
        cons.handler = handler;
        cons.fund = fund;
        cons.BiBTC = BiBTC;
        cons.resolver = resolver;
    }

    /**
	* @dev main implementation of outflow process
	* @param requestSender eth-address of outflow action requester
	* @param feePayer the eth-address of outflow fee payer
	* @param recipient the eth-address to determine recipient's Bitcoin address
    * @param btcAmount requested BTC amount (in Satoshi)
    * @param actionType type indicator (withdraw, borrow or transferOut)
	* @return true
	*/
    function _outflowInternal(address requestSender, address feePayer, address recipient, uint256 btcAmount, uint256 actionType) internal returns (bool) {
        // cannot execute in challenge phase
        _notChallenged();

        address thisAddress = address(this);
        // load external contracts
        S_External_Contracts memory cons = _loadExternalContracts();

        // check whether the user already requested.
        S_Outflow memory memOutflow = _db_get_outflowInfo(cons.db, recipient);
        require(!memOutflow.requested, "working outflow exists");

        // burn BifrostBTC token
        cons.BiBTC.burnFrom(requestSender, btcAmount);

        // calculate outflow fee amount and pay it
        uint256 BFCFee;
        (btcAmount, BFCFee) = cons.fund.calcOutflowFee(btcAmount);
        _BFC_transferFrom(BFC, feePayer, address(cons.fund), BFCFee);
        cons.fund.add_pendingBFCFee(BFCFee);

        // construct outflow context and store it
        memOutflow.requested = true;
        memOutflow.pendingAmount = uint64(btcAmount);
        memOutflow.timeLimit = uint128(block.number + outflowTimeout);
        cons.db.set_outflowInfo(recipient, memOutflow);

        // find the recipient BTC address by ether address
        (address refundPubkeyHash, uint32 addressFormatType) = resolver.getRefundAddr(recipient);
        require(refundPubkeyHash != address(0), "not found the refund address");

        // emit outflow event, it may be utilized by the Bifrost and Relayers
        emit OutFlow(recipient, refundPubkeyHash, addressFormatType, actionType, memOutflow.pendingAmount, memOutflow.timeLimit);

        return true;
    }

    /**
	* @dev check whether range of batch block headers satisfies some conditions
    * @param anchorHeight the previous block height of relayed batch headers
    * @param endHeight the latest block height of relayed batch headers
    * @param endHash the latest block hash of relayed batch headers
    * @param targetHeight the height of target block header (may include target transaction)
    * @param targetHash the height of target block header (may include target transaction)
    * @return true if challenge occurs by this submission (if not, false)
	*/
    function _checkChallenge(
        S_External_Contracts memory cons,
        uint256 anchorHeight,
        uint256 endHeight,
        bytes32 endHash,
        uint256 targetHeight,
        bytes32 targetHash
    ) internal returns (bool) {
        S_PendingHeightsPointer memory ptr;
        uint64[] memory _pendingHeights;
        bytes32 tmpHash;

        // read all pending block heights
        (ptr, _pendingHeights) = pendingHeights.peeks();

        // Batch headers must not include pending heights already stored in the Bitcoin contract.
        for(uint256 i; i < _pendingHeights.length; i++) {
            if(_pendingHeights[i] == 0) continue; // skip the empty blocks
            require(_pendingHeights[i] <= anchorHeight || endHeight <= _pendingHeights[i], "invalid: relay headers range");
        }

        tmpHash = _db_get_hashByHeight(cons.db, endHeight);
        if(tmpHash == endHash) {
            // In case of general submission (not to latest pending height)
            return false;
        } else if (tmpHash == bytes32(0)) {
            // In case of general submission (to latest pending height)
            require(latestHeight == anchorHeight, "invalid: case2");
            return false;
        } else { // else if (tmpHash != bytes32(0))
            // In case of submission that raises a challenge

            // A challenge cannot be raised at the confirmed height.
            if(_db_get_heightByHash(cons.db, tmpHash) < ptr.min) revert("challenge to confirmed");

            // Set challenge context
            S_ChallengeContext memory ctx;
            ctx.challenger = msg.sender;
            ctx.challenged = true;
            ctx.challengeBTCheight = uint64(targetHeight);
            ctx.challengeETHheight = uint64(block.number);
            ctx.challengeHash = targetHash;
            ctx.challengeFeeAmount = challengerStake;

            // Charge a challenger fee.
            _BFC_transferFrom(BFC, ctx.challenger, address(this), ctx.challengeFeeAmount);

            // Store challenge context
            cons.db.set_challengeHistory(targetHash, ctx);
            challengeCTX = ctx;

            // return true
            return ctx.challenged;
        }
    }

    /**
	* @dev store new block header
    * @param _db the interface of external database contract
    * @param targetHeight the block height to be added
    * @param targetHash the block hash to be added
	*/
    function _updatePendingHeight(
        IBTC_DB _db,
        uint256 targetHeight,
        bytes32 targetHash
    ) internal {
        // Register height
        uint64 number = uint64(targetHeight);
        _db.set_hashAndHeightInfo(targetHash, number);
        pendingHeights.push(number);
    }

    /**
	* @dev check validity of relayed batch headers
    * @param cons the interfaces of external contracts
    * @param vars the context for the submission
    * @param challengeResolveFlag true when the submission for challenge resolution (or false)
    * @param rawHeaders the binary of relayed batch headers
    * @return updated context of the submission
	*/
    function _checkHeaderChain(
        S_External_Contracts memory cons,
        S_Memory_Context memory vars,
        bool challengeResolveFlag,
        bytes memory rawHeaders
    ) internal returns (
        S_Memory_Context memory
    ) {
        vars.numHeaders = rawHeaders.length / Header_Length;
        S_Memory_RetargetCTX memory memRetargetCTX;

        // parse anchorHash that means previous block hash of relayed batch headers
        vars.tmpHeader = rawHeaders.sliceHeader(0);
        vars.anchorHash = vars.tmpPreHash = vars.tmpHeader.parsePreHash();

        // In case of challenge resolution
        if(challengeResolveFlag) {
            // batch must have sufficient block headers
            require(vars.numHeaders >= Confirm_Guarantee, "too short headers in resolve");

            S_ChallengeContext memory ctx = challengeCTX;

            // check challenge resolution timeout
            if(ctx.challengeETHheight + challengeTimeout >= block.number) {
                // Case of Challenger wins
                if( vars.anchorHash == ctx.challengeHash) {
                    require(ctx.challenger == msg.sender, "only challenger resolve");

                    // rollback the header chain
                    _rollbackPendingHeights(cons.db, cons.resolver, ctx.challengeBTCheight);

                    // apply this submission to the header chain
                    vars.anchorHeight = ctx.challengeBTCheight;
                    vars.endHeight = vars.anchorHeight + vars.numHeaders;
                    latestHeight = ctx.challengeBTCheight;
                    _updatePendingHeight(cons.db, ctx.challengeBTCheight, ctx.challengeHash);
                    vars.tmpUint = ctx.challengeBTCheight - _modRetargetBlockInterval(ctx.challengeBTCheight);
                    memRetargetCTX.current = retargetCTX;
                    _db_edit_RetargetHistory(cons.db, vars.tmpUint, memRetargetCTX.current);

                }
                // Case of Relayer wins (challenge fails)
                else if (vars.anchorHash == _db_get_hashByHeight(cons.db, ctx.challengeBTCheight)) {
                    _onlyRelayers();

                    // check existence of anchor block
                    vars.anchorHeight = _db_get_heightByHash(cons.db, vars.anchorHash);
                    require( vars.anchorHeight != 0, "anchor Hash fail in resolve");

                    vars.endHeight = vars.anchorHeight + vars.numHeaders;
                } else {
                    revert("undefined resolve");
                }
                // resolve: A Resolver takes fee challenger paid (The winning challenger gets the fee he paid back)
                BFC.transfer(msg.sender, ctx.challengeFeeAmount);
            } else {
                _onlyRelayers();

                // check existence of anchor block
                vars.anchorHeight = _db_get_heightByHash(cons.db, vars.anchorHash);
                require( vars.anchorHeight != 0, "anchor Hash fail in resolve");

                vars.endHeight = vars.anchorHeight + vars.numHeaders;
                // timeout: A Resolver cannot takes fee challenger paid
                BFC.transfer(address(cons.fund), ctx.challengeFeeAmount);
            }

            // challenge phase done: delete context(retarget and challenge)
            delete retargetCTX;
            delete challengeCTX;
        }
        // In case of general submissions (not case of challenge resolution)
        else {
            // check existence of anchor block
            vars.anchorHeight = _db_get_heightByHash(cons.db, vars.tmpPreHash);
            require( vars.anchorHeight != 0, "relay anchor Hash fail");

            vars.endHeight = vars.anchorHeight + vars.numHeaders;
        }

        // pre-calculate the parameter of retarget process
        vars.thisEpochHead = vars.anchorHeight - _modRetargetBlockInterval(vars.anchorHeight);
        vars.nextEpochHead = vars.thisEpochHead + RetargetBlockInterval;
        vars.thisEpochTail = vars.nextEpochHead-1;

        memRetargetCTX.current = cons.db.get_RetargetHistory(vars.thisEpochHead);
        memRetargetCTX.next = cons.db.get_RetargetHistory(vars.nextEpochHead);

        // find current epoch tail(for update next nBits)
        if( vars.thisEpochTail <= vars.endHeight &&
            RetargetBlockInterval-1 != _modRetargetBlockInterval(vars.anchorHeight)
        ) {
            vars.thisEpochHeadUpdate = vars.thisEpochHead;
            vars.nextEpochHeadUpdate = vars.nextEpochHead;

            // to submit index
            vars.retargetUpdateHeader = vars.thisEpochTail - vars.anchorHeight-1;
            vars.retargetUpdateHeader *= Header_Length;
        } else {
            // does not retarget on this submission
            vars.retargetUpdateHeader = type(uint256).max;
        }

        vars.tmpTarget = _nBitsToDifficultyTarget(memRetargetCTX.current.nBits);
        if(vars.retargetUpdateHeader == 0) {
            (memRetargetCTX, vars.tmpTarget) = _calcEpochRetarget(memRetargetCTX, vars.tmpHeader.parseTimestamp(), vars.tmpTarget);
        }

        // validate relayed batch block header
        for(uint256 i = Header_Length; i < rawHeaders.length; i += Header_Length) {
            vars.tmpHash = vars.tmpHeader.hash256_bigend();

            vars.tmpHeader = rawHeaders.sliceHeader(i);
            vars.tmpPreHash = vars.tmpHeader.parsePreHash();

            require(vars.tmpTarget >= uint256(vars.tmpHash), "invalid intermediate difficulty");
            require(vars.tmpPreHash == vars.tmpHash, "broken header chain");

            if(i == vars.retargetUpdateHeader) {
                (memRetargetCTX, vars.tmpTarget) = _calcEpochRetarget(memRetargetCTX, vars.tmpHeader.parseTimestamp(), vars.tmpTarget);
            }
        }

        // check difficulty of last block header in the batch block headers
        vars.endHash = vars.tmpHeader.hash256_bigend();
        if(vars.endHeight != vars.thisEpochTail)
            require(vars.tmpTarget >= uint256(vars.endHash), "invalid end difficulty");
        else
            require(_nBitsToDifficultyTarget(memRetargetCTX.current.nBits) >= uint256(vars.endHash), "invalid end difficulty");

        // update retarget context(epoch head)
        // find next epoch head
        if( vars.nextEpochHead <= vars.endHeight ) {
            vars.nextEpochHeadUpdate = vars.nextEpochHead;
            vars.tmpUint = RetargetBlockInterval-1 -_modRetargetBlockInterval(vars.anchorHeight);
            // vars.thisEpochHeadUpdate = vars.endHeight - _modRetargetBlockInterval(vars.endHeight);

            vars.tmpHeader = rawHeaders.sliceHeader(vars.tmpUint*Header_Length);
            memRetargetCTX.next.epochHeadTime = vars.tmpHeader.parseTimestamp();
        }

        vars.tmpUint = vars.targetHeight*Header_Length;
        vars.targetHeader = rawHeaders.sliceHeader(vars.tmpUint);
        vars.targetHash = vars.targetHeader.hash256_bigend();

        // calculate target height
        vars.targetHeight += vars.anchorHeight+1;
        if(!challengeResolveFlag) {
            vars.challengeControl = _checkChallenge(cons, vars.anchorHeight, vars.endHeight, vars.endHash, vars.targetHeight, vars.targetHash);
        }

        // retarget and store updated retarget context
        if( vars.thisEpochHeadUpdate != 0) {
            if(!vars.challengeControl) {
                retargetCTX.epochTailTime = memRetargetCTX.current.epochTailTime;
                _db_edit_RetargetHistory(cons.db, vars.thisEpochHead, memRetargetCTX.current);
                _db_edit_RetargetHistory(cons.db, vars.nextEpochHead, memRetargetCTX.next);
            }
        }
        if( vars.nextEpochHeadUpdate != 0 ) {
            if(!vars.challengeControl) {
                retargetCTX.epochHeadTime = memRetargetCTX.next.epochHeadTime;
                _db_edit_RetargetHistory(cons.db, vars.nextEpochHead, memRetargetCTX.next);
            }
        }
        return vars;
    }

    /**
	* @dev parse unit (transaction out) and store it under target hash
    * @param cons the interfaces of external contracts
    * @param targetHash the header hash of units will store(input param of unitID hashing)
    * @param tmpTXHash the txHash contains units(input param of unitID hashing)
    * @param rawTX the bytes TX contains units information
    * @param units_indices the indices of TX outputs
	*/
    function _storePendingUnits(
        S_External_Contracts memory cons,
        bytes32 targetHash,
        bytes32 tmpTXHash,
        bytes memory rawTX,
        uint256[] memory units_indices
    ) internal {
        // parse units (transaction out) from raw transactions
        S_Unit[] memory units = cons.libs.parse_unit_from_rawTX(rawTX, units_indices);

        address userAddr;
        for(uint256 i; i < units_indices.length; i++) {
            // get user's eth address related to pubkey hash
            (userAddr, units[i].status) = _resolver_getCustomerETHAddr(cons.resolver, units[i].BTCaddr);

            if (units[i].status == 1) {
                // outflow
                if(_outRequestCheck(_db_get_outflowInfo(cons.db, userAddr), units[i].amount) < block.number) {
                    cons.resolver.penaltyTransfer(userAddr, units[i].amount);
                }
            } else {
                // inflow
                cons.db.add_inflowPending(userAddr, units[i].amount);
            }
        }
        cons.db.register_units(targetHash, tmpTXHash, units_indices, units);
    }

    /**
	* @dev confirm the pending block heights that are old enough.
    * @param cons the interfaces of external contracts
    * @param targetHeight the current block height
    * @param count the number of confirming units on a each height
	*/
    function _confirmPendingHeights(
        S_External_Contracts memory cons,
        uint256 targetHeight,
        uint256 count
    ) internal {
        // get block heights bigger than [currentHeight - confirm_guarantee].
        (bool success, uint64[] memory targets) = pendingHeights.pops(uint64(targetHeight-Confirm_Guarantee));

        // confirm units (transaction out) popped above
        if(success) {
            for(uint256 i; i < targets.length; i++) {
                if(targets[i] == 0) break; //check end (or empty)
                _confirmUnits(cons, targets[i], count);
            }
        }
    }

    /**
	* @dev confirm units (transaction out) under the target blocks
    * @param cons the interfaces of external contracts
    * @param targetHeight the height of block which contains units to be confirmed
    * @param count the number of units to be confirmed
	*/
    function _confirmUnits(
        S_External_Contracts memory cons,
        uint256 targetHeight,
        uint256 count
    ) internal returns (bool) {
        // pops units (transaction out) to be confirmed
        S_Unit[] memory units = _popUnitIDsByHeight(cons.db, targetHeight, count);

        address userAddr;
        address _this = address(this);
        for(uint256 i; i < units.length; i++) {
            // get user's eth address related to pubkeyKey hash
            (userAddr, units[i].status) = _resolver_getCustomerETHAddr(cons.resolver, units[i].BTCaddr);

            if (units[i].status == 1) {
                // outflow
                _outRequestCheck(_db_pop_outflowInfo(cons.db, userAddr), units[i].amount);
            } else {
                // inflow
                _db_sub_inflowPending(cons.db, userAddr, units[i].amount);
                // determine a fee amount and deducted amount
                (uint64 _amount, uint64 _fee) = cons.fund.calcInflowFee(units[i].amount);

                // In case of "transferIn" (swap across blockchains) action
                if (units[i].status == 2) _BiBTC_mint(cons.BiBTC, userAddr, _amount);
                else {
                    // TODO opti: mint tokens in the sum of all inflow units (for gas optimizations)
                    _BiBTC_mint(cons.BiBTC, _this, _amount);
                    if (units[i].status == 3) {
                        // deposit tokens to the user
                        callHandlerViewProxy(cons.handler, cons.handler.depositTo.selector, userAddr, _amount);
                    } else if (units[i].status == 4) {
                        // repay the user's loan
                        callHandlerViewProxy(cons.handler, cons.handler.repayTo.selector, userAddr, _amount);
                    }
                }
                // update fund by adding fee
                cons.fund.add_pendingBTCFee(_fee);
            }
        }

        return true;
    }

    /**
	* @dev call the BiFi handler's function
    * @param _handler interface of the BiFi handler
    * @param _selector function selector ("depositTo" or "repayTo")
    * @param userAddr the recipient's eth address
    * @param btcAmount the depositing (or repaying) amount
	*/
    function callHandlerViewProxy(IBIFIHandlerProxy _handler, bytes4 _selector, address userAddr, uint64 btcAmount) internal {
        bool success; bytes memory returnData;
        (success, returnData) = _handler.handlerViewProxy(
                    abi.encodeWithSelector(
                        _selector,
                        userAddr, _btcToUnified(btcAmount), false
                    )
                );
        require(success, string(returnData));
    }

    /**
	* @dev rollback (remove) pending heights in pendingHeights, bigger than or equal to target height
    * @param _db the interface of external database
    * @param _resolver the interface of external address resolver
    * @param targetHeight the height of rollback position
	*/
    function _rollbackPendingHeights(IBTC_DB _db, IAddressResolver _resolver, uint256 targetHeight) internal {
        // get block heights bigger than or equal to "targetHeight"
        (bool success, uint64[] memory targets) = pendingHeights.rollbackPops(uint64(targetHeight));

        if(success) {
            S_Unit[] memory units;
            address userAddr;

            for(uint256 i; i < targets.length; i++) {
                if(targets[i] == 0) break; // check end (or empty)

                // pops units (transaction outs) under the target height
                units = _popUnitIDsByHeight(_db, targets[i], 0);

                for(uint256 j; j < units.length; j++) {
                    // get user's eth address related to pubkey hash
                    (userAddr, units[j].status) = _resolver_getCustomerETHAddr(_resolver, units[j].BTCaddr);

                    if (units[j].status == 1) {
                        // outflow
                        _outRequestCheck(_db_pop_outflowInfo(_db, userAddr), units[j].amount);
                    } else {
                        // inflow
                        _db_sub_inflowPending(_db, userAddr, units[j].amount);
                    }
                }
                _db.set_hashByHeight(targets[i], 0);
            }
        }
    }

    /**
	* @dev check outflow information
    * @param memOut information of outflow request in the past
    * @param amount the amount of relayed unit (transaction out)
    * @return outflow limit of time
	*/
    function _outRequestCheck(S_Outflow memory memOut, uint64 amount) internal pure returns (uint128) {
        require(memOut.requested, "not requested outflow");
        require(memOut.pendingAmount == amount, "different outflow amounts");
        return memOut.timeLimit;
    }

    /**
	* @dev calculate remainder after dividing the value by 2016
    * @return remainder
	*/
    function _modRetargetBlockInterval(uint256 value) internal pure returns (uint256) {
        return value % RetargetBlockInterval;
    }

    /**
	* @dev pop unit (transaction out) under the block height
    * @param _db interface of external database
    * @param targetHeight the block height containing the unit
    * @param count the number of popped units
    * @return popped units
	*/
    function _popUnitIDsByHeight(IBTC_DB _db, uint256 targetHeight, uint256 count) internal returns (S_Unit[] memory) {
        if(count == 0) return _db.pop_unitIDsAtHeight(targetHeight);
        else return _db.pop_unitIDsAtHeight(targetHeight, count);
    }

    /**
	* @dev decimal converter: btc decimal(8) to BiFi handler decimal(18)
    * @param _amount BTC amount (in Satoshi)
    * @return amount in 18-decimal
	*/
    function _btcToUnified(uint64 _amount) internal pure returns (uint256) {
        // return uint256(_amount)*1000000000000000000/100000000;
        return uint256(_amount)*10000000000;
    }

    /**
	* @dev retarget algorithm (update bitcoin difficulty)
    * @param memRetargetCTX the retarget context
    * @param _epochTailTime The tail timestamp of the current 2016-epoch
    * @return updated retarget context
    * @return the difficulty target of the next 2016-epoch
	*/
    function _calcEpochRetarget(
        S_Memory_RetargetCTX memory memRetargetCTX,
        uint32 _epochTailTime,
        uint256 tmpTarget
    ) internal pure returns (
        S_Memory_RetargetCTX memory,
        uint256
    ) {
        // update retarget context
        memRetargetCTX.current.epochTailTime = _epochTailTime;
        tmpTarget = _epochDifficultyRetargetAlgorithm(memRetargetCTX.current.epochTailTime, tmpTarget, memRetargetCTX.current.epochHeadTime);
        memRetargetCTX.next.nBits = _difficultyTargetTonBITs(tmpTarget);

        return (memRetargetCTX, tmpTarget);
    }

    /**
	* @dev calculate next difficulty target
    * @param _epochTailTime the tail timestamp of the current 2016-epoch
    * @param _epochDifficultyTarget the difficulty target of the current 2016-epoch
    * @param _epochBaseTime the head timestamp of the current 2016-epoch
    * @return _tmp next difficulty target (next difficulty target)
	*/
    function _epochDifficultyRetargetAlgorithm(
        uint256 _epochTailTime,
        uint256 _epochDifficultyTarget,
        uint256 _epochBaseTime
    ) internal pure returns (uint256 _tmp) {
        // get elapsed time of the current 2016-epoch
        _tmp = _epochTailTime - _epochBaseTime;

        // revise the elapsed time within the defined range. (MAX: 8 weeks, MIN: half week)
        if( _tmp > ReTargetTimeInterval << 2) _tmp = ReTargetTimeInterval << 2;
        if( _tmp < ReTargetTimeInterval >> 2) _tmp = ReTargetTimeInterval >> 2;

        // calculate new difficulty target
        if(ReTargetTimeInterval < _tmp) _tmp = _epochDifficultyTarget / ReTargetTimeInterval * _tmp;
        else _tmp = _epochDifficultyTarget * _tmp / ReTargetTimeInterval;

        if(_tmp > MAX_Target) _tmp = MAX_Target;
    }

    /**
	* @dev convert nBits to difficulty target
    * @param nBits nbits value
    * @return difficulty target value related to the nbits
	*/
    function _nBitsToDifficultyTarget(uint256 nBits) internal pure returns (uint256) {
        // return (nBits&0xffffff) * 256**((nBits>>24)-3);
        // return (nBits&0xffffff) << 8*((nBits>>24)-3);
        return (nBits&0xffffff) << (nBits>>21)-24;
    }

    /**
	* @dev convert difficulty target to nBits
    * @param _difficultyTarget the difficulty target value
    * @return nbits related to the difficulty target
	*/
    function _difficultyTargetTonBITs(uint256 _difficultyTarget) internal pure returns (uint32) {
        uint256 i;
        uint256 firstByte = 0xFF00000000000000000000000000000000000000000000000000000000000000;

        // find first index
        while(true) {
            if( ( (_difficultyTarget << i) & firstByte ) != 0 ) {

                if((_difficultyTarget << i) & firstByte > 0x7F00000000000000000000000000000000000000000000000000000000000000) {
                    // exception case.
                    if(i!=0) i-=8;
                }
                break;
            }
            i+=8;
        }

        // return uint32( ( (256-i)/8 << 24) | _difficultyTarget & 0xFFFFFF );
        return uint32( ( (256-i) << 21) | (_difficultyTarget >> (232-i)) & 0xFFFFFF );
    }


    /// @notice simple wrapper functions below (for optimizing code size)

    function _BiBTC_mint(IERC20 _BiBTC, address _userAddr, uint64 _amount) internal {
        _BiBTC.mint(_userAddr, _amount);
    }
    function _resolver_getCustomerETHAddr(IAddressResolver _resolver, address _btcAddr) internal view returns (address, uint32) {
        return _resolver.getCustomerETHAddr(_btcAddr);
    }
    function _db_get_heightByHash(IBTC_DB _db, bytes32 _hash) internal view returns (uint64) {
        return _db.get_heightByHash(_hash);
    }
    function _db_get_hashByHeight(IBTC_DB _db, uint256 key) internal returns (bytes32) {
        return _db.get_hashByHeight(key);
    }
    function _db_edit_RetargetHistory(IBTC_DB _db, uint256 key, S_RetargetContext memory _retargetCTX) internal {
        _db.edit_RetargetHistory(key, _retargetCTX);
    }
    function _db_pop_outflowInfo(IBTC_DB _db, address userAddr) internal returns (S_Outflow memory) {
        return _db.pop_outflowInfo(userAddr);
    }
    function _db_get_outflowInfo(IBTC_DB _db, address userAddr) internal returns (S_Outflow memory) {
        return _db.get_outflowInfo(userAddr);
    }
    function _db_sub_inflowPending(IBTC_DB _db, address userAddr, uint64 amount) internal {
        _db.sub_inflowPending(userAddr, amount);
    }
}