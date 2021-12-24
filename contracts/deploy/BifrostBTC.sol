// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../libs/proxy/ProxyStorage.sol";
import "../libs/ERC20Burnable.sol";

/**
* @title BiFi-Bifrost-Extension BifrostBTC Contract
* @notice Contract for BifrostBTC deployment
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

contract BifrostBTC is ERC20Burnable {
    constructor() {
        owner = payable(msg.sender);
        _init('BifrostBTC', 'BiBTC', 8);
    }
}