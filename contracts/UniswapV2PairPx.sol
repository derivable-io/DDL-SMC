// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFetchUniswapV2.sol";
import "./uniswap/Math.sol";

contract UniswapV2PairPx is Ownable {

    struct TokenInfo {
        address cToken;
        address quoteToken;
        address lpToken;
        int256 leverage;
    }

    uint256 private constant Q112 = 2**112;

    IFetchUniswapV2 public fetchPx;
    IUniswapV2Factory public immutable UNISWAPV2_FACTORY;

    mapping(address => TokenInfo) private _dTokens;
    mapping(address => uint256) private _basePrices;

    constructor(IFetchUniswapV2 _fetchPx, IUniswapV2Factory _factory) Ownable() {
        fetchPx = _fetchPx;
        UNISWAPV2_FACTORY = _factory;
    }

    function setFetch(address _fetchPx) external virtual onlyOwner {
        require(_fetchPx != address(0), "Set zero address");

        fetchPx = IFetchUniswapV2(_fetchPx);
    }

    function addDToken(
        address _dToken,
        TokenInfo calldata _tokenInfo
    ) external virtual onlyOwner {
        require(
            _dTokens[_dToken].lpToken == address(0), "DToken already recorded"
        );
        require(
            _tokenInfo.cToken != address(0) &&
            _tokenInfo.lpToken != address(0) &&
            _tokenInfo.quoteToken != address(0) &&
            _tokenInfo.leverage != 0,
            "Invalid settings"
        );

        _dTokens[_dToken] = _tokenInfo;
    }

    function fetch(address _dToken) external virtual returns (uint256 _num, uint256 _denom) {
        TokenInfo memory _info = _dTokens[_dToken];
        require(
            _info.lpToken != address(0), "DToken not found"
        );

        (uint256 _lpPx, uint256 _cPx) = _fetch(_info.cToken, _info.quoteToken, _info.lpToken);
        //  if `_basePrices[_dToken] = 0` (first round), then:
        //      - `_basePrice = _cPx`
        //      - update `_basePrice[_dToken] = `_cPx`
        //      - `_basePrice = _cPx` -> (_cPx / _basePrice)^i = 1 regardless of leverage value
        //  thus, return (1, _lpPx) immediately
        uint256 _basePrice = _basePrices[_dToken];
        if (_basePrice == 0) {
            _basePrices[_dToken] = _cPx;
            return (1, _lpPx);
        }
        //  There are two cases: leverage < -2 or leverage > 2
        //  abs(leverage) should be less than or equal 50 due to EVM constraints (gas, execution timeout)
        //  PViC = (cPx / basePrice)^i / lpPx
        //  if i < 0: PViC = (basePrice / cPx)^(abs(i)) / lpPx
        //  if i > 0: PViC = (cPx / basePrice)^(abs(i)) / lpPx
        uint256 _absLeverage = _abs(_info.leverage);
        require(
            _absLeverage >= 2 && _absLeverage <= 50, "Invalid leverage"
        );

        uint256 _k = 1;
        if (_info.leverage < 0) {
            if (_basePrice < _cPx) {
                (_cPx, _k) = _adjust(_cPx);
                _k = _k**_absLeverage;
            }
            return (_nLeverage(_basePrice, _cPx, _absLeverage), _cPx * _k * _lpPx);
        }   
        else {
            if (_cPx < _basePrice) {
                (_basePrice, _k) = _adjust(_basePrice);
                _k = _k**_absLeverage;
            }
            return (_nLeverage(_cPx, _basePrice, _absLeverage), _basePrice * _k * _lpPx);
        }   
    }

    function _adjust(uint256 _num) private pure returns (uint256, uint256) {
        if (_num % 5 == 0)
            return (_num / 5, 5);
        else if (_num % 3 == 0)
            return (_num / 3, 3);
        return (_num / 2, 2);
    }

    function _abs(int256 _num) private pure returns (uint256) {
        if (_num < 0)
            return uint256(_num * -1);
        return uint256(_num);
    }

    //  d = denominator and n = numerator
    //  (a / b)^1 = a / b = n1 / d
    //      n1 = a
    //      d = b
    //  (a / b)^2 = (a * a / b) / b = n2 / d
    //      n2 = a * a / b
    //      d = b
    //  (a / b)^3 = (a * a / b * a / b) / b = (n2 * n1 / d) / d
    //      n3 = n2 * n1 / d = a * a / b * a / b
    //      d = b
    //  (a / b)^4 = ((a * a / b) * (a * a / b) / b) / b = (n2 * n2 / d) / d
    //      n4 = n2 * n2 / d
    //      d = b
    //  (a / b)^5 = (n3 * n2 / d) / d
    //      n5 = n3 * n2 / d
    //      d = b
    //  (a / b)^6 = (n3 * n3 / d) / d
    //      n6 = n3 * n3 / d
    //      d = b
    //  (a / b)^7 = (n3 * n4 / d) / d
    //      n7 = n3 * n4 / d
    //      d = b
    //  _nLeverage() helps to calculate a numerator of:
    //      + (basePrice / cPx)^(abs(i))
    //      + (cPx / basePrice)^(abs(i))
    function _nLeverage(uint256 _a, uint256 _b, uint256 _leverage) internal virtual pure returns (uint256) {
        if (_leverage == 2)
            return _n2(_a, _b);
        else if (_leverage == 3)
            return _n3(_a, _b);
        
        if (_leverage % 3 == 0 || _leverage % 3 == 2)
            return _n3(_a, _b) * _nLeverage(_a, _b, _leverage - 3) / _b;
        else 
            return _n2(_a, _b) * _nLeverage(_a, _b, _leverage - 2) / _b;
    }

    function _n2(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a * _a / _b;
    }

    function _n3(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _n2(_a, _b) * _a / _b;
    }

    function _fetch(
        address _cToken,
        address _quoteToken,
        address _lpToken
    ) internal virtual returns (uint256 _lpPx, uint256 _cPx) {
        address _token0 = IUniswapV2Pair(_lpToken).token0();
        address _token1 = IUniswapV2Pair(_lpToken).token1();
        uint256 _totalSupply = IUniswapV2Pair(_lpToken).totalSupply();
        (uint256 _r0, uint256 _r1, ) = IUniswapV2Pair(_lpToken).getReserves();

        uint256 _sqrtK = Math.sqrt(_r0 * _r1) * Q112 / _totalSupply;
        uint256 _px0 = _getPrice(_token0, _quoteToken);
        uint256 _px1 = _getPrice(_token1, _quoteToken);

        if (_cToken == _token0)
            _cPx = _px0;
        else {
            require(_cToken == _token1, "Invalid base token");
            _cPx = _px1;
        }

        _lpPx = 2 * _sqrtK * Math.sqrt(_px0) * Math.sqrt(_px1) / Q112;
    }

    function _getPrice(address _token, address _quoteToken) internal virtual returns (uint256) {
        uint256 _singleToken = 10**ERC20(_token).decimals();
        if (_token == _quoteToken)
            return _singleToken;

        address _pair = UNISWAPV2_FACTORY.getPair(_token, _quoteToken);
        return fetchPx.fetch(_token, _pair, _singleToken);
    }
}