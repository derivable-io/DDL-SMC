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
        int128 leverage;
    }

    uint256 private constant Q112 = 2**112;

    IFetchUniswapV2 public fetchPx;
    IUniswapV2Factory public immutable UNISWAPV2_FACTORY;

    mapping(address => TokenInfo) private _dTokens;

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

    function fetch(address _dToken) external virtual returns (uint256) {
        TokenInfo memory _info = _dTokens[_dToken];
        require(
            _info.lpToken != address(0), "DToken not found"
        );

        (uint256 _lpPx, uint256 _cPx) = _fetch(_info.cToken, _info.quoteToken, _info.lpToken);
        //  TODO: need to find a proper scaling number
        //  PViC = _cPx^leverage / _lpPx
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