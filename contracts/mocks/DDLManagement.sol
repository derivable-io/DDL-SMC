// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
    @title DDLManagement contract
    @dev This contract is being used as Governance of DDL Protocol
       + Register address (Treasury) to receive fee
       + Set up additional special roles - DEFAULT_ADMIN_ROLE, MANAGER_ROLE
*/
contract DDLManagement is AccessControlEnumerable {
    address public treasury;

    bool public halted;

    //  Declare Roles - MANAGER_ROLE
    //  There are three roles:
    //     - Top Gun = DEFAULT_ADMIN_ROLE:
    //         + Manages governance settings
    //         + Has an authority to grant/revoke other roles
    //         + Has an authority to set him/herself other roles
    //     - MANAGER_ROLE
    //         + Has an authority to do special tasks, i.e. settings
    //         + NFT Holder when Heroes/item are minted
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _treasury) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        treasury = _treasury;
    }

    /**
       @notice Set `halted = true`
       @dev  Caller must have MANAGER_ROLE
    */
    function halt() external onlyRole(MANAGER_ROLE) {
        halted = true;
    }

    /**
       @notice Set `halted = false`
       @dev  Caller must have MANAGER_ROLE
    */
    function unhalt() external onlyRole(MANAGER_ROLE) {
        halted = false;
    }

    /**
       @notice Change new address of Treasury
       @dev  Caller must have DEFAULT_ADMIN_ROLE
       @param _newTreasury    Address of new Treasury
    */
    function updateTreasury(address _newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTreasury != address(0), "Set zero address");

        treasury = _newTreasury;
    }
}
