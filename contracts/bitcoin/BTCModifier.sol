// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./state/BTCState.sol";

/**
* @title BiFi-Bifrost-Extension BTCModifier Contract
* @notice Contract for access control of Bitcoin contract, and BFC token control
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract BTCModifier is BTCState {
    /**
	* @dev wrapper function of erc20 token contract's "transferFrom"
    * @param _bfc the interface of BFC token contract
    * @param _from the address of sender
    * @param _to the address of recipient
    * @param _amount the amount to be sent
	*/
    function _BFC_transferFrom(IERC20 _bfc, address _from, address _to, uint256 _amount) internal {
        _bfc.transferFrom(_from, _to, _amount);
    }

    /**
	* @dev ensure that a contract is not in the challenge phase
    * @return flag false if Bitcoin contract is not in challenge phase (or revert)
	*/
    function _notChallenged() internal view returns (bool flag) {
        flag = challengeCTX.challenged;
        require(!flag, "challenged");
    }

    /**
	* @dev ensure that a contract is in the challenge phase
    * @return flag if Bitcoin contract is in challenge phase (or revert)
	*/
    function _challenged() internal view returns (bool flag) {
        flag = challengeCTX.challenged;
        require(flag, "not challenged");
    }

    /**
	* @dev register a Relayer by staking BFC
    * @notice the received BFC will be sent to the "Fund" contract
	*/
    function participationRelayer() external {
        address sender = msg.sender;
        uint256 _stake = relayerStake;
        require(roles[sender] != 1, "participationRelayer");
        _setRole(sender, 1);
        _BFC_transferFrom(BFC, sender, address(fund), _stake);
        _fund_set_relayer(sender, _stake);
    }

    /**
	* @dev remove "Relayer" by releasing the relayer's stake (in BFC)
	*/
    function leaveRelayer(address _relayer) onlyAdmin external {
        _setRole(_relayer, 0);
        _fund_set_relayer(_relayer, 0);
    }

    /**
	* @dev set a Relayer by force
    * @param _relayer the address of the "Relayer"
    * @param _amount the amount of the "Relayer"'s stake (in BFC)
	*/
    function _fund_set_relayer(address _relayer, uint256 _amount) internal {
        fund.setRelayer(_relayer, _amount);
    }


    function authRelayer(address _addr, uint256 _role) onlyAdmin external {
        // _role value 0 for delete
        _setRole(_addr, _role);
    }

    /**
	* @dev update the entity's role
    * @param _addr the address of target entity
    * @param _role the authority level (if zero, no authority)
	*/
    function setRole(address _addr, uint256 _role) onlyAdmin external {
        _setRole(_addr, _role);
    }

    /**
	* @dev update the entity's rol (internal)
    * @param _addr the address of target entity
    * @param _role the authority level (if zero, no authority)
	*/
    function _setRole(address _addr, uint256 _role) internal {
        roles[_addr] = _role;
    }

    /**
	* @dev modifier for relayer only functions
	*/
    function _onlyRelayers() internal view {
        address sender = msg.sender;
        require(sender == owner || roles[sender] == 1, "only Relayer");
    }

    /**
	* @dev modifier for "BiFi Handler" only functions
	*/
    function _onlyContract() internal view {
        address sender = msg.sender;
        require(sender == owner || admins[sender] != 0 || roles[sender] == 4, "only Contract");
    }
}