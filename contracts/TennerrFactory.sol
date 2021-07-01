// SPDX-License-Identifier: unlicensed
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Tennerr.sol";

/* this should be vault

1) deposit in tennerr
2) transfer to controller
3) mint creditTokens here in vault
4) transfer to Escrow based on payment method
5) claim from Tennerr if all OK

IF NOT OK
1) dispute from tennerr
2) chainlinkVRF in DAO contract electes voters
3) Distributer contract (isERC20/to create still) mints governance
rights token on the spot to elected addresses
4) only elected(with token) can vote on conflict, once concluded distribute collected fees
through distributer contract
5) resolve issue with last money transfer from escrow

 */

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



  constructor() public ERC20 ("Credit Tennerr Token","cTNR"){}


  function mint(
    uint amountDeposited,
    string calldata currencyTicker)
    external returns (uint256){
      require(hasRole(MINTER_ROLE, msg.sender), "Caller is not an authorized minter");
      require(amountDeposited>0, "Deposited amount is zero.");
      uint256 exchangeRateToken = getCurrentExchangeRate(currencyTicker);
      require(exchangeRateToken>0,"Exchange rate is zero");
      tennerrController.depositToPool(TennerrController.LiquidityPool.Aave, currencyTicker, amountDeposited, msg.sender);
      // either I get it from pool or compute it here privately based on minted
      uint256 exchangeRatePool = tennerrController.getExchangeRate(TennerrController.LiquidityPool.Aave,currencyTicker);
      require(exchangeRatePool>0,"Pool exchange rate is zero. Check pool gateway.");
      uint256 mintedAmount = 0;
      mintedAmount = amountDeposited.mul(10**27).div(exchangeRatePool).mul(exchangeRateToken).div(10**6);
      require(mintedAmount>0,"Amount deposited not enough to mint tokens.");
      _mint(msg.sender,mintedAmount);
      return mintedAmount;
  }

  function getCurrentExchangeRate(string memory currencyTicker) internal returns (uint256){
      return tennerrController.getExchangeRate(TennerrController.LiquidityPool.Aave,currencyTicker);
  }

  function setTennerr(address payable newContract) external {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrContractAddress = newContract;
      tennerr = Tennerr(_tennerrContractAddress);
  }

  function setTennerrEscrow(address payable newContract) external {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrEscrowContractAddress = newContract;
      tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
      grantRole(MINTER_ROLE, _tennerrEscrowContractAddress);
  }

}
