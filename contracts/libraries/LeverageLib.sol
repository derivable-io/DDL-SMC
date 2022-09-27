// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

library LeverageLib {

    function _adjust(uint256 _num) internal pure returns (uint256, uint256) {
        return (_num / 11, 11);
    }

    function _abs(int256 _num) internal pure returns (uint256) {
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
    function _nLeverage(uint256 _a, uint256 _b, uint256 _leverage) internal pure returns (uint256) {
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
}
