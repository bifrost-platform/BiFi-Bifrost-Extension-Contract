// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./state/FundStorage.sol";

/**
* @title BiFi-Bifrost-Extension FundInternal Contract
* @notice Contract for fund logics
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract FundInternal is FundStorage {
    uint256 constant unifiedPoint = 10**18;

    function _getPrice_btc_bfc18() public view returns (uint256 unifiedPrice) {
        uint256 btc_eth_18 = uint256( BTC_ETH_18.latestAnswer() );

        uint256 bfc_eth_18;
        (uint256 r0, uint256 r1, ) = BFC_ETH_18.getReserves();
        bfc_eth_18 = unifiedDiv(r1, r0);

        unifiedPrice = unifiedDiv(btc_eth_18, bfc_eth_18);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        a > b ? result = a : result = b;
    }

    function getRatioAmount(uint256 amount, uint256 score, uint256 total) internal pure returns(uint256) {
        return unifiedMul(amount, unifiedDiv(score*unifiedPoint, total*unifiedPoint));
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a*b/unifiedPoint;
    }
    function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a*unifiedPoint/b;
    }
}