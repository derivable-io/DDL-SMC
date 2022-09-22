// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./CPToken.sol";

contract CPTokenFactory {

    bytes32 private constant VERSION = keccak256("CPTokenFactory_v1");

    address private immutable POOL_FACTORY;
    mapping(address => address) private _cpTokens;

    event NewCToken(address indexed pool, address indexed cpToken);

    constructor(address _pFactory) {
        POOL_FACTORY = _pFactory;
    }

    modifier onlyPoolFactory() {
        require(msg.sender == getPoolManagement(), "Only Pool Management");
        _;
    }

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
    ) external onlyPoolFactory returns (address _cpToken) {
        require(
            getCPTokenByPool(_pool) == address(0), "CToken has been created"
        );

        bytes memory _bytecode = abi.encodePacked(
            type(CPToken).creationCode,
            abi.encode(_pool, _name, _symbol, _url)
        );
        bytes32 _salt = keccak256(
            abi.encodePacked(_name, _symbol, _url)
        );

        _cpToken = Create2.deploy(0, _salt, _bytecode);
        _cpTokens[_pool] = _cpToken;

        emit NewCToken(_pool, _cpToken);
    }

    function getPoolManagement() public view returns (address) {
        return POOL_FACTORY;
    }

    function getCPTokenByPool(address _pool) public view returns (address) {
        return _cpTokens[_pool];
    }
}

