// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../bitcoin/BTCEntryLogicExternal.sol";

/**
* @title BiFi-Bifrost-Extension Bitcoin Contract
* @notice Contract for Bitcoin deployment
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

contract Bitcoin is BTCEntryLogicExternal {
    constructor() {
        owner = payable(msg.sender);
    }
}