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


contract Tennerr is Ownable, ReentrancyGuard, ChainlinkClient {
  using SafeERC20 for IERC20;
  using SafeMath for uint;
  using Counters for Counters.Counter;

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

  mapping(address => bool) public isSellerRegistered;
  // a mapping of sellers
  mapping(uint256 => Seller) sellers;

  event SellerRegistered(address sellerAddress, string name, string area);


  constructor() public {}

  /* register dev/seller */
  function registerSeller(string memory name, string memory area, string memory socialHandle) public {
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
    emit SellerRegistered(msg.sender, name, area);
  }
  /* open quote from seller */
  function jobQuoteBySeller() public {
    require(isSellerRegistered[msg.sender], 'You need to register first');
    /* TO DO */
  }


  /* pay seller quote */
  function paySeller(
    address seller,
    uint sellerQuoteId,
    uint amount,
    string memory currency,
    uint nofdaysdeadline,
    uint revisions) public {
     /* requires seller to be registered  */
     /* require buyer to have enough money  */
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

  // fallback function
  receive() external payable { }

}
