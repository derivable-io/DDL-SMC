// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IPriceOracle {

    function fetch(address _dToken) external returns (uint256 _num, uint256 _denom);
    function fetch(address _token, address _pool, uint256 _baseAmount) external returns (uint256 _quoteAmount);
}