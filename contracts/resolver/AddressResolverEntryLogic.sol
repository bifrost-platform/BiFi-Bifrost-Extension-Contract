// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../interfaces/IAddressResolver.sol";
import "./AddressResolverModifier.sol";
import "../bitcoin/state/BTCDataStructure.sol";

/**
* @title BiFi-Bifrost-Extension AddressResolverEntryLogic Contract
* @notice Contract for Address Resolver entry functions
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

abstract contract AddressResolverEntryLogic is IAddressResolver, AddressResolverModifier, BTCDataStructure {
    event UserRegistration(
        uint32 refundAddrType,
        address[] pubkeyHashes,
        address ethAddr
    );

    event UserRegistrationSingle(
        uint32 actionType,
        uint32 addrFormatType,
        address btcAddr,
        address ethAddr
    );

    /**
	* @dev register an user by storing dedicated address of the user
	* @param refundAddrType the type of user's refund btc address (0: segwit, 1: legacy, 2: p2sh)
    * @param pubkeyHashes the dedicated pubkey hashes
    *       @notice index 0 for BiFi withdraw and BiFi borrow (outflow)
    *       @notice index 1 for swap across blockchains (inflow)
    *       @notice index 2 for BiFi deposit (inflow)
    *       @notice index 3 for BiFi repay (inflow)
    * @param sig the signature by Bifrost
	* @return true
	*/
    function registerUser(
        uint32 refundAddrType,
        address[] calldata pubkeyHashes,
        bytes32[] calldata sig
    ) override external returns (bool) {
        address signer;
        bytes32 _hash = keccak256( abi.encode(pubkeyHashes[1], pubkeyHashes[2], pubkeyHashes[3], msg.sender) );
        signer = ecrecover(_hash, uint8(uint256(sig[0])), sig[1], sig[2]); // msg hash, v, r, s
        require(bifrosts[signer] != 0, "ecrecover fail");

        for(uint256 i; i<4; i++) {
            _registerAddress(uint32(i+1), i!=0 ? 0 : refundAddrType, pubkeyHashes[i], msg.sender);
        }

        emit UserRegistration(
            refundAddrType,
            pubkeyHashes,
            msg.sender
        );

        return true;
    }

    /**
	* @dev change refund pubkey hash for the existing user
	* @param refundAddrType the type of refund btc address (0: segwit, 1: legacy, 2: p2sh)
    * @param refundPubkeyHash the user's pubkey hash to be used to refunding BTC
	* @return true
	*/
    function registerRefund(
        uint32 refundAddrType,
        address refundPubkeyHash
    ) external returns (bool) {
        address sender = msg.sender;

        require(ethUsers[sender][1] != address(0), "bifrost registration");

        _registerAddress(1, refundAddrType, refundPubkeyHash, sender);
        emit UserRegistrationSingle(1, refundAddrType, refundPubkeyHash, sender);
        return true;
    }

    /**
	* @dev register single pubkey hash of the user
	* @param actionType Identifying performance of the Bitcoin Tx unit
	*       @notice value 1 for BiFi withdraw and BiFi borrow (outflow)
    *       @notice value 2 for swap across blockchains (inflow)
    *       @notice value 3 for BiFi deposit (inflow)
    *       @notice value 4 for BiFi repay (inflow)
	* @param addrFormatType the type of user's refund btc address (0: segwit, 1: legacy, 2: p2sh)
    * @param pubkeyHash the dedicated pubkey hashes corresponding BiFi-action
    * @param ethAddr the user's ether address
	* @return true
	*/
    function _registerAddress(uint32 actionType, uint32 addrFormatType, address pubkeyHash, address ethAddr) internal returns (bool) {
        address zeroAddr;
        require(pubkeyHash != zeroAddr || ethAddr != zeroAddr, "zero address");

        BTCUserStructure memory tmp = btcUsers[pubkeyHash];
        // pubkey hash not used or
        // users pubkey hash change
        require(
            tmp.addr == zeroAddr ||
            (tmp.actionType == 1 && actionType == 1 && tmp.addr == ethAddr),
            "err: BTC addr collision"
        );
        if(actionType == 1) _checkUserOutflow(ethAddr);

        tmp.actionType     = actionType;
        tmp.addrFormatType = addrFormatType;
        tmp.addr           = ethAddr;

        btcUsers[pubkeyHash] = tmp;
        ethUsers[ethAddr][actionType] = pubkeyHash;
        return true;
    }

    /**
	* @dev check whether there is an outflow process in progress
	* @param userAddr the address of the user
	*/
    function _checkUserOutflow(address userAddr) internal {
        S_Outflow memory memOutflow = db.get_outflowInfo(userAddr);
        require(!memOutflow.requested, "cannot update refund address in outflow");
    }

    /**
	* @dev pay compensation to the user for late refund BTC by the Bifrost
	* @param _userAddr the address of the user
    * @param _btcAmount the refund amount requested by the user
	*/
    function penaltyTransfer(address _userAddr, uint256 _btcAmount) onlyAdmin override external {
        uint256 _bfcAmount = unifiedMul(fund.BTCtoBFC(_btcAmount), penaltyRatio);
        penaltyAmount += _bfcAmount;
        BFC.transfer(_userAddr, _bfcAmount);
    }

    function getCustomerETHAddr(address pubkeyHash) override external view returns (address, uint32) {
        BTCUserStructure memory tmpCustomer = btcUsers[ pubkeyHash ];
        return (tmpCustomer.addr, tmpCustomer.actionType);
    }

    function getBTCUserInfo(address pubkeyHash) external view returns (BTCUserStructure memory tmpCustomer) {
        tmpCustomer = btcUsers[ pubkeyHash ];
    }

    function getRefundAddr(address ethAddr) override external view returns (address btcPubkeyHash, uint32 addrFormatType) {
        btcPubkeyHash = ethUsers[ethAddr][1];
        addrFormatType = btcUsers[btcPubkeyHash].addrFormatType;
    }

    function getETHUserInfo(address etherAddr) external view returns (address[] memory pubkeyHashes) {
        pubkeyHashes = new address[](4);

        for(uint256 i=0; i<4; i++) pubkeyHashes[i] = ethUsers[etherAddr][i+1];
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a*b/10**18;
    }
}