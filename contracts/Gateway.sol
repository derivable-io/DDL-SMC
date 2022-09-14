// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/ICollateralPool.sol";

contract Gateway {

    address private immutable POOL_FACTORY;

    constructor(address _pFactory) {
        POOL_FACTORY = _pFactory;
    }

    mapping(address => mapping(address => address)) private _logics;

    function getMarketPrice(address _dToken) external view returns (uint256) {
        //  Call logic implementation and get P_ViC
        // logics[msg.sender][_dToken].fetch(_dToken);
    }

    function setLogic(address _dToken, address _logic) external {
        address _pool = msg.sender;
        require(
            IPoolFactory(pFactory()).isExisted(_pool), "Pool not recorded"
        );

        //  Allow Pool Owner changes logic implementation to fetch P_ViC ????
        _logics[_pool][_dToken] = _logic;
    }

    //  This can be moved to Logic
    function addCollateral(uint256 _cAmount) external view returns (uint256 _cpAmount) {
        (uint256 _totalC, uint256 _totalCP) = _getTotal();
        _cpAmount = _totalCP * _cAmount / _totalC;
    }

    //  This can be moved to Logic
    function removeCollateral(uint256 _cpAmount) external view returns (uint256 _cAmount) {
        (uint256 _totalC, uint256 _totalCP) = _getTotal();
        _cAmount = _totalC * _cpAmount / _totalCP;
    }

    function _getTotal() private view returns (uint256 _totalC, uint256 _totalCP) {
        (_totalC, _totalCP) = ICollateralPool(msg.sender).total();
    }

    function pFactory() public view returns (address) {
        return POOL_FACTORY;
    }
}

