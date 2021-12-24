// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../Owner.sol";

/**
* @title BiFi-Bifrost-Extension ProxyStorage Contract
* @notice Contract for proxy storage layout sharing
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

abstract contract ProxyStorage is Owner {
    address public _implement;
}