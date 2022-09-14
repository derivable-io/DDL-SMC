// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolFactory {

    function isExisted(address _pool) external view returns (bool);
}

