// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IBIFIHandlerProxy Interface
* @notice Interface for BiFi mockup handler Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IBIFIHandlerProxy {
    function reqExternalWithdraw(uint256 unifiedTokenAmount, bool flag) external returns (bool);
    function reqExternalBorrow(uint256 unifiedTokenAmount, bool flag) external returns (bool);

    function deposit(uint256 amount, bool flag) external returns (bool);
    function withdraw(uint256 amount, bool flag) external returns (bool);
    function repay(uint256 amount, bool flag) external returns (bool);
    function borrow(uint256 amount, bool flag) external returns (bool);

    function depositTo(address userAddr, uint256 amount, bool flag) external returns (bool);
    function repayTo(address userAddr, uint256 amount, bool flag) external returns (bool);

	function handlerProxy(bytes memory data) external returns (bool, bytes memory);
	function handlerViewProxy(bytes memory data) external returns (bool, bytes memory);
	function siProxy(bytes memory data) external returns (bool, bytes memory);
	function siViewProxy(bytes memory data) external returns (bool, bytes memory);

    function setErc20(address ercAddr, string memory name) external returns (bool);

    function handler() external view returns (address);
    function getOwner() external view returns (address);
    function getERC20Addr() external view returns (address);
}