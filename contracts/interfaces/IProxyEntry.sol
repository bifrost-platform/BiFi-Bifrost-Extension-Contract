// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./IOwner.sol";

/**
* @title BiFi-Bifrost-Extension IProxyEntry Interface
* @notice Interface for Proxy Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IProxyEntry is IOwner {
    function setProxyLogic(address logicAddr) external returns(bool);
    fallback() external payable;
    receive() external payable;
}