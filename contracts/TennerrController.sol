// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/ILendingPool.sol";
import "../interfaces/IProtocolDataProvider.sol";
import "../interfaces/IAToken.sol";
import "./Tennerr.sol";
import "./TennerrEscrow.sol";

// the controller should manage the deposit/withdrawls to/from pools

contract TennerrController is Ownable, AccessControl {
  using SafeMath for uint;
  // initiialize tennerr
  Tennerr public tennerr;
  address payable private _tennerrContractAddress;
  // initiialize escrow
  TennerrEscrow public tennerrEscrow;
  address payable private _tennerrEscrowContractAddress;

  ILendingPool public aaveLendingPool;
  address public aaveLendingPoolAddress;
  IProtocolDataProvider public aaveDataProvider;
  address public aaveDataProviderAddress;

  /* for now only Aave on polygon, could add other defi projects too */
  enum LiquidityPool {Aave}
  mapping(string => LiquidityPool[]) private poolsByCurrency;

  // mapping token name to blockchain addresses
  mapping(string => address) private _erc20Contracts;
  // Map currecy ticker to pools
  mapping(string => TennerrController.LiquidityPool[]) private _poolsByCurrency;

  mapping(address => uint ) public amountDeposited;
  uint public _netDepositsUsd;

  uint256 precision = 12;

  constructor() public {
    // Add supported currencies e.g. USDC
    addSupportedCurrency("USDC", 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    // Add what pool the currency can be sent to
    addPoolToCurrency("USDC", TennerrController.LiquidityPool.Aave);
  }

  function depositToPool(LiquidityPool pool, string calldata currencyCode, uint256 amount, address _depositor) external {
    address erc20Contract = _erc20Contracts[currencyCode];
    require(erc20Contract != address(0), "Invalid currency code.");
    IERC20 token = IERC20(erc20Contract);
    if (pool == LiquidityPool.Aave){
      aaveLendingPool = ILendingPool(aaveLendingPoolAddress);
       /* approve  */
      token.approve(aaveLendingPoolAddress,amount);
      /* deposit */
      aaveLendingPool.deposit(erc20Contract,amount,address(this),0);
    } else revert("Invalid pool index.");
    _updateDepositsCache(amount,currencyCode, _depositor);
  }

  function _updateDepositsCache(uint amountUsd, string memory currencyTicker, address _depositor) public {
    _netDepositsUsd += amountUsd;
    amountDeposited[_depositor] += amountUsd;
  }

  function withdrawFromPool(LiquidityPool pool, string calldata currencyCode, uint256 amount, address _to) external {
      require(msg.sender == _tennerrContractAddress);
      _withdrawFromPool(pool, currencyCode, amount, _to);
  }

  function _withdrawFromPool(LiquidityPool pool, string memory currencyCode, uint256 amount, address _to) public {
      address erc20Contract = _erc20Contracts[currencyCode];
      require(erc20Contract != address(0), "Invalid currency code.");
      uint amountToWithdraw = amount;
      if (pool == LiquidityPool.Aave){
        aaveLendingPool = ILendingPool(aaveLendingPoolAddress);
        aaveLendingPool.withdraw(erc20Contract,amountToWithdraw,address(this));
      } else revert("Invalid pool index.");
      IERC20(erc20Contract).approve(_tennerrEscrowContractAddress, amountToWithdraw);
      _updateWithdrawalsCache(amount,currencyCode, _to);
  }

  function _updateWithdrawalsCache(uint amountUsd, string memory currencyTicker, address _to) public {
    _netDepositsUsd -= amountUsd;
    amountDeposited[_to] -= amountUsd;
  }

  // add supported currency for deposits
  function addSupportedCurrency(string memory currencyTicker, address erc20Contract) public {
    _erc20Contracts[currencyTicker] = erc20Contract;
  }
  // add available pool for the specific currency
  function addPoolToCurrency(string memory currencyTicker, TennerrController.LiquidityPool pool) public {
    _poolsByCurrency[currencyTicker].push(pool);
  }

  function setTennerr(address payable newContract) external onlyOwner {
        _tennerrContractAddress = newContract;
        tennerr = Tennerr(_tennerrContractAddress);
  }

  function setTennerrEscrow(address payable newContract) external onlyOwner {
        _tennerrEscrowContractAddress = newContract;
        tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
  }

  function setAaveLendingPoolAddress(address payable newContract) external onlyOwner {
        aaveLendingPoolAddress= newContract;
        aaveLendingPool = ILendingPool(aaveLendingPoolAddress);
  }

  function setAaveDataProviderAddress(address newContract) external onlyOwner {
        aaveDataProviderAddress= newContract;
        aaveDataProvider = IProtocolDataProvider(aaveDataProviderAddress);
  }

  function getPoolBalance(LiquidityPool pool, string memory currencyTicker) public view returns (uint256){
    address erc20Contract = _erc20Contracts[currencyTicker];
    require(erc20Contract != address(0), "Invalid currency code.");
    if (pool == LiquidityPool.Aave){
      (address aToken, address a, address b) = aaveDataProvider.getReserveTokensAddresses(erc20Contract);
      return IAToken(aToken).balanceOf(address(this));
    }
    else revert("Invalid pool index.");
  }

  function getPoolTokensBalance(LiquidityPool pool, string memory currencyTicker) public view returns (uint256){
    address erc20Contract = _erc20Contracts[currencyTicker];
    require(erc20Contract != address(0), "Invalid currency code.");
    if (pool == LiquidityPool.Aave){
      (address aToken, address a, address b) = aaveDataProvider.getReserveTokensAddresses(erc20Contract);
      return IAToken(aToken).balanceOf(address(this));
    } else revert("Invalid pool index.");
  }

  function getExchangeRate(LiquidityPool pool, string memory currencyTicker) public returns (uint256){
    address erc20Contract = _erc20Contracts[currencyTicker];
    require(erc20Contract != address(0), "Invalid currency code.");
    if (pool == LiquidityPool.Aave){
      (address _aTokenAddress, address _, address __) = aaveDataProvider.getReserveTokensAddresses(erc20Contract);
      return aaveLendingPool.getReserveNormalizedIncome(IAToken(_aTokenAddress).UNDERLYING_ASSET_ADDRESS());
    } else revert("Invalid pool index.");
    }

  receive() external payable { }

}
