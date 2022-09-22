// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

/**
    @title Fetch Price
    @dev This contract supports fetching price of one Token using Uniswap Pool ((UniswapV2Pair))
*/
interface IFetchUniswapV2 {
    
    function fetch(address _token, address _pool, uint256 _amount) external returns (uint256 _quoteAmount);
}
