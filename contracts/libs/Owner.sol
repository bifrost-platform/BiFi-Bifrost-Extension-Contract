// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../interfaces/IOwner.sol";

abstract contract Owner is IOwner {
    address payable public owner;
    address payable public pendingOwner;
    mapping(address => uint256) public admins;

    modifier onlyOwner() {
        require(payable( msg.sender ) == owner, "only Owner");
        _;
    }

    modifier onlyAdmin() {
        address payable sender = payable( msg.sender );
        require(sender == owner || admins[sender] != 0, "only Admin");
        _;
    }

    constructor() {
        admins[owner = payable( msg.sender )] = 1;
    }

    function transferOwnership(address _nextOwner) override external onlyOwner {
        pendingOwner = payable( _nextOwner );
    }

    function acceptOwnership() override external {
        address payable sender = payable( msg.sender );
        require(sender == pendingOwner, "pendingOwner");
        owner = sender;
    }

    function setOwner(address _nextOwner) override external onlyOwner {
        owner = payable( _nextOwner );
    }

    function setAdmin(address _admin, uint256 auth) override external onlyOwner {
        admins[_admin] = auth;
    }
}
