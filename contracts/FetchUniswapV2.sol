// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

/**
    @title Fetch Price
    @dev This contract supports fetching price of one Token using Uniswap Pool ((UniswapV2Pair))
*/
contract FetchUniswapV2 is Ownable {
    using FixedPoint for *;

    struct Info {
        uint256 priceCumulativeLast;
        uint256 lastTimestamp;
    }

    mapping(address => mapping(address => Info)) private lastInfo;
    mapping(address => mapping(address => uint256)) private lastPriceAverages;

    function addToken(address[] calldata _tokens, address[] calldata _pools) external virtual onlyOwner {
        uint256 _len = _tokens.length;

        for (uint256 i; i < _len; i++)
            _update(_tokens[i], _pools[i]);
    }

    function fetch(address _token, address _pool, uint256 _amount) public virtual returns (uint256 _quoteAmount) {
        (uint256 _priceCumulativeLast, uint256 _lastTimestamp) = getLastInfo(_token, _pool);
        require(_lastTimestamp != 0, "Token or Pool not supported");

        (uint256 _priceCumulative, uint256 _updatedTime) = _update(_token, _pool);
        if (_priceCumulative == _priceCumulativeLast || _lastTimestamp == _updatedTime) {
            _quoteAmount = getLastPriceAvg(_token, _pool);
            require(_quoteAmount != 0, "Last quoteAmount is zero");
        }
        else {
            FixedPoint.uq112x112 memory _priceAvg = FixedPoint.uq112x112(
                uint224((_priceCumulative - _priceCumulativeLast) / (_updatedTime - _lastTimestamp))
            );
            _quoteAmount = _priceAvg.mul(_amount).decode144();

            lastPriceAverages[_token][_pool] = _quoteAmount;
        }
    }

    function _update(address _token, address _pool) internal virtual returns (uint256 _priceCumulative, uint256 _updatedTime) {
        uint256 _price0Cumulative;
        uint256 _price1Cumulative;
        //  Does not need to check whether pool is valid (reserve0 != 0 and reserve1 != 0)
        //  UniswapV2OracleLibrary already check that
        (_price0Cumulative, _price1Cumulative, _updatedTime) = 
            UniswapV2OracleLibrary.currentCumulativePrices(_pool);

        IUniswapV2Pair _pair = IUniswapV2Pair(_pool);
        if (_token == _pair.token0())
            _priceCumulative = _price0Cumulative;
        else {
            require(_token == _pair.token1(), "Invalid token or pool");
            _priceCumulative = _price1Cumulative;
        }
        
        lastInfo[_token][_pool].priceCumulativeLast = _priceCumulative;
        lastInfo[_token][_pool].lastTimestamp = _updatedTime;
    }

    function getLastInfo(address _token, address _pool) public virtual view returns (uint256, uint256) {
        return (lastInfo[_token][_pool].priceCumulativeLast, lastInfo[_token][_pool].lastTimestamp);
    }

    function getLastPriceAvg(address _token, address _pool) public virtual view returns (uint256) {
        return lastPriceAverages[_token][_pool];
    }
}
