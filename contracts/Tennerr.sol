// SPDX-License-Identifier: unlicensed
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";//"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import "./TennerrController.sol";
import "./TennerrEscrow.sol";
import "./TennerrFactory.sol";
import "./TennerrStreamer.sol";
import "./TennerrDAO.sol";


contract Tennerr is AccessControl, ReentrancyGuard, ChainlinkClient {
  using SafeERC20 for IERC20;
  using SafeMath for uint;
  using Counters for Counters.Counter;

  // Create a new role identifier for the admin role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // OZ counter
  Counters.Counter private sellerIdTracker;

  struct Seller {
      uint _id;
      string name;
      string area;
      string[] socialHandles;
      uint jobsNumber;
      uint jobsVolume;
      uint reputationScore;
      string reputationLevel;
  }
  /* Quote parameters
  payment type could be something like:
    0 - all upfront
    1 - 50% downpayment
    2 - superfluid
    3 - custom etc */
  struct Quote {
      bytes32 jobId;
      uint sellerId;
      uint priceUsd;
      uint paymentType;
      uint nOfRevisions;
      uint jobLength;
      uint flowRate;
  }

  // tracks the amount spent on the platform
  mapping(address => uint256) amountSpentOnPlatformUsd;
  // authorized currency tickers on platform
  mapping(string => bool)  _AuthorizedCurrencyTickers;
  // mapping token name to blockchain addresses
  mapping(string => address) private _erc20Contracts;

  mapping(address => bool) public isSellerRegistered;
  // a mapping of sellers
  mapping(uint256 => Seller) sellers;

  mapping(address => uint) sellerIdByAddress;
  mapping(uint => address) sellerAddressById;
  mapping(bytes32 => Quote) quotes;

  mapping(address => Quote[]) quotesBySeller;
  // address of the tennerr contract
  address payable private _tennerrEscrowContractAddress;
  // tennerr contract
  TennerrEscrow public tennerrEscrow;
  // address of the tennerr controller
  address payable private _tennerrControllerContractAddress;
  // tennerr contract
  TennerrController public tennerrController;
  // address of the tennerr factory
  address payable private _tennerrFactoryContractAddress;
  // tennerr contract
  TennerrFactory public tennerrFactory;
  // address of the tennerr DAO
  address payable private _tennerrDAOContractAddress;
  // tennerr DAO contract
  TennerrDAO public tennerrDAO;
  // address of the tennerr streamer
  address payable private _tennerrStreamerContractAddress;
  // tennerr streamer contract
  TennerrStreamer public tennerrStreamer;

  ISuperToken tennerrFactoryX;

  event SellerRegistered(address sellerAddress, string name, string area);


  constructor() {
    _AuthorizedCurrencyTickers["USDC"] = true;
    addSupportedCurrency("USDC", 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);//check address checksum
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  /* register dev/seller */
  function registerSeller(string memory name,
    string memory area,
    string memory socialHandle)
    public {
      require(!isSellerRegistered[msg.sender], 'User already registered');
      sellerIdTracker.increment();
      uint sellerId = sellerIdTracker.current();
      Seller storage seller = sellers[sellerId];
      seller._id = sellerId;
      seller.name = name;
      seller.area = area;
      seller.socialHandles = [socialHandle];
      seller.jobsNumber = 0;
      seller.jobsVolume = 0;
      seller.reputationScore = 0;
      seller.reputationLevel = "Unrated";

      isSellerRegistered[msg.sender] = true;
      sellerIdByAddress[msg.sender] = sellerId;
      sellerAddressById[sellerId] = msg.sender;
      emit SellerRegistered(msg.sender, name, area);
  }
  /* open quote from seller */
  /* jobLength is how long it takes to fullfill job*/
  function jobQuoteProposal(
    uint priceInUsd,
    uint paymentType,
    uint nOfRevisions,
    uint jobLength,
    uint flowRate)
    public returns (bytes32){
      require(isSellerRegistered[msg.sender], 'You need to be registered first');
      require(paymentType < 4,'Payment type not recognized');
      uint sellerId = sellerIdByAddress[msg.sender];
      /* should be very hard to get a duplicate id from this*/
      bytes32 jobId = keccak256(abi.encodePacked(sellerId, priceInUsd, paymentType, block.timestamp));

      Quote storage quote = quotes[jobId];
      quote.jobId = jobId;
      quote.sellerId = sellerId;
      quote.priceUsd = priceInUsd;
      quote.paymentType = paymentType;
      quote.nOfRevisions = nOfRevisions;
      quote.jobLength = jobLength;
      quote.flowRate = flowRate;
      require( quote.priceUsd > 0, 'wtf');
      quotesBySeller[msg.sender].push(quote);
      return jobId;
  }


  /* pay seller quote */
  function paySeller(
    bytes32 sellerQuoteId,
    uint amountUsd,
    string memory currencyTicker) public {

      /* requires seller to be registered and buyer to have enough money  */
      /* require(amount > 0, "Deposit must be more than 0."); */
      require(_erc20Contracts[currencyTicker] != address(0), "Invalid currency code.");
      // Get deposit amount in USD
      Quote memory quote = quotes[sellerQuoteId];
      uint priceOfQuote = quote.priceUsd;
      require(amountUsd >= priceOfQuote);
      uint sellerId = quote.sellerId;
      address sellerAddress = sellerAddressById[sellerId];
      uint flowRate = 0;
      if (quote.paymentType==2){flowRate = quote.flowRate;}
      uint amountMinted = _handlePayment(sellerQuoteId,msg.sender,amountUsd,quote.paymentType,currencyTicker, flowRate);
      tennerrEscrow.storeOrder(sellerId,msg.sender, sellerAddress, sellerQuoteId, priceOfQuote, quote.jobLength, quote.paymentType, flowRate, amountMinted);
  }

  function _handlePayment(
    bytes32 jobId,
    address buyerAddress,
    uint amount,
    uint paymentType,
    string memory currencyTicker,
    uint flowRate) internal returns (uint amountMinted) {
      address erc20Contract = _erc20Contracts[currencyTicker];
      // requires approval from user (tx sender, done by web3)
      IERC20(erc20Contract).safeTransferFrom(buyerAddress, _tennerrControllerContractAddress, amount);
      amountMinted = tennerrFactory.mint(amount,currencyTicker);
      /* all upfront */
      if (paymentType == 0)
      {
        // deposit all into escrow */
        _moveToEscrow(amountMinted);
      }
      else if (paymentType == 1)
      /* 50% downpayment */
      {
        _moveToEscrow(amountMinted);
      }
      else if (paymentType == 2)
      /* superfluid */
      {
        _moveToStreamer(amountMinted);
        /* This flow rate is equivalent to 1000 tokens per month, for a token with 6 decimals. */
        // uint flowRate = 385802469135802; // for 18 decimal, tokens per second
        // uint nSecondsIn30days = 2592000;
        /* start stream of credit tokens to escrow*/
        tennerrStreamer.createFlow(_tennerrEscrowContractAddress, flowRate, abi.encodePacked(jobId));
      }
  }

  function _moveToEscrow(uint amountMinted) internal {
      IERC20(tennerrFactory).approve(address(this), amountMinted);
      IERC20(tennerrFactory).safeTransferFrom(address(this),_tennerrEscrowContractAddress, amountMinted);
  }

  function _moveToStreamer(uint amountMinted) internal {
      IERC20(tennerrFactory).approve(address(tennerrFactoryX), amountMinted);
      require(tennerrFactory.balanceOf(address(this))== amountMinted, 'mint failed');
      uint transferAmount = amountMinted.mul(10**18).div(10**6);
      tennerrFactoryX.upgrade(transferAmount);
      tennerrFactoryX.transfer(_tennerrStreamerContractAddress,transferAmount );
  }

/* work checkers  */
  /* get work status from buyer */
  /* get timeleft for work id for both buyer or seller*/


/* seller function */
  /* cancel order, refund buyer */
  /* ask seller to modify order (edit amount if charge extra, edit delivery time) */
/* buyer function  */
  /* order edit request approve/ deny */
  /* ask for cancel order */
  /* ask for update on order status */


/* open dispute (https://www.fiverr.com/support/articles/360010452597-Using-the-Resolution-Center)*/
  /* select reason for dispute
    other party will have up to 48h to accept or decline
    if does not reply, buyer gets money back
    if reply and accepts, propose deal or refund
    if reply and decline, disputes escaleted to DAO
   */

// issueId: 1 jobNotDelivered, 2 jobNotMeetingExpectation, 3 other
function openDispute(bytes32 jobId, uint issueId) public returns (bool success){
    TennerrEscrow.Order memory order = tennerrEscrow.getQuoteData(jobId);
    address buyer = order.buyer;
    address seller = order.seller;
    require(msg.sender == buyer, 'Only buyer can open dispute');
    success = tennerrDAO.disputeJob(jobId,buyer, seller,issueId);
}

// proposalId: 0 refund, 1 timeExtension , 2 compensationUpgrade, 3 split,
function sellerAppeal(bytes32 jobId, uint proposalId, uint proposalData, string calldata shortExplanation) public {
    TennerrEscrow.Order memory order = tennerrEscrow.getQuoteData(jobId);
    address seller = order.seller;
    require(msg.sender == seller, 'Only seller can appeal');
    tennerrDAO.updateDisputeAfterAppeal(jobId,seller,proposalId,proposalData,shortExplanation);
}

// proposalId: 0 accept, 1 timeExtension , 2 compensationUpgrade, 3 split, 4 refund
function buyerAppealResponse(bytes32 jobId, uint responseId,uint proposalData, string calldata shortExplanation) public {
    TennerrEscrow.Order memory order = tennerrEscrow.getQuoteData(jobId);
    address buyer = order.buyer;
    require(msg.sender == buyer, 'Only buyer can respond');
    tennerrDAO.buyerAppealEvaluation(jobId,buyer,responseId, proposalData, shortExplanation);
}

// proposalId: 0 accept, other: DAO
function sellerDealResponse(bytes32 jobId, uint responseId, string calldata shortExplanation) public {
    TennerrEscrow.Order memory order = tennerrEscrow.getQuoteData(jobId);
    address seller = order.seller;
    require(msg.sender == seller, 'Only seller can respond to proposed deal');
    tennerrDAO.sellerDealEvaluation(jobId,seller,responseId, shortExplanation);
}

function topUpOnOrder(bytes32 jobId, uint amount, string memory currencyTicker) external {
    address erc20Contract = _erc20Contracts[currencyTicker];
    require(IERC20(erc20Contract).balanceOf(msg.sender)>= amount);
    IERC20(erc20Contract).safeTransferFrom(msg.sender, _tennerrControllerContractAddress, amount);
    uint amountMinted = tennerrFactory.mint(amount,currencyTicker);
    _moveToEscrow(amountMinted);
    tennerrEscrow.handleTopUp(jobId,amountMinted);
}

function redeemCredit() public{
      uint tokenBalance = IERC20(tennerrFactory).balanceOf(msg.sender);
      require(tokenBalance >0, 'Get yourself some tokens you got nothing');
      uint balanceInUsd= balanceToWithdraw(msg.sender, tokenBalance);
      _withdrawFromPools("USDC",balanceInUsd, msg.sender);
      tennerrFactory.burn(msg.sender,tokenBalance);
      address erc20Contract = _erc20Contracts["USDC"];
      IERC20 token = IERC20(erc20Contract);
      token.safeTransferFrom(_tennerrControllerContractAddress, msg.sender, balanceInUsd);
}

function _withdrawFromPools(string memory currencyTicker, uint256 amount, address _to) internal {
     // Check contract balance of token and withdraw from pools
     address erc20Contract = _erc20Contracts[currencyTicker];
     TennerrController.LiquidityPool pool = TennerrController.LiquidityPool.Aave;
     tennerrController.withdrawFromPool(pool,currencyTicker,amount, _to);
     uint tennerrControllerBalance = IERC20(erc20Contract).balanceOf(_tennerrControllerContractAddress);
     require(amount <= tennerrControllerBalance, "Available balance not enough to cover amount even after pools withdrawal.");
  }

function balanceToWithdraw(address _to, uint tokenBalance) public returns (uint balanceInUsd){
  require(tokenBalance > 0, "Balance must be more than 0.");
  uint fxInterest = tennerrController.getExchangeRate(TennerrController.LiquidityPool.Aave,"USDC");
  balanceInUsd = tokenBalance.mul(fxInterest).div(10**27);
  return balanceInUsd;
}

 // add supported currency for deposits
 function addSupportedCurrency(string memory currencyTicker, address erc20Contract) public {
    _erc20Contracts[currencyTicker] = erc20Contract;
 }

 function setTennerrEscrow(address payable newContract) external {
     // Check that the calling account has the admin role
     require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
     _tennerrEscrowContractAddress = newContract;
     tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
 }

 function setTennerrController(address payable newContract) external {
   // Check that the calling account has the admin role
   require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
   _tennerrControllerContractAddress = newContract;
   tennerrController = TennerrController(_tennerrControllerContractAddress);
 }

 function setTennerrFactory(address payable newContract) external {
   // Check that the calling account has the admin role
   require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
   _tennerrFactoryContractAddress = newContract;
   tennerrFactory = TennerrFactory(_tennerrFactoryContractAddress);
 }

 function setTennerrDAO(address payable newContract) external {
   // Check that the calling account has the admin role
   require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
   _tennerrDAOContractAddress = newContract;
   tennerrDAO = TennerrDAO(_tennerrDAOContractAddress);
 }

 function setTennerrFactoryX(address payable newContract) external {
   // Check that the calling account has the admin role
   require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
   address _tennerrFactoryXContractAddress = newContract;
  tennerrFactoryX = ISuperToken(_tennerrFactoryXContractAddress);
 }

 function setTennerrStreamer(address payable newContract) external {
   // Check that the calling account has the admin role
   require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
   _tennerrStreamerContractAddress = newContract;
   tennerrStreamer= TennerrStreamer(_tennerrStreamerContractAddress);
 }



/* sellers info getters */
  /* get dev/seller telegram handle */
  /* get dev/seller discord handle */
  /* get dev/seller email */
  /* get dev/seller github or gitlab */
  /* get dev/seller portfolio link */
  /* get dev/seller rep level */

  // delete quote function, switch and pop

  function getSellerRegistration(address sellerAddress) public view returns (bool){
    return isSellerRegistered[sellerAddress];
  }

  function getSellerId() public view returns (uint){
    require(isSellerRegistered[msg.sender], 'You need to be registered first');
    return sellerIdByAddress[msg.sender];
  }

  function getSellerAddressById(uint sellerId) public view returns (address){
      return sellerAddressById[sellerId];
  }


  function getQuotesByAddress(address seller) public view returns (Quote[] memory){
      return quotesBySeller[seller];
  }

  function getQuoteByQuoteId(bytes32 sellerQuoteId) public view returns (Quote memory) {
      return quotes[sellerQuoteId];
  }

  // fallback function
  receive() external payable { }

}
