// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IBitcoin Interface
* @notice Interface for Bitcoin Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IBitcoin {
    function executeOutflow(address _userAddr, uint256 _btcAmount, uint256 actionType) external returns (bool);
}