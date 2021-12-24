// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IAddressResolver Interface
* @notice Interface for AddressResolver Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IAddressResolver {
    function registerUser(
        uint32 refundAddrType,
        address[] calldata pubkeyHashes,
        bytes32[] calldata sig
    ) external returns (bool);

    function getCustomerETHAddr(address pubkeyHash) external view returns (address, uint32);
    function getRefundAddr(address ethAddr) external view returns (address btcPubkeyHash, uint32 addrFormatType);

    function penaltyTransfer(address userAddr, uint256 _btcAmount) external;
}