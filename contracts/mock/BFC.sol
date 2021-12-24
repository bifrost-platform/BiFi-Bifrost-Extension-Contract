// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../libs/ERC20Burnable.sol";

/**
* @title BiFi-Bifrost-Extension BFC Contract
* @notice Contract for BFC mock up
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

contract BFC is ERC20Burnable {
    constructor() {
        owner = payable(msg.sender);
        _init('Bifrost', 'BFC', 18);
        _mint(msg.sender, 40*10**9*10**18);
    }
}