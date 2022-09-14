// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token20 is ERC20 {

    uint256 private _decimals;
    
    constructor(uint256 _decimals_, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _decimals = _decimals_;
    }

    function decimals() public view override returns (uint8) {
        return uint8(_decimals);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
