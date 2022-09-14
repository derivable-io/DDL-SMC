// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IDDLManagement contract
   @dev Provide interfaces that allow interaction to DDLManagement contract
*/
interface IDDLManagement {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function halted() external view returns (bool);
}
