// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension AddressResolverStructure Contract
* @notice Contract for user address structure
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract AddressResolverStructure {
    /**
	* @dev address information related to the user
	*/
    struct BTCUserStructure {
        uint32 actionType;      // use only 4 bytes
        // format type 0 for bech32, 1 for base58
        uint32 addrFormatType;  // use only 4 bytes
        address addr;
    }
}