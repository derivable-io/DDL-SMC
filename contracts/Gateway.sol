// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/ICollateralPool.sol";

contract Gateway {
    using Address for address;

    address private immutable POOL_FACTORY;

    constructor(address _pFactory) {
        POOL_FACTORY = _pFactory;
    }

    mapping(address => mapping(address => address)) private _extLogics;

    function getMarketPrice(address _dToken) external view returns (uint256) {
        //  Call logic implementation and get P_ViC
        // logics[msg.sender][_dToken].fetch(_dToken);
    }

    function setExtLogic(address _token, address _extLogic) external {
        address _pool = msg.sender;
        require(
            IPoolFactory(pFactory()).isExisted(_pool), "Pool not recorded"
        );
        require(_extLogic.isContract(), "Must be a contract");

        _extLogics[_pool][_token] = _extLogic;
    }

    function pFactory() public view returns (address) {
        return POOL_FACTORY;
    }

    function extLogic(address _pool, address _token) public view returns (address) {
        return _extLogics[_pool][_token];
    }

    function _getTotal() private view returns (uint256 _totalC, uint256 _totalCP) {
        (_totalC, _totalCP) = ICollateralPool(msg.sender).total();
    }
}

