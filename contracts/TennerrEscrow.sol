// SPDX-License-Identifier: unlicensed
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Tennerr.sol";
import "./TennerrStreamer.sol";
import "./TennerrDAO.sol";
/**
 * @title tennerrEscrow
 * @dev under construction
 */

contract TennerrEscrow is AccessControl {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  // OZ counter
  Counters.Counter private orderNumberTracker;

  // address of the tennerr contract
  address payable private _tennerrContractAddress;
  // tennerr contract
  Tennerr public tennerr;

  // address of the tennerr streamer
  address payable private _tennerrStreamerContractAddress;
  // tennerr streamer contract
  TennerrStreamer public tennerrStreamer;

  // address of the tennerr streamer
  address payable private _tennerrDAOContractAddress;
  // tennerr streamer contract
  TennerrDAO public tennerrDAO;
  // address of the tennerr factory
  address payable private _tennerrFactoryContractAddress;
  // tennerr contract
  TennerrFactory public tennerrFactory;


  /* mapping(address => mapping(uint256 => Order)) orders; */
  mapping(bytes32 => Order) public orderByOrderId;

  mapping(bytes32 => uint) public amountInEscrow;
  mapping(address => uint) public totalAmountClaimable;

  mapping(bytes32 => bool) public isWithdrawAllowed;
  // Create a new role identifier for the admin role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  constructor() public {
    // give admin role to deployer
    _setupRole(ADMIN_ROLE, msg.sender);
  }

  struct Order {
      uint orderId;
      uint sellerId;
      address buyer;
      address seller;
      bytes32 jobId;
      uint orderPrice;
      uint absDeadline;
  }

  // create order and store it
  function storeOrder(
    uint sellerId,
    address buyer,
    address seller,
    bytes32 jobId,
    uint price,
    uint jobLength,
    uint paymentType,
    uint flowRate,
    uint amountMinted) external {
      require(msg.sender == _tennerrContractAddress, 'Storing order not allowed');
      uint256 orderNumber = orderNumberTracker.current();
      orderNumberTracker.increment();
      Order storage order = orderByOrderId[jobId];
      order.orderId = orderNumber;
      order.sellerId = sellerId;
      order.buyer = buyer;
      order.seller = seller;
      order.jobId = jobId;
      order.orderPrice = price;
      order.absDeadline = block.timestamp.add(jobLength);
      totalAmountClaimable[seller] += price;
      totalAmountClaimable[buyer] += price;
      if (paymentType == 2) {
        tennerrStreamer.accountingCache(jobId,flowRate);
        uint[5] memory data = tennerrStreamer.getStreamData(jobId);
        amountInEscrow[jobId] = data[2];//streamedToDate
      } else {
        amountInEscrow[jobId] += amountMinted;
      }
      tennerrDAO.includeElegible(buyer);
      tennerrDAO.includeElegible(seller);
  }



  function editTimeline(bytes32 jobId, uint proposalData) external {
      require(_tennerrDAOContractAddress == msg.sender, 'Governance rules on this');
      // adding time from now not from original timeline
      orderByOrderId[jobId].absDeadline = block.timestamp.add(proposalData);
  }

  function editCompensation(bytes32 jobId, uint proposalData) external {
      require(_tennerrDAOContractAddress == msg.sender, 'Governance rules on this');
      orderByOrderId[jobId].orderPrice += proposalData;
  }

  function initiateRefund(bytes32 jobId) external {
      require(_tennerrDAOContractAddress == msg.sender, 'Governance rules on this');
      address _to = orderByOrderId[jobId].buyer;
      uint amount = amountInEscrow[jobId];
      amountInEscrow[jobId] -= amount;
      IERC20(tennerrFactory).approve(address(this), amount);
      IERC20(tennerrFactory).safeTransferFrom(address(this), _to, amount);
  }


  function handleTopUp(bytes32 jobId, uint amount) external {
      require(_tennerrContractAddress == msg.sender);
      amountInEscrow[jobId] += amount;
  }


  function getQuoteData(bytes32 jobId) external view returns (Order memory){
    return orderByOrderId[jobId];
  }

 // should call this if seller or DAO approves job completion
  function withdrawalAllowed(bytes32 jobId) public returns (bool){
      require(orderByOrderId[jobId].buyer == msg.sender || msg.sender == _tennerrDAOContractAddress, '' );
      isWithdrawAllowed[jobId] = true;
      return isWithdrawAllowed[jobId];
  }

  function withdrawFromEscrow(bytes32 jobId) external {
    require(orderByOrderId[jobId].seller == msg.sender,'Only seller can withdraw his money');
    require(isWithdrawAllowed[jobId], 'Withdraw not allowed.');
    _withdraw(jobId);
  }

  function _withdraw(bytes32 jobId) internal {
    address _to = orderByOrderId[jobId].seller;
    uint amount = amountInEscrow[jobId];
    IERC20(tennerrFactory).safeTransferFrom(address(this), _to, amount);
  }

  function setTennerr(address payable newContract) external {
    // Check that the calling account has the admin role
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _tennerrContractAddress = newContract;
    tennerr = Tennerr(_tennerrContractAddress);
  }

  function setTennerrStreamer(address payable newContract) external {
    // Check that the calling account has the admin role
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _tennerrStreamerContractAddress = newContract;
    tennerrStreamer= TennerrStreamer(_tennerrStreamerContractAddress);
  }

  function setTennerrDAO(address payable newContract) external {
    // Check that the calling account has the admin role
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _tennerrDAOContractAddress = newContract;
    tennerrDAO = TennerrDAO(_tennerrDAOContractAddress);
  }

  function setTennerrFactory(address payable newContract) external {
    // Check that the calling account has the admin role
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _tennerrFactoryContractAddress = newContract;
    tennerrFactory = TennerrFactory(_tennerrFactoryContractAddress);
  }

  receive() external payable {}

}
