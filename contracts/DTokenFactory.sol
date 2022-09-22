// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IPoolFactory.sol";
import "./DToken.sol";

contract DTokenFactory {

    bytes32 private constant VERSION = keccak256("DTokenFactory_v1");

    address private immutable POOL_FACTORY;
    //  Collateral Pool -> Derivative Hash -> Derivative Token
    mapping(address => mapping(bytes32 => address)) private _dTokens;

    event NewDToken(address indexed pool, bytes32 indexed deriHash, address indexed dToken);

    constructor(address _pFactory) {
        POOL_FACTORY = _pFactory;
    }

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
    ) external returns (address _dToken) {
        require(
            IPoolFactory(getPoolManagement()).isExisted(_pool), "Pool not recorded"
        );
        require(
            getDTokenByPool(_pool, _hash) == address(0), "DToken already created"
        );

        bytes memory _bytecode = abi.encodePacked(
            type(DToken).creationCode,
            abi.encode(_pool, _name, _symbol, _url)
        );
        bytes32 _salt = keccak256(
            abi.encodePacked(_name, _symbol, _url)
        );

        _dToken = Create2.deploy(0, _salt, _bytecode);
        _dTokens[_pool][_hash] = _dToken;

        emit NewDToken(_pool, _hash, _dToken);
    }

    function getPoolManagement() public view returns (address) {
        return POOL_FACTORY;
    }

    function getDTokenByPool(address _pool, bytes32 _hash) public view returns (address) {
        return _dTokens[_pool][_hash];
    }
}

