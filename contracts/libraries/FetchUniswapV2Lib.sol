// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../interfaces/IPriceOracle.sol";

library FetchUniswapV2Lib {

    address private constant UNISWAPV2_FACTORY = 0x31003C2D5685c7D28D7174c3255307Eb9a0f3015;    // replace for yours        
    address private constant PRICE_ORACLE = 0x31003C2D5685c7D28D7174c3255307Eb9a0f3015;     // replace for yours

    function _fetch(address _cToken, address _quoteToken) internal returns (uint256 _quoteAmount) {
        address _pair = IUniswapV2Factory(UNISWAPV2_FACTORY).getPair(_cToken, _quoteToken);

        return IPriceOracle(PRICE_ORACLE).fetch(_cToken, _pair, 10**ERC20(_cToken).decimals());
    }
}
