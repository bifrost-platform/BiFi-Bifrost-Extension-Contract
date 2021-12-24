// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../libs/proxy/ProxyStorage.sol";
import "../../interfaces/IBIFIHandlerProxy.sol";
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IERC20.sol";

import "../../interfaces/IBTC_DB.sol";
import "../../interfaces/IBTCPureLib.sol";
import "../../interfaces/IFund.sol";

import "../../interfaces/IChainlinkPriceFeed.sol";
import "../../interfaces/IUniswapV2Pair.sol";

import "./BTCDataStructure.sol";

import "../utils/L_PendingHeights.sol";

/**
* @title BiFi-Bifrost-Extension BTCState Contract
* @notice Internal storage Contract used by Bitcoin Contract
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract BTCState is ProxyStorage, BTCDataStructure {
    using L_PendingHeights for S_PendingHeights;

    mapping(address => uint256) public roles;

    IBTC_DB public database;
    IFund public fund;
    IAddressResolver public resolver;
    IBTCPureLib public btclib;

    IBIFIHandlerProxy public handler;
    IERC20 public BiBTC;
    IERC20 public BFC;

    S_ChallengeContext public challengeCTX;
    S_RetargetContext public retargetCTX; // retarget with challenge

    S_PendingHeights pendingHeights;

    uint256 public latestHeight;
    uint256 public Confirm_Guarantee;

    uint256 public relayerStake;
    uint256 public challengerStake;

    uint256 public outflowTimeout;
    uint256 public challengeTimeout;

    uint256 constant Header_Length         = 80;

    uint256 constant RetargetBlockInterval = 2016;
    uint256 constant ReTargetTimeInterval  = 1209600; // 3600 * 24 * 7 * 2

    uint256 constant MAX_Target = 0xffff0000000000000000000000000000000000000000000000000000; // (2**16-1) << 208

    /**
    * @dev set confirm_guarantee which is number of bitcoin confirmation blocks (in general, 6)
    * @param _confirms value to be set
	*/
    function setConfirm_Guarantee(uint256 _confirms) external onlyAdmin {
        Confirm_Guarantee = _confirms;
    }

    /**
    * @dev set internal buffer size of pending bitcoin block heights
    * @param _size value to be set
	*/
    function initPendingHeights(uint64 _size) onlyAdmin external {
        pendingHeights.init(_size);
    }

    /**
    * @dev set amount required to get Relayer Rights
    * @param _relayerStake value to be set
	*/
    function setRelayerStake(uint256 _relayerStake) onlyAdmin external {
        relayerStake = _relayerStake;
    }

    /**
    * @dev set amount required for challenger to submit challenge
    * @param _challengerStake value to be set
	*/
    function setChallengerStake(uint256 _challengerStake) onlyAdmin external {
        challengerStake = _challengerStake;
    }

    /**
    * @dev set time limit for the outflow process to be completed
    * @param _limit value to be set
	*/
    function setOutflowTimeout(uint256 _limit) onlyAdmin external {
        outflowTimeout = _limit;
    }

    /**
    * @dev set time limit for the challenge process to be completed
    * @param _challengeTimeout value to be set
	*/
    function setChallengeTimeout(uint256 _challengeTimeout) onlyAdmin external {
        challengeTimeout = _challengeTimeout;
    }

    /**
    * @dev set the "BiFi handler" address
    * @param handlerAddr address to be set
	*/
    function setHandler(address handlerAddr) onlyAdmin external {
        handler = IBIFIHandlerProxy( handlerAddr );
        roles[handlerAddr] = 4;
        // token approve to BiFi system
        IERC20(BiBTC).approve(handlerAddr, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    /**
    * @dev set the "Address Resolver" address
    * @param resolverAddr address to be set
	*/
    function setAddressResolver(address resolverAddr) onlyAdmin external {
        resolver = IAddressResolver( resolverAddr );
    }

    /**
    * @dev set the "wrapped Bitcoin" token address
    * @param _BiBTC address to be set
	*/
    function setBiBTC(address _BiBTC) onlyAdmin external {
        BiBTC = IERC20(_BiBTC);
    }

    /**
    * @dev set the "Bifrost token" address
    * @param _BFC address to be set
	*/
    function setBFCtoken(address _BFC) onlyAdmin external {
        BFC = IERC20(_BFC);
    }

    /**
    * @dev set the "External DataBase" address
    * @param DSaddr address to be set
	*/
    function setDataBase(address DSaddr) onlyAdmin external {
        database = IBTC_DB(DSaddr);
    }

    /**
    * @dev set the "BTCPureLibs" address
    * @param btcLibAddr address to be set
	*/
    function setbtclib(address btcLibAddr) onlyAdmin external {
        btclib = IBTCPureLib(btcLibAddr);
    }

    /**
    * @dev set the "Fund" address
    * @param fundAddr address to be set
	*/
    function setFundAddr(address fundAddr) onlyAdmin external {
        fund = IFund(fundAddr);
    }
}