// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./FundInternal.sol";

/**
* @title BiFi-Bifrost-Extension FundExternal Contract
* @notice Contract for Fund entry functions
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/
contract FundExternal is FundInternal {
    /**
	* @dev calc inflow fee and deducted amount
    * @param _requestedBTCAmount the requested amount
    * @return executeAmount the finalized amount to execute BiFi-action
    * @return btcFee the fee amount (in Satoshi)
	*/
    function calcInflowFee(uint256 _requestedBTCAmount) external view returns (uint64 executeAmount, uint64 btcFee) {
        btcFee = uint64( unifiedMul(_requestedBTCAmount, inflowFeeRate) );
        executeAmount = uint64(_requestedBTCAmount - btcFee);
    }

    /**
	* @dev calc outflow fee and deducted amount
    * @param _requestedBTCAmount the requested amount
    * @return executeAmount the finalized amount to execute BiFi-action
    * @return bfcFee the fee amount (in BFC)
	*/
    function calcOutflowFee(uint256 _requestedBTCAmount) external view returns (uint64 executeAmount, uint256 bfcFee) {
        bfcFee = uint64( _max(unifiedMul(_requestedBTCAmount, outflowFeeRate), outflowMinFee) );

        executeAmount = uint64(_requestedBTCAmount);

        // bfcFee = bfcFee*_getPrice_btc_bfc18() / 10**8;
        bfcFee = bfcFee*_getPrice_btc_bfc18() / 0x5f5e100;
    }

    function setRelayer(address _relayer, uint256 amount) onlyAdmin external {
        if(amount != 0) _pushRelayer(_relayer, amount);
        else _popRelayer(_relayer);

    }
    function _pushRelayer(address _relayer, uint256 _amount) internal {
        bool contain;
        address[] memory _relayers = relayers;

        for(uint256 i; i<_relayers.length; i++) {
            if(_relayers[i] == _relayer) {
                contain = true;
                break;
            }
        }
        if(contain == false) relayers.push(_relayer);
        relayerStakes[_relayer] += _amount;
    }
    function _popRelayer(address _relayer) internal {
        uint256 _amount;
        bool contain;

        for(uint256 i; i<relayers.length; i++) {
            if(relayers[i] == _relayer) {
                (relayers[i], relayers[relayers.length-1]) = (relayers[relayers.length-1], relayers[i]);
                _amount = relayerStakes[_relayer];
                delete relayerStakes[_relayer];
                contain = true;
                break;
            }
        }
        require(contain, "not relayer");
        BFC.transfer(_relayer, _amount);
    }

    function BTCtoBFC(uint256 _requestedBTCAmount) external view returns (uint256) {
        return _requestedBTCAmount * _getPrice_btc_bfc18() / 0x5f5e100;
    }

    function del_pendingBTCFee() onlyAdmin external returns (uint256) {
        uint256 returnData = pendingBTCFeeSum;
        delete pendingBTCFeeSum;
        return returnData;
    }

    function del_pendingBFCFee() onlyAdmin external returns (uint256) {
        uint256 returnData = pendingBFCFeeSum;
        delete pendingBFCFeeSum;
        return returnData;
    }

    function add_pendingBFCFee(uint256 executeAmount) onlyAdmin external returns (bool) {
        pendingBFCFeeSum += executeAmount;
        return true;
    }

    function sub_pendingBFCFee(uint256 executeAmount) onlyAdmin external returns (bool) {
        pendingBFCFeeSum -= executeAmount;
        return true;
    }

    function add_pendingBTCFee(uint256 executeAmount) onlyAdmin external returns (bool) {
        pendingBTCFeeSum += executeAmount;
        return true;
    }

    function sub_pendingBTCFee(uint256 executeAmount) onlyAdmin external returns (bool) {
        pendingBTCFeeSum -= executeAmount;
        return true;
    }

    function getInflowFeeParams() external view returns (uint256 _inflowFeeRate) {
        _inflowFeeRate = inflowFeeRate;
    }

    function getOutflowFeeParams() external view returns (uint256 _outflowFeeRate, uint256 _outflowMinFee) {
        _outflowFeeRate = outflowFeeRate;
        _outflowMinFee = outflowMinFee;
    }
}