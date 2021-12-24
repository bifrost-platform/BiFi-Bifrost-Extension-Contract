// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../interfaces/IProxyEntry.sol";
import "./ProxyStorage.sol";

/**
* @title BiFi-Bifrost-Extension ProxyEntry Contract
* @notice Contract for upgradable proxy pattern with access control
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

contract ProxyEntry is ProxyStorage, IProxyEntry {
    constructor (address logicAddr) {
        _setProxyLogic(logicAddr);
    }

    function setProxyLogic(address logicAddr) onlyOwner override external returns(bool) {
        _setProxyLogic(logicAddr);
    }
    function _setProxyLogic(address logicAddr) internal {
        _implement = logicAddr;
    }

    fallback() override external payable {
        address addr = _implement;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() override external payable {}
}