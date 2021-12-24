// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension FundStructure Contract
* @notice Contract for fund struct
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract FundStructure {
    struct BTCUserStructure {
        // 12 bytes(addrType4, networkType4, btcFormat4) + 20bytes(address)
        uint32 actionType;
        // uint32 networkType;
        uint32 addrFormatType;
        address addr;
    }
}