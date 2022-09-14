// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
    @title IDDLToken contract
    @dev This contract defines an interface of ICPToken and IDToken that others can interact
*/

interface IDDLToken {

    function mint(address _to, uint256 _amount) external;
	function burn(address _from, uint256 _amount) external;
}
