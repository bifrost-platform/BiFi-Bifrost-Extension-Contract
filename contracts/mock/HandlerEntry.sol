// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./HandlerInternal.sol";

import "../libs/SafeERC20.sol";

/**
* @title BiFi-Bifrost-Extension HandlerEntry Contract
* @notice Contract for BiFi mockup handler entry functions
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

abstract contract HandlerEntry is HandlerInternal {
    using SafeERC20 for IERC20;

    function setBitcoinAddr(address btcAddr) external returns (bool) {
        bitcoin = IBitcoin(btcAddr);
        return true;
    }

    function setBiBTC(address _BiBTC) external returns (bool) {
        BiBTC = IERC20(_BiBTC);
        return true;
    }

    function reqExternalWithdraw(uint256 btcAmount, bool flag) override external returns (bool) {
        address userAddr = msg.sender;

        uint256 userDeposit = depositAmount[userAddr];
        require(userDeposit >= btcAmount, "err: not enough Deposit");
        require( (userDeposit-btcAmount) * borrowLimit >= borrowAmount[userAddr], "err: not enough Withdraw Credit");
        depositAmount[userAddr] = userDeposit - btcAmount;
        totalDepositAmount -= btcAmount;

        BiBTC.safeTransfer(address(bitcoin), btcAmount);

        require(
            bitcoin.executeOutflow(userAddr, btcAmount, 2),
            "err: request fail"
        );

        return true;
    }

    function reqExternalBorrow(uint256 btcAmount, bool flag) override external returns (bool) {
        address userAddr = msg.sender;

        uint256 userBorrow = borrowAmount[userAddr];
        require( (depositAmount[userAddr] * borrowLimit >= userBorrow + btcAmount), "err: not enough Borrow Credit");
        borrowAmount[userAddr] = userBorrow - btcAmount;
        totalBorrowAmount -= btcAmount;

        BiBTC.safeTransfer(address(bitcoin), btcAmount);

        require(
            bitcoin.executeOutflow(userAddr, btcAmount, 3),
            "err: request fail"
        );

        return true;
    }

    function deposit(uint256 amount, bool flag) override external returns (bool) {
        _deposit(msg.sender, amount);
        BiBTC.safeTransferFrom(msg.sender, address(this), _UnifiedToUnderlying(amount));
        return true;
    }

    function withdraw(uint256 amount, bool flag) override external returns (bool) {
        depositAmount[msg.sender] -= amount;
        totalDepositAmount -= amount;
        BiBTC.safeTransfer(msg.sender, _UnifiedToUnderlying(amount));
        return true;
    }

    function repay(uint256 amount, bool flag) override external returns (bool) {
        uint256 userBorrowAmount = borrowAmount[msg.sender];

        if(userBorrowAmount < amount) {
            borrowAmount[msg.sender] = 0;
            totalBorrowAmount -= userBorrowAmount;

            _deposit(msg.sender, userBorrowAmount-amount);
        } else {
            borrowAmount[msg.sender] -= amount;
            totalBorrowAmount -= amount;
        }

        BiBTC.safeTransferFrom(msg.sender, address(this), _UnifiedToUnderlying(amount));

        return true;
    }

    function borrow(uint256 amount, bool flag) override external returns (bool) {
        borrowAmount[msg.sender] += amount;
        totalBorrowAmount += amount;
        BiBTC.safeTransfer(msg.sender, _UnifiedToUnderlying(amount));
        return true;
    }

    function depositTo(address userAddr, uint256 amount, bool flag) override public returns (bool) {
        depositAmount[userAddr] += amount;
        totalDepositAmount += amount;
        BiBTC.safeTransferFrom(msg.sender, address(this), _UnifiedToUnderlying(amount));
        return true;
    }

    function repayTo(address userAddr, uint256 amount, bool flag) override public returns (bool) {
        uint256 userBorrowAmount = borrowAmount[userAddr];

        if(userBorrowAmount < amount) {
            borrowAmount[userAddr] = 0;
            totalBorrowAmount -= userBorrowAmount;

            _deposit(userAddr, userBorrowAmount-amount);
        } else {
            borrowAmount[userAddr] -= amount;
            totalBorrowAmount -= amount;
        }

        BiBTC.safeTransferFrom(msg.sender, address(this), _UnifiedToUnderlying(amount));
        return true;
    }

    function getUserDepositAmount(address userAddr) external view returns (uint256) {
        return depositAmount[userAddr];
    }
    function getUserBorrowAmount(address userAddr) external view returns (uint256) {
        return borrowAmount[userAddr];
    }

    function handlerViewProxy(bytes calldata rawCallData) override external returns (bool result, bytes memory returnData) {
        (result, returnData) = address(this).delegatecall(rawCallData);
        require(result, string(returnData) );
    }

    function getERC20Addr() override external view returns (address) {

    }
    function getOwner() override external view returns (address) {

    }
    function handler() override external view returns (address) {

    }
    function handlerProxy(bytes memory data) override external returns (bool, bytes memory) {

    }
    function setErc20(address ercAddr, string memory name) override external returns (bool) {

    }
    function siProxy(bytes memory data) override external returns (bool, bytes memory) {

    }
    function siViewProxy(bytes memory data) override external returns (bool, bytes memory) {

    }
}

