// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/ICPTokenFactory.sol";
import "./interfaces/IDTokenFactory.sol";
import "./CollateralPool.sol";

contract PoolFactory {
    using SafeERC20 for IERC20;

    bytes32 private constant VERSION = keccak256("PoolFactory_v1");

    IDTokenFactory private _dFactory;
    ICPTokenFactory private _cFactory;

    mapping(address => bool) private _pMap;
    address[] private _pools;

    event NewPool(address indexed creator, address indexed pool);

    /**
        @notice Create a new Collateral Pool contract
        @param _extCont               External Contracts
            - [0]: PoolOwner - Address that manages Collateral Pool contract
                - Pool Owner (EOA)
                - Management contract
                - DAO
            - [1]: BaseToken - Address of Liquidity Token (Native Coin = 0x00)
            - [2]: Gateway - External contract that helps to calculate:
                - Convert `cAmount` (Collateral Amount) -> `cpAmount` (Collateral Pool Amount)
                - Convert  `cpAmount` (Collateral Pool Amount) -> `cAmount` (Collateral Amount)
        @param _poolConfigurations      Immutable settings of the Collateral Pool
            - [0]: Target Collateral Ratio (1 < TCR)
            - [1]: FeeBase
            - [2]: FeeRate
        @param _poolInfo                Pool URL and CPToken information
            - [0]: Pool URL
            - [1]: CPToken Name
            - [2]: CPToken Symbol
            - [3]: CPToken URL
    */
    function createPool(
        uint256 _initAmount,
        address[3] calldata _extCont,
        uint256[3] calldata _poolConfigurations,
        string[4] calldata _poolInfo
    ) external payable {
        address _sender = msg.sender;
        bytes memory _bytecode = abi.encodePacked(
            type(CollateralPool).creationCode,
            abi.encode(
                _dFactory,
                _extCont,
                _poolConfigurations,
                bytes(_poolInfo[0])
            )
        );
        bytes32 _salt = keccak256(
            abi.encodePacked(_sender, _extCont[0], _extCont[1], _extCont[2], bytes(_poolInfo[0]))
        );

        address _pool = Create2.deploy(0, _salt, _bytecode);
        address _cpToken = _cFactory.newCPToken(_pool, _poolInfo[1], _poolInfo[2], _poolInfo[3]);
        
        if (_extCont[1] == address(0)) 
            require(msg.value == _initAmount, "Invalid init collateral");
        else {
            require(msg.value == 0, "Invalid init collateral");
            IERC20(_extCont[1]).safeTransferFrom(_sender, _pool, _initAmount);
        }
        CollateralPool(_pool).initialize{value: msg.value}(_cpToken, _sender, _initAmount);

        _pools.push(_pool);
        _pMap[_pool] = true;
    }

    function isExisted(address _pool) external view returns (bool) {
        return _pMap[_pool];
    }

    function numOfPools() external view returns (uint256) {
        return _pools.length;
    } 

    function getPool(uint256 _index) public view returns (address) {
        return _pools[_index];
    }

    function cTokenFactory() external view returns (address) {
        return address(_cFactory);
    }

    function dTokenFactory() external view returns (address) {
        return address(_dFactory);
    }
}

