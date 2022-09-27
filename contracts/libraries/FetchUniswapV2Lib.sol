// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IPriceOracle.sol";
import "../uniswap/Math.sol";

library FetchUniswapV2Lib {

    uint256 private constant Q112 = 2**112;
    address private constant UNISWAPV2_FACTORY = 0x31003C2D5685c7D28D7174c3255307Eb9a0f3015;    // replace for yours

    /**
        @notice Fetch Price of `_bToken` and `_lpToken` with respect to `_qToken`
            `_lpToken`: LP_Token0_Token1

        @param _extOracle         UniswapV2 Oracle contract that returns a single asset's price
        @param _bToken            BaseToken (Token0/Token1)
        @param _qToken            QuoteToken, i.e. USDT, USDC, BUSD, Token1/Token0, etc
        @param _lpToken           UniswapV2 LPToken

        @return _lpPx             Price of LPToken
        @return _bPx              Price of BaseToken
    */
    function _fetchPair(
        address _extOracle,
        address _bToken,
        address _qToken,
        address _lpToken
    ) internal returns (uint256 _lpPx, uint256 _bPx) {
        address _token0 = IUniswapV2Pair(_lpToken).token0();
        address _token1 = IUniswapV2Pair(_lpToken).token1();
        uint256 _totalSupply = IUniswapV2Pair(_lpToken).totalSupply();
        (uint256 _r0, uint256 _r1, ) = IUniswapV2Pair(_lpToken).getReserves();

        uint256 _sqrtK = Math.sqrt(_r0 * _r1) * Q112 / _totalSupply;
        uint256 _px0 = _fetchSingle(_extOracle, _token0, _qToken);
        uint256 _px1 = _fetchSingle(_extOracle, _token1, _qToken);

        if (_bToken == _token0)
            _bPx = _px0;
        else {
            require(_bToken == _token1, "Invalid base token");
            _bPx = _px1;
        }

        _lpPx = 2 * _sqrtK * Math.sqrt(_px0) * Math.sqrt(_px1) / Q112;
    }

    /**
        @notice Fetch Price of `_token` with respect to `_qToken`

        @param _extOracle         UniswapV2 Oracle contract that returns a single asset's price
        @param _token             Token that needs to check price
        @param _qToken            Quote Token, i.e. USDT, USDC, BUSD, etc
    */
    function _fetchSingle(address _extOracle, address _token, address _qToken) private returns (uint256) {
        uint256 _singleToken = 10**ERC20(_token).decimals();
        if (_token == _qToken)
            return _singleToken;

        address _pool = IUniswapV2Factory(UNISWAPV2_FACTORY).getPair(_token, _qToken);

        return IPriceOracle(_extOracle).fetch(_token, _pool, _singleToken);
    }
}
