// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ICollateralPool {
    function poolLocked() external view returns (bool);
    function total() external view returns (uint256 _totalC, uint256 _totalCP);
}
