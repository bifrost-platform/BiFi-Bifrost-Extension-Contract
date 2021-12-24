// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension BTCEvents Contract
* @notice Event definition collection
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract BTCEvents {
    // the requested "OutFlow" event, this is useful for relayer and Bifrost
    event OutFlow(address recipientAddr, address refundPubkeyHash, uint256 addressFormatType, uint256 actionType, uint256 btcAmount, uint256 timeLimit);
}