pragma solidity ^0.6.6;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Tennerr.sol";
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

  mapping(address => mapping(uint256 => Order)) orders;

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
    uint jobLength) external {
      uint256 orderNumber = orderNumberTracker.current();
      orderNumberTracker.increment();
      Order storage order = orders[buyer][orderNumber];
      order.orderId = orderNumber;
      order.sellerId = sellerId;
      order.buyer = buyer;
      order.seller = seller;
      order.jobId = jobId;
      order.orderPrice = price;
      order.absDeadline = block.timestamp.add(jobLength);
    /* mapDepositToController(); */
  }

 // should call this if seller or DAO approves job completion
  function withdrawalAllowed(address payee) public view returns (bool){
    return true;
  }

  function setTennerr(address payable newContract) external {
    // Check that the calling account has the admin role
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _tennerrContractAddress = newContract;
    tennerr = Tennerr(_tennerrContractAddress);
  }

  receive() external payable {}

}
