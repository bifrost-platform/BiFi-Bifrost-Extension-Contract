// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IOwner Interface
* @notice Interface for Owner Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IOwner {
    function transferOwnership(address _owner) external;
    function acceptOwnership() external;
    function setOwner(address _owner) external;
    function setAdmin(address _admin, uint256 auth) external;
}