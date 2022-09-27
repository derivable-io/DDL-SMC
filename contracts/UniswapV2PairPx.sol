// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/FetchPairUniswapV2Lib.sol";
import "./libraries/LeverageLib.sol";

contract UniswapV2PairPx is Ownable {
    using FetchPairUniswapV2Lib for address;
    using LeverageLib for *;

    struct TokenInfo {
        address cToken;
        address quoteToken;
        address lpToken;
        int256 leverage;
    }

    address public fetchPx;

    mapping(address => TokenInfo) private _dTokens;
    mapping(address => uint256) private _basePrices;

    constructor(address _fetchPx) Ownable() {
        fetchPx = _fetchPx;
    }

    function setFetch(address _fetchPx) external virtual onlyOwner {
        require(_fetchPx != address(0), "Set zero address");

        fetchPx = _fetchPx;
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

        (uint256 _lpPx, uint256 _cPx) = fetchPx._fetch(_info.cToken, _info.quoteToken, _info.lpToken);
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
        uint256 _absLeverage = _info.leverage._abs();
        require(
            _absLeverage >= 2 && _absLeverage <= 50, "Invalid leverage"
        );

        uint256 _k = 1;
        if (_info.leverage < 0) {
            if (_basePrice < _cPx) {
                (_cPx, _k) = _cPx._adjust();
                _k = _k**_absLeverage;
            }
            return (_basePrice._nLeverage(_cPx, _absLeverage), _cPx * _k * _lpPx);
        }   
        else {
            if (_cPx < _basePrice) {
                (_basePrice, _k) = _basePrice._adjust();
                _k = _k**_absLeverage;
            }
            return (_cPx._nLeverage(_basePrice, _absLeverage), _basePrice * _k * _lpPx);
        }   
    }
}