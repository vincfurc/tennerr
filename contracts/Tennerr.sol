// SPDX-License-Identifier: unlicensed

pragma solidity ^0.6.6;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "./TennerrController.sol";
import "./TennerrEscrow.sol";


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
  mapping(bytes32 => Quote) quoteByQuoteId;

  // address of the tennerr contract
  address payable private _tennerrEscrowContractAddress;
  // tennerr contract
  TennerrEscrow public tennerrEscrow;
  // address of the tennerr contract
  address payable private _tennerrControllerContractAddress;
  // tennerr contract
  TennerrController public tennerrController;


  event SellerRegistered(address sellerAddress, string name, string area);


  constructor() public {
    _AuthorizedCurrencyTickers["USDC"] = true;
    addSupportedCurrency("USDC", 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);//check address checksum
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  /* register dev/seller */
  function registerSeller(string memory name, string memory area, string memory socialHandle) public {
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
  function jobQuoteProposal(uint priceInUsd, uint paymentType, uint nOfRevisions,uint jobLength ) public returns (bytes32){
    require(isSellerRegistered[msg.sender], 'You need to be registered first');
    uint sellerId = sellerIdByAddress[msg.sender];
    /* should be very hard to get a duplicate id from this*/
    bytes32 jobId = keccak256(abi.encodePacked(sellerId, priceInUsd, paymentType, block.timestamp));

    Quote storage quote = quoteByQuoteId[jobId];
    quote.jobId = jobId;
    quote.sellerId = sellerId;
    quote.priceUsd = priceInUsd;
    quote.paymentType = paymentType;
    quote.nOfRevisions = nOfRevisions;
    quote.jobLength = jobLength;

    return jobId;
  }


  /* pay seller quote */
  function paySeller(
    bytes32 sellerQuoteId,
    uint amount,
    string memory currencyTicker) public {
      /* requires seller to be registered and buyer to have enough money  */
      require(isSellerRegistered[msg.sender], 'You need to be registered first');
      /* require(amount > 0, "Deposit must be more than 0."); */
      address erc20Contract = _erc20Contracts[currencyTicker];
      require(erc20Contract != address(0), "Invalid currency code.");
      // Get deposit amount in USD
      uint amountUsd = amount;
      Quote memory quote = quoteByQuoteId[sellerQuoteId];
      uint priceOfQuote = quote.priceUsd;
      require(amountUsd >= priceOfQuote);
      uint sellerId = quote.sellerId;
      address sellerAddress = sellerAddressById[sellerId];
      address buyerAddress = msg.sender;
      uint jobLength = quote.jobLength;
     // requires approval from user (tx sender, done by web3)
     IERC20(erc20Contract).safeTransferFrom(buyerAddress, _tennerrControllerContractAddress, amount);
     tennerrEscrow.storeOrder(sellerId,buyerAddress, sellerAddress, sellerQuoteId, priceOfQuote, jobLength);
     /* if deadline > 2 days deposit in aave and keep count */
     /* increment work id for seller */
     /* update work id status to started */
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

/* dispute escalation*/
  /* chainlink VRF to pick small group of seller/buyers
    sign NDA(if needed) look at history and vote
    majority gets the money, fee goes to voters and DAO
   */


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

/* sellers info getters */
  /* get dev/seller telegram handle */
  /* get dev/seller discord handle */
  /* get dev/seller email */
  /* get dev/seller github or gitlab */
  /* get dev/seller portfolio link */
  /* get dev/seller rep level */

  function getSellerRegistration(address sellerAddress) public view returns (bool){
    return isSellerRegistered[sellerAddress];
  }

  function getSellerId() public view returns (uint){
    require(isSellerRegistered[msg.sender], 'You need to be registered first');
    return sellerIdByAddress[msg.sender];
  }

  // fallback function
  receive() external payable { }

}
