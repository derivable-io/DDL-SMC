// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICollateralPool.sol";

/**
    @title CPToken contract
    @dev This ERC-20 contract holds Counter Collateral Token of one Collateral Pool (CP)
*/

contract CPToken is ERC20 {

	address public immutable COLLATERAL_POOL;

	string private _url;

	modifier onlyCP() {
		require(msg.sender == COLLATERAL_POOL, "Only Collateral Pool");
		_;
	}
    
    constructor(
		address _pool,
		string memory _name,
		string memory _symbol,
		string memory url_
	) ERC20(_name, _symbol) {
		COLLATERAL_POOL = _pool;
		_url = url_;
	}

	function getURL() external view returns (string memory) {
		return _url;
	}

    function mint(address _to, uint256 _amount) external onlyCP {
        _mint(_to, _amount);
    }

	function burn(address _from, uint256 _amount) external onlyCP {
		_burn(_from, _amount);
	}

	function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
		super._beforeTokenTransfer(from, to, amount);
		require(
			!ICollateralPool(COLLATERAL_POOL).poolLocked(), "Pool locked! Failed to transfer"
		);
	}
}
