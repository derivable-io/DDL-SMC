// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IDTokenFactory {

    /**
        @notice Create DToken contract for one derivative of the Collateral Pool
        @param _pool              Address of the Collateral Pool contract
        @param _hash              Hash of a derivative type (i.e. ETH^2)
        @param _name              Name of the Counter Collateral Token
        @param _symbol            Symbol of the Counter Collateral Token
        @param _url               External URL to retrieve more information of this token
    */
    function newDToken(
        address _pool,
        bytes32 _hash,
        string calldata _name,
        string calldata _symbol,
        string calldata _url
    ) external returns (address _dToken);
}

