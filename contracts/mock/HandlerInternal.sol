// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../libs/Owner.sol";
import "../interfaces/IBIFIHandlerProxy.sol";
import "../interfaces/IBitcoin.sol";
import "../interfaces/IERC20.sol";

import "../interfaces/IBIFIHandlerProxy.sol";

import "../libs/SafeERC20.sol";

/**
* @title BiFi-Bifrost-Extension HandlerInternal Contract
* @notice Contract for BiFi mockup handler logics
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

abstract contract HandlerInternal is IBIFIHandlerProxy, Owner {
    using SafeERC20 for IERC20;

    IBitcoin bitcoin;
    IERC20 BiBTC;

    uint256 public totalDepositAmount;
    uint256 public totalBorrowAmount;

    mapping(address => uint256) depositAmount;
    mapping(address => uint256) borrowAmount;

    uint256 constant borrowLimit  = 8 * 10 ** 17;
    uint256 constant unifiedPoint = 10 ** 18;

    function _deposit(address userAddr, uint256 amount) internal returns (bool) {
        depositAmount[userAddr] += amount;
        totalDepositAmount += amount;
    }

    function _UnifiedToUnderlying(uint256 amount) internal pure returns (uint256) {
        return amount*10**8/10**18;
    }
}
