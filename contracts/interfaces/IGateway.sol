// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IGateway {

    function setExtLogic(address _dToken, address _logic) external;
    function getMarketPrice() external view returns (uint256);  
}

