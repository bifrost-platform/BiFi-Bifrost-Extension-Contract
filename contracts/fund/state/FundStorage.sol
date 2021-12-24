// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../libs/proxy/ProxyStorage.sol";
import "./FundStructure.sol";

import "../../interfaces/IChainlinkPriceFeed.sol";
import "../../interfaces/IUniswapV2Pair.sol";

import "../../interfaces/IERC20.sol";

/**
* @title BiFi-Bifrost-Extension FundStorage Contract
* @notice Contract for internal storage of fund
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract FundStorage is ProxyStorage, FundStructure {
    IChainlinkPriceFeed BTC_ETH_18;
    IUniswapV2Pair BFC_ETH_18;

    IERC20 public BiBTC;
    IERC20 public BFC;

    uint256 public inflowFeeRate; // 0.5%
    uint256 public outflowFeeRate; // 0.5%
    uint256 public outflowMinFee; // 0.01 bitcoin == 1000000 Satoshi

    uint256 public pendingBTCFeeSum;
    uint256 public pendingBFCFeeSum;

    address[] public relayers;
    mapping(address=>uint256) relayerStakes;

    function setBiBTC(IERC20 _BiBTC) onlyAdmin external {
        BiBTC = _BiBTC;
    }

    function setBFC(IERC20 _BFC) onlyAdmin external {
        BFC = _BFC;
    }

    function setBTC_ETH_18Addr(IChainlinkPriceFeed _BTC_ETH_18) onlyAdmin external returns (bool) {
        BTC_ETH_18 = _BTC_ETH_18;
        return true;
    }

    function setBFC_ETH_18Addr(IUniswapV2Pair _BFC_ETH_18) onlyAdmin external returns (bool) {
        BFC_ETH_18 = _BFC_ETH_18;
        return true;
    }

    function setInflowFeeRate(uint256 _inflowFeeRate) onlyAdmin external returns (bool) {
        inflowFeeRate = _inflowFeeRate;
        return true;
    }
    function setOutflowFeeRate(uint256 _outflowFeeRate) onlyAdmin external returns (bool) {
        outflowFeeRate = _outflowFeeRate;
        return true;
    }
    function setOutflowMinFee(uint256 _outflowMinFee) onlyAdmin external returns (bool) {
        outflowMinFee = _outflowMinFee;
        return true;
    }

    function withdrawFund() onlyAdmin external {
        address _sender = msg.sender;
        address _this = address(this);
        IERC20 _erc20;
        _erc20 = BiBTC;
        _erc20.transfer(_sender, _erc20.balanceOf(_this));

        _erc20 = BFC;
        _erc20.transfer(_sender, _erc20.balanceOf(_this));
    }
}