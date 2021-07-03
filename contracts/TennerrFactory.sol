// SPDX-License-Identifier: unlicensed
pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Tennerr.sol";
import "./TennerrEscrow.sol";
import "./TennerrController.sol";

/* this is similar to a vault */

contract TennerrFactory is ERC20Burnable, AccessControl{
  using SafeMath for uint;

  // initiialize tennerr
  Tennerr public tennerr;
  address payable private _tennerrContractAddress;
  // initiialize escrow
  TennerrEscrow public tennerrEscrow;
  address payable private _tennerrEscrowContractAddress;
  // initiialize tennerr
  TennerrController public tennerrController;
  address payable private _tennerrControllerAddress;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // Create a new role identifier for the minter role
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");



  constructor() public ERC20 ("Credit Tennerr Token","cTNR"){
    // give admin role to deployer
    _setupRole(ADMIN_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE,ADMIN_ROLE);
  }


  function mint(
    uint amountDeposited,
    string calldata currencyTicker)
    external returns (uint256){
      require(hasRole(MINTER_ROLE, msg.sender), "Caller is not an authorized minter");
      require(amountDeposited>0, "Deposited amount is zero.");
      tennerrController.depositToPool(TennerrController.LiquidityPool.Aave, currencyTicker, amountDeposited, msg.sender);
      // either I get it from pool or compute it here privately based on minted
      uint256 exchangeRatePool = tennerrController.getExchangeRate(TennerrController.LiquidityPool.Aave,currencyTicker);
      require(exchangeRatePool>0,"Pool exchange rate is zero. Check pool gateway.");
      uint256 mintedAmount = 0;
      mintedAmount = amountDeposited.mul(10**27).div(exchangeRatePool);
      require(mintedAmount>0,"Amount deposited not enough to mint tokens.");
      _mint(msg.sender,mintedAmount);
      return mintedAmount;
  }

  function getCurrentExchangeRate(string memory currencyTicker) internal returns (uint256){
      return tennerrController.getExchangeRate(TennerrController.LiquidityPool.Aave,currencyTicker);
  }

  function setTennerr(address payable newContract) external {
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrContractAddress = newContract;
      tennerr = Tennerr(_tennerrContractAddress);
      grantRole(MINTER_ROLE,_tennerrContractAddress );
  }

  function setTennerrEscrow(address payable newContract) external {
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrEscrowContractAddress = newContract;
      tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
  }

  function setTennerrController(address payable newContract) external {
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrControllerAddress = newContract;
      tennerrController = TennerrController(_tennerrControllerAddress);
      }
}
