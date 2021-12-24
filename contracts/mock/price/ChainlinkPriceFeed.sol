// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../interfaces/IChainlinkPriceFeed.sol";

/**
* @title BiFi-Bifrost-Extension ChainlinkPriceFeed Contract
* @notice Contract for chainlink price feed mockup, return BTC/ETH(18) price
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

// Ethereum mainnet, Chainlink btc/eth price feed: 0xdeb288F737066589598e9214E782fa5A8eD689e8
contract ChainlinkPriceFeed is IChainlinkPriceFeed {
    function latestAnswer() override external view returns (int256) {
        return 17075389233083143000;
    }
}