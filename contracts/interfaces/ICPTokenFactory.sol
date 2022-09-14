// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICPTokenFactory {

    /**
        @notice Create CPToken contract of one Collateral Pool contract
        @param _pool              Address of the Collateral Pool contract
        @param _name              Name of the CP Token
        @param _symbol            Symbol of the CP Token
        @param _url               External URL to retrieve more information of this token
    */
    function newCPToken(
        address _pool,
        string calldata _name,
        string calldata _symbol,
        string calldata _url
    ) external returns (address _cpToken);
}

