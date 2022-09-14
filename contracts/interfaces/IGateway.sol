// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGateway {

    function getMarketPrice() external view returns (uint256);
    function addCollateral(uint256 _cAmount) external view returns (uint256 _cpAmount);
    function removeCollateral(uint256 _cpAmount) external view returns (uint256 _cAmount);    
}

