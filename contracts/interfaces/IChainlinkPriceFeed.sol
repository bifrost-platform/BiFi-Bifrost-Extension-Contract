// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../bitcoin/state/BTCDataStructure.sol";

/**
* @title BiFi-Bifrost-Extension IChainlinkPriceFeed Interface
* @notice Interface for the Chainlink price feed mockup Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IChainlinkPriceFeed {
    function latestAnswer() external view returns (int256);
}