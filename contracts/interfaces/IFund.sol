// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IFund Interface
* @notice Interface for Fund Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IFund {
    function calcInflowFee(uint256 requestedAmount) external view returns (uint64 amount, uint64 btcFee);
    function calcOutflowFee(uint256 requestedAmount) external view returns (uint64 amount, uint256 bfcFee);
    function BTCtoBFC(uint256 requestedAmount) external view returns (uint256 bfc);

    function setRelayer(address _relayer, uint256 amount) external;

    function add_pendingBFCFee(uint256 amount) external returns (bool);
    function sub_pendingBFCFee(uint256 amount) external returns (bool);
    function add_pendingBTCFee(uint256 amount) external returns (bool);
    function sub_pendingBTCFee(uint256 amount) external returns (bool);
}