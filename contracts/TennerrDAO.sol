// SPDX-License-Identifier: unlicensed
pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TennerrDAO is AccessControl, VRFConsumerBase {
  using SafeMath for uint;

  mapping(bytes32 => bytes32) public disputeIdToJobId;

  // 0-3: voting options , 4: time of dispute opening 5: stepId 6: dispute result
  mapping(bytes32 => uint256[]) public votesOnDispute;
  // 0: disputed staker, 1: disputing holder
  mapping(bytes32 => address[]) public disputingPartiesByDisputeId;

  mapping(bytes32 =>bool) public isDisputeOpen;

  // Create a new role identifier for the diff roles
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
  bytes32 public constant REPLACER_ROLE = keccak256("REPLACER_ROLE");

  bytes32 internal keyHash;
  uint256 internal fee;

  uint256 public randomResult;

  constructor()
  VRFConsumerBase(
      0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
      0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
  )
   public
    {
      /* chainlink setup */
      keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
      fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
      // give admin role to deployer
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(SETTER_ROLE, address(this));
    }

  // issueId: 0 jobNotDelivered, 1 jobNotMeetingExpectation, 2 other
  function disputeJob(bytes32 jobId, address staker, uint issueId) public returns (bytes32){
    /* require to be party involved in job
    or part of elected governance */
    require(issueId < 3, " Invalid issue Id");
    bytes32 disputeId = keccak256(abi.encodePacked(jobId, issueId, staker));
    require(isDisputeOpen[disputeId] != false,"Dispute already closed.");
    votesOnDispute[disputeId] = [0,0,0, block.timestamp, issueId, 6];
    disputeIdToJobId[disputeId] = jobId;
    disputingPartiesByDisputeId[disputeId] = [staker, msg.sender];
    isDisputeOpen[disputeId] = true;
  }

  // vote: 0 giveBackToBuyer, 1 giveToSeller, 2 split
  function voteOnDispute(bytes32 disputeId, uint8 vote) public {
    require(isDisputeOpen[disputeId],"Dispute closed or non-existant.");
    uint deadline = votesOnDispute[disputeId][3] + 2 days;
    require( block.timestamp < deadline, "Deadline passed. Voting closed.");
    uint weight = 1;
    if (vote == 0) {
      votesOnDispute[disputeId][0] += weight;
    } else if (vote ==1) {
      votesOnDispute[disputeId][1] += weight;
    } else if (vote ==2) {
      votesOnDispute[disputeId][2] += weight;
    }
  }

  function getDisputeDecision(bytes32 disputeId) public {
    require(isDisputeOpen[disputeId],"Dispute closed or non-existant.");
    uint deadline = votesOnDispute[disputeId][3] + 2 days;
    require( block.timestamp > deadline, "Voting still open. Try later.");
    uint totalVotes = votesOnDispute[disputeId][0] + votesOnDispute[disputeId][1] + votesOnDispute[disputeId][2];
    uint winner = 5;
    if ((votesOnDispute[disputeId][0] > votesOnDispute[disputeId][1]) && (votesOnDispute[disputeId][0] > votesOnDispute[disputeId][2])){
      winner = 0;
    } else if ((votesOnDispute[disputeId][1] > votesOnDispute[disputeId][0]) && (votesOnDispute[disputeId][1] > votesOnDispute[disputeId][2])){
      winner = 1;
    } else if ((votesOnDispute[disputeId][2] > votesOnDispute[disputeId][0]) && (votesOnDispute[disputeId][2] > votesOnDispute[disputeId][1])){
      winner = 2;
    }
    votesOnDispute[disputeId][5] = winner;
  }

  function executeDisputeDecision(bytes32 disputeId) public {
      require(votesOnDispute[disputeId][3]>0, "Dispute does not exist");
      require(isDisputeOpen[disputeId],"Dispute already closed.");
      uint deadline = votesOnDispute[disputeId][3] + 2 days;
      require( block.timestamp > deadline, "Voting still open. Try later.");
      require( votesOnDispute[disputeId][5] != 5, "No decision yet.");
      require( votesOnDispute[disputeId][5] != 6," Decision is a draw, no enforceable action.");

      address staker = disputingPartiesByDisputeId[disputeId][0];
      address disputer = disputingPartiesByDisputeId[disputeId][1];
      /* execute decision */
  }

  /* function _electVoters() internal {
  }
  function _distributeVotingRights() internal {
  }
  function _calculateFee() internal {
  }
  function _distributeFee() internal {
  } */

  function getRandomNumber(uint256 userProvidedSeed, address roller) public returns (bytes32 requestId) {
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      requestId = requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
  }

  function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues;
  }

  // fallback function
  receive() external payable { }

}
