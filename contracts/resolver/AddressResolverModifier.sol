// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./state/AddressResolverStorage.sol";
/**
* @title BiFi-Bifrost-Extension AddressResolverModifier Contract
* @notice Contract for Address Resolver entry functions
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract AddressResolverModifier is AddressResolverStorage {
    function setBifrostAddr(address _bifrostAddr, uint256 _stake) onlyAdmin external {
        bifrosts[_bifrostAddr] = _stake;
    }

    function registerBifrost(address _bifrostAddr) onlyAdmin external {
        require(bifrosts[_bifrostAddr] == 0, "already registered");

        uint256 _amount = bifrostStake;
        BFC.transferFrom(_bifrostAddr, address(this), _amount);
        bifrosts[_bifrostAddr] = _amount;
    }

    function releaseBifrost() external {
        address sender = msg.sender;
        uint256 _amount = bifrosts[sender];
        require(_amount != 0 && penaltyAmount==0, "not registered");

        delete bifrosts[sender];
        BFC.transfer(sender, _amount);
    }

    function penaltyResolve(uint256 _amount) external {
        uint256 _penaltyAmount = penaltyAmount;
        if(_penaltyAmount < _amount) _amount = _penaltyAmount;

        penaltyAmount -= _amount;
        BFC.transferFrom(msg.sender, address(this), _amount);
    }
}