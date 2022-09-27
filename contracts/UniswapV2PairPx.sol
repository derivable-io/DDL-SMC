// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/FetchUniswapV2Lib.sol";
import "./libraries/LeverageLib.sol";

contract UniswapV2PairPx is Ownable {
    using FetchUniswapV2Lib for address;
    using LeverageLib for *;

    struct TokenInfo {
        address bToken;         //  BaseToken (Token0/Token1)
        address qToken;         //  QuoteToken
        address lpToken;        //  LP_Token0_Token1
        int256 leverage;
    }

    address public extOracle;

    mapping(address => TokenInfo) private _dTokens;
    mapping(address => uint256) private _basePrices;

    constructor(address _extOracle) Ownable() {
        extOracle = _extOracle;
    }

    function setFetch(address _extOracle) external virtual onlyOwner {
        require(_extOracle != address(0), "Set zero address");

        extOracle = _extOracle;
    }

    function addDToken(
        address _dToken,
        TokenInfo calldata _tokenInfo
    ) external virtual onlyOwner {
        require(
            _dTokens[_dToken].lpToken == address(0), "DToken already recorded"
        );
        require(
            _tokenInfo.bToken != address(0) &&
            _tokenInfo.lpToken != address(0) &&
            _tokenInfo.qToken != address(0) &&
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

        (uint256 _lpPx, uint256 _bPx) = extOracle._fetchPair(_info.bToken, _info.qToken, _info.lpToken);
        //  if `_basePrices[_dToken] = 0` (first round), then:
        //      - `_basePrice = _bPx`
        //      - update `_basePrice[_dToken] = `_bPx`
        //      - `_basePrice = _bPx` -> (_bPx / _basePrice)^i = 1 regardless of leverage value
        //  thus, return (1, _lpPx) immediately
        uint256 _basePrice = _basePrices[_dToken];
        if (_basePrice == 0) {
            _basePrices[_dToken] = _bPx;
            return (1, _lpPx);
        }
        //  There are two cases: leverage < -2 or leverage > 2
        //  abs(leverage) should be less than or equal 50 due to EVM constraints (gas, execution timeout)
        //  PViC = (bPx / basePrice)^i / lpPx
        //  if i < 0: PViC = (basePrice / bPx)^(abs(i)) / lpPx
        //  if i > 0: PViC = (bPx / basePrice)^(abs(i)) / lpPx
        uint256 _absLeverage = _info.leverage._abs();
        require(
            _absLeverage >= 2 && _absLeverage <= 50, "Invalid leverage"
        );

        uint256 _k = 1;
        if (_info.leverage < 0) {
            if (_basePrice < _bPx) {
                (_bPx, _k) = _bPx._adjust();
                _k = _k**_absLeverage;
            }
            return (_basePrice._nLeverage(_bPx, _absLeverage), _bPx * _k * _lpPx);
        }   
        else {
            if (_bPx < _basePrice) {
                (_basePrice, _k) = _basePrice._adjust();
                _k = _k**_absLeverage;
            }
            return (_bPx._nLeverage(_basePrice, _absLeverage), _basePrice * _k * _lpPx);
        }   
    }
}