// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IPriceOracle.sol";
import "../uniswap/Math.sol";

library FetchPairUniswapV2Lib {

    uint256 private constant Q112 = 2**112;
    address private constant UNISWAPV2_FACTORY = 0x31003C2D5685c7D28D7174c3255307Eb9a0f3015;    // replace for yours

    function _fetch(
        address _fetchPx,
        address _cToken,
        address _quoteToken,
        address _lpToken
    ) internal returns (uint256 _lpPx, uint256 _cPx) {
        address _token0 = IUniswapV2Pair(_lpToken).token0();
        address _token1 = IUniswapV2Pair(_lpToken).token1();
        uint256 _totalSupply = IUniswapV2Pair(_lpToken).totalSupply();
        (uint256 _r0, uint256 _r1, ) = IUniswapV2Pair(_lpToken).getReserves();

        uint256 _sqrtK = Math.sqrt(_r0 * _r1) * Q112 / _totalSupply;
        uint256 _px0 = _getPrice(_fetchPx, _token0, _quoteToken);
        uint256 _px1 = _getPrice(_fetchPx, _token1, _quoteToken);

        if (_cToken == _token0)
            _cPx = _px0;
        else {
            require(_cToken == _token1, "Invalid base token");
            _cPx = _px1;
        }

        _lpPx = 2 * _sqrtK * Math.sqrt(_px0) * Math.sqrt(_px1) / Q112;
    }

    function _getPrice(address _fetchPx, address _token, address _quoteToken) private returns (uint256) {
        uint256 _singleToken = 10**ERC20(_token).decimals();
        if (_token == _quoteToken)
            return _singleToken;

        address _pair = IUniswapV2Factory(UNISWAPV2_FACTORY).getPair(_token, _quoteToken);

        return IPriceOracle(_fetchPx).fetch(_token, _pair, _singleToken);
    }
}
