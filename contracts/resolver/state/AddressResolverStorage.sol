// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../libs/proxy/ProxyStorage.sol";
import "./AddressResolverStructure.sol";

import "../../interfaces/IBTC_DB.sol";
import "../../interfaces/IFund.sol";
import "../../interfaces/IERC20.sol";

/**
* @title BiFi-Bifrost-Extension AddressResolverStorage Contract
* @notice Storage Contract of Address Resolver
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract AddressResolverStorage is ProxyStorage, AddressResolverStructure {
    IBTC_DB public db;
    mapping(address => uint256) public bifrosts;
    IERC20 public BFC;
    uint256 public bifrostStake;

    IFund public fund;
    uint256 public penaltyRatio;
    uint256 public penaltyAmount;

    mapping(address => BTCUserStructure) btcUsers;
    mapping(address => mapping(uint256 => address)) ethUsers;

    function setDB(IBTC_DB _db) onlyAdmin external {
        db = _db;
    }
    function setBFC(IERC20 _bfc) onlyAdmin external {
        BFC = _bfc;
    }

    function setStake(uint256 amount) onlyAdmin external {
        bifrostStake = amount;
    }

    function setFund(IFund _fund) onlyAdmin external {
        fund = _fund;
    }

    function setPenaltyRatio(uint256 _ratio) onlyAdmin external {
        penaltyRatio = _ratio;
    }
    function setPenaltyAmount(uint256 _penaltyAmount) external onlyAdmin {
        penaltyAmount = _penaltyAmount;
    }

    function withdrawFund() onlyAdmin external {
        IERC20 _erc20 = BFC;
        _erc20.transfer(msg.sender, _erc20.balanceOf(address(this)));
    }

    function setETHUser(address ethUserAddr, uint256 _actionType, address _pubkeyHash) onlyAdmin external {
        address zeroAddr;
        require( 0 < _actionType && _actionType <= 4, "invalid action type");

        ethUsers[ ethUserAddr ][ _actionType ] = _pubkeyHash;
    }

    function setBTCuser(address pubkeyHash, uint32 _actionType, uint32 _addrFormatType, address _ethUserAddr) onlyAdmin external {
        address zeroAddr;
        require( 0 < _actionType && _actionType <= 4, "invalid action type");

        BTCUserStructure memory tmp;
        tmp.actionType = _actionType;
        tmp.addrFormatType = _addrFormatType;
        tmp.addr = _ethUserAddr;
        btcUsers[pubkeyHash] = tmp;
    }
}