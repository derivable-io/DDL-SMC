// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDTokenFactory.sol";
import "./interfaces/IDDLToken.sol";
import "./interfaces/IGateway.sol";

contract Pool {
    using SafeERC20 for IERC20;

    bytes32 private constant VERSION = keccak256("Pool_v1");
    uint256 private constant DENOMINATOR = 10_000;
    uint256 private constant DEFAULT_DEPEG_RATE = 10_000;

    address private immutable DFACTORY;
    address private immutable CTOKEN;
    address private immutable GATEWAY;

    uint256 private immutable TCR;
    uint256 private immutable FEE_BASE;
    uint256 private immutable FEE_RATE;

    address private _cpToken;
    address private _owner;
    uint256 private _totalMintedDToken;

    mapping(bytes32 => address) private _dTokens;
    mapping(address => uint256) private _depegs;
    string private _poolURL;

    bool private _poolLocked;

    event NewDerivative(address indexed pool, address indexed dToken, bytes32 dHash);
    event AddCollateral(address indexed sender, uint256 indexed cAmount, uint256 indexed cpAmount);
    event RemoveCollateral(address indexed receiver, uint256 indexed cpAmount, uint256 indexed cAmount);
    event MintDerivative(address indexed sender, uint256 indexed cAmount, uint256 indexed dAmount);
    event BurnDerivative(address indexed receiver, uint256 indexed dAmount, uint256 indexed cAmount);

    modifier onlyOwner() {
        require(msg.sender == poolOwner(), "Only Pool Owner");
        _;
    }

    /**
        @param _extCont               External Contracts
            [0]: PoolOwner - Address that manages Collateral Pool contract
                - Pool Owner (EOA)
                - Management contract
                - DAO
            [1]: CToken - Address of Liquidity Token (Native Coin = 0x00)
    */
    constructor(
        address _dFactory,
        address _gateway,
        address[2] memory _extCont,
        uint256[3] memory _poolConfigurations,
        string memory _poolURL_
    ) {
        _owner = _extCont[0];

        DFACTORY = _dFactory;
        GATEWAY = _gateway;
        CTOKEN = _extCont[1];
        
        TCR = _poolConfigurations[0];
        FEE_BASE = _poolConfigurations[1];
        FEE_RATE = _poolConfigurations[2];
        _poolURL = _poolURL_;
    }

    function initialize(address _cpToken_, address _initializer, uint256 _amount) external payable {
        require(
            cpToken() == address(0), "CPToken already set"
        );

        _cpToken = _cpToken_;
        IDDLToken(_cpToken_).mint(_initializer, _amount);
    }

    function lock() external onlyOwner {
        _poolLocked = true;
    }

    function unlock() external onlyOwner {
        _poolLocked = false;
    }

    function updateURL(string calldata _url) external onlyOwner {
        _poolURL = _url;
    }

    function addDToken(
        bytes32 _hash,
        address _extLogic,
        string calldata _name,
        string calldata _symbol,
        string calldata _url
    ) external onlyOwner {
        address _dToken = IDTokenFactory(DFACTORY).newDToken(
            address(this), _hash, _name, _symbol, _url
        );
        _dTokens[_hash] = _dToken;
        _depegs[_dToken] = DEFAULT_DEPEG_RATE;

        IGateway(gateway()).setExtLogic(_dToken, _extLogic);

        emit NewDerivative(address(this), _dToken, _hash);
    }

    function adjustDepegRate(address _dToken, uint256 _newValue) external onlyOwner {
        uint256 _currentRate = depegRate(_dToken);
        require(
            _currentRate != 0 && _newValue < _currentRate,
            "Invalid depeg rate"
        );

        _depegs[_dToken] = _newValue;
    }

    //  TODO: logic constraints not yet implemented, i.e. CR < TCR 
    function addCollateral(uint256 _cAmount) external payable {
        _deposit(_cAmount);
        _addCollateral(msg.sender, _cAmount);
    }

    //  TODO: logic constraints not yet implemented, i.e. CR < TCR 
    function removeCollateral(uint256 _cpAmount) external {
        address _requestor = msg.sender;
        address _cpToken_ = cpToken();
        require(
            IERC20(_cpToken_).balanceOf(_requestor) >= _cpAmount, "Insufficient balance"
        );
    
        (uint256 _totalC, uint256 _totalCP) = total();
        uint256 _cAmount = _totalC * _cpAmount / _totalCP;
        _withdraw(_cpToken_, _requestor, _cpAmount, _cAmount);

        emit RemoveCollateral(_requestor, _cpAmount, _cAmount);
    }

    //  TODO: logic constraints not yet implemented, i.e. CR < TCR 
    //  R_DC = sum(R_DCi)
    function mintDerivative(address _dToken, uint256 _cAmount) external payable {
        _deposit(_cAmount);

        address _requestor = msg.sender;
        (uint256 _dAmount, uint256 _fee) = _derivative(_dToken, _cAmount, true);
        IDDLToken(_dToken).mint(_requestor, _dAmount);

        emit MintDerivative(_requestor, _cAmount - _fee, _dAmount);
    }

    //  TODO: logic constraints not yet implemented, i.e. CR < TCR
    //  Update R_DC
    function burnDerivative(address _dToken, uint256 _dAmount) external {
        address _requestor = msg.sender;
        require(
            IERC20(_dToken).balanceOf(_requestor) >= _dAmount, "Insufficient balance"
        );

        (uint256 _cAmount, ) = _derivative(_dToken, _dAmount, false);
        _withdraw(_dToken, _requestor, _dAmount, _cAmount);

        emit BurnDerivative(_requestor, _dAmount, _cAmount);
    }

    function depegRate(address _dToken) public view returns (uint256) {
        return _depegs[_dToken];
    }

    function total() public view returns (uint256 _totalC, uint256 _totalCP) {
        address _token = cToken();
        if (_token == address(0))
            _totalC = address(this).balance;
        else
            _totalC = IERC20(_token).balanceOf(address(this));

        _totalCP = IERC20(cpToken()).totalSupply();
    }

    function collateralRatio() public view returns (uint256 _cr) {
        uint256 _totalD = _totalMintedDToken;
        (uint256 _totalC, ) = total();
        if (_totalD == 0)
            _cr = type(uint256).max;
        else
            _cr = 1 + _totalC / _totalD;
    }

    function poolLocked() external view returns (bool) {
        return _poolLocked;
    }

    function poolInfo() public view returns (uint256 _tcr, uint256 _feeBase, uint256 _feeRate) {
        return (TCR, FEE_BASE, FEE_RATE);
    }
    
    function gateway() public view returns (address) {
        return GATEWAY;
    }

    function cToken() public view returns (address) {
        return CTOKEN;
    }

    function dFactory() external view returns (address) {
        return DFACTORY;
    }

    function poolOwner() public view returns (address) {
        return _owner;
    }

    function dToken(bytes32 _hash) public view returns (address) {
        return _dTokens[_hash];
    }

    function cpToken() public view returns (address) {
        return _cpToken;
    }

    function url() external view returns (string memory) {
        return _poolURL;
    }

    function _getDepeg(address _dToken) private view returns (uint256 _depeg) {
        _depeg = depegRate(_dToken);
        require(_depeg != 0, "DToken not found");
    }

    function _derivative(address _dToken, uint256 _inAmount, bool _isMint) private returns (uint256 _outAmount, uint256 _fee) {
        uint256 _depeg = _getDepeg(_dToken);
        uint256 _quote = IGateway(gateway()).getMarketPrice();
        //  Mint Derivative:
        //  - Fee is charged on an amount of CToken (`_inAmount`) before calculating a minting amount of DToken (`_outAmount`)
        //  Burn Derivative:
        //  - Fee is charged on an amount of CToken (`_outAmount`) after calculating a burning amount of DToken (`_inAmount`)
        if (_isMint) {
            _fee = _chargeFee(_inAmount);
            _outAmount = (_inAmount - _fee) * DENOMINATOR / (_quote * _depeg);
        }
        else {
            _outAmount = _inAmount * _quote * _depeg / DENOMINATOR;
            _fee = _chargeFee(_outAmount);
            _outAmount -= _fee;
        }

        _addCollateral(address(this), _fee);
    }

    function _addCollateral(address _to, uint256 _cAmount) private {
        (uint256 _totalC, uint256 _totalCP) = total();
        uint256 _cpAmount = _totalCP * _cAmount / _totalC;
        IDDLToken(cpToken()).mint(_to, _cpAmount);

        emit AddCollateral(_to, _cAmount, _cpAmount);
    }

    function _withdraw(address _token, address _to, uint256 _inAmount, uint256 _outAmount) private {
        IDDLToken(_token).burn(_to, _inAmount);
        _transfer(cToken(), address(this), _to, _outAmount);
    }

    function _deposit(uint256 _cAmount) private {
        address _token = cToken();
        if(_token == address(0))
            require(msg.value == _cAmount, "Invalid collateral amount");
        else
            _transfer(_token, msg.sender, address(this), _cAmount);
    }

    function _chargeFee(uint256 _inAmount) private view returns (uint256 _fee) {
        (, uint256 _feeBase, uint256 _feeRate) = poolInfo();
        return _feeBase + _feeRate * _inAmount / DENOMINATOR;
    }

    function _transfer(address _token, address _from, address _to, uint256 _amount) private {
        if(_token == address(0))
            Address.sendValue(payable(_to), _amount);
        else 
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }
}
