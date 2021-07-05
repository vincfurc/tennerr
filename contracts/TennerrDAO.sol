// SPDX-License-Identifier: unlicensed
pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/TennerrLibrary.sol";
import "./Tennerr.sol";
import "./TennerrEscrow.sol";
import "./TennerrVotingRightsToken.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TennerrDAO is AccessControl, VRFConsumerBase {
  using SafeMath for uint;

  mapping(bytes32 => bytes32) public disputeIdToJobId;

  // 0-3: voting options , 4: time of dispute opening 5: stepId 6: dispute result
  mapping(bytes32 => uint256[]) public votesOnDispute;
  // 0: disputed seller, 1: disputing buyer
  mapping(bytes32 => address[]) public disputingPartiesByJobId;

  mapping(bytes32 =>bool) public isDisputeOpen;
  /* status, step deadline -
  status:
  0: open, 1: appealed, 2: buyer deal accepted, 3: buyer proposed deal,
   4: escaleted, 5: closed*/
  mapping(bytes32 => uint[] ) public disputeStatus;

  mapping(bytes32 => string[]) public disputeInfo;

  mapping(bytes32 => uint[]) public disputeCurrentDeal;

  address[] public elegible;

  /* address[] public electedGlobal;
  uint[2] public  valuesGlobal; */

  // address of the tennerr contract
  address payable private _tennerrContractAddress;
  // tennerr contract
  Tennerr public tennerr;
  // initiialize escrow
  TennerrEscrow public tennerrEscrow;
  address payable private _tennerrEscrowContractAddress;
  // initiialize VRT
  TennerrVotingRightsToken public tennerrVRT;
  address payable private _tennerrVRTContractAddress;

  // Create a new role identifier for the diff roles
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
  bytes32 public constant REPLACER_ROLE = keccak256("REPLACER_ROLE");

  bytes32 internal keyHash;
  uint256 internal fee;

  mapping(bytes32 => uint256) public randomResultByReqId;
  mapping(bytes32 => bytes32) public reqIdByJobId;

  uint256 private constant RANDOMNESS_IN_PROGRESS = 200;

  event RandomnessInProgress(bytes32 indexed requestId, bytes32 indexed jobId);
  event RandomnessIsHere(bytes32 indexed requestId, uint256 indexed result);

  constructor()
  VRFConsumerBase(
      0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
      0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
  )
   public
    {
      /* chainlink setup */
      keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
      fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
      // give admin role to deployer
      _setupRole(ADMIN_ROLE, msg.sender);
      _setupRole(SETTER_ROLE, address(this));
    }

  // issueId: 0: none, 1 jobNotDelivered, 2 jobNotMeetingExpectation, 3 other
  function disputeJob(bytes32 jobId, address buyer, address seller, uint issueId) public returns (bool){
      /* require to be party involved in job*/
      /* require(msg.sender == _tennerrContractAddress, 'Can only open through Tennerr'); */
      require(issueId > 0 && issueId < 4, " Invalid issue Id");
      /* voting slots, deadline, issueId, result */
      votesOnDispute[jobId] = [0,0,0, block.timestamp, issueId, 6];
      disputingPartiesByJobId[jobId] = [seller, buyer];
      isDisputeOpen[jobId] = true;
      disputeStatus[jobId] = [0, block.timestamp + 2 days];
      _updateDisputeInfo("buyer", jobId, issueId, "");
      return isDisputeOpen[jobId];
  }



  function updateDisputeAfterAppeal(bytes32 jobId, address seller, uint proposalId, uint proposalData, string memory shortExplanation) public {
      require(msg.sender == _tennerrContractAddress, 'Can only appeal through Tennerr');
      require(block.timestamp < disputeStatus[jobId][1], 'deadline has passed, refund initiated');
      disputeStatus[jobId] = [1, block.timestamp + 2 days];
      _updateDisputeInfo("seller", jobId, 0, shortExplanation);
      disputeCurrentDeal[jobId] = [proposalId, proposalData];
  }

  function buyerAppealEvaluation(bytes32 jobId, address buyer, uint proposalId,uint counterProposalData,string memory shortExplanation) public {
      require(msg.sender == _tennerrContractAddress, 'Can only appeal through Tennerr');
      require(block.timestamp < disputeStatus[jobId][1], 'deadline has passed');
      uint proposalData = disputeCurrentDeal[jobId][1];
      disputeStatus[jobId] = [1, block.timestamp + 2 days];
      _updateDisputeInfo("buyer", jobId, 0, shortExplanation);
      _evaluateResponse(jobId, proposalId, proposalData, counterProposalData, 0);
      disputeCurrentDeal[jobId] = [proposalId, counterProposalData];
  }

  function _evaluateResponse(bytes32 jobId, uint proposalId, uint proposalData, uint counterProposalData, uint refundNumb) internal {
      require(disputeStatus[jobId][0] != 4, 'Waiting for governance');
      if (proposalId == 0 && disputeCurrentDeal[jobId][0] == refundNumb){
          tennerrEscrow.initiateRefund(jobId);
          disputeStatus[jobId][0] = 5; //close
          isDisputeOpen[jobId] == false;
      } else if (proposalId == 0 && disputeCurrentDeal[jobId][0] == 1){
          tennerrEscrow.editTimeline(jobId, proposalData);
          disputeStatus[jobId][0] = 2;
          isDisputeOpen[jobId] == false;
      } else if (proposalId == 0 && disputeCurrentDeal[jobId][0] == 2){
          tennerrEscrow.editCompensation(jobId, proposalData);
          disputeStatus[jobId][0] = 2;
          isDisputeOpen[jobId] == false;
      } else if (proposalId != 0 && proposalId != 5 ) {
          disputeStatus[jobId] = [3, block.timestamp + 2 days];
          disputeCurrentDeal[jobId] = [proposalId, counterProposalData];
      } else if (proposalId == 5 ){
        disputeStatus[jobId][0] = 4;
        /* _escalationSetUp(jobId); */
        _escalationSetUpMOCK(jobId);
      }
  }

  function _escalationSetUp(bytes32 jobId) internal {
      require(msg.sender == _tennerrContractAddress, 'Can only appeal through Tennerr');
      _getRandomNumber(jobId);
  }

  function _escalationSetUpMOCK(bytes32 jobId) internal {
      require(msg.sender == _tennerrContractAddress, 'Can only appeal through Tennerr');
      bytes32 requestId = "0xxx";
      reqIdByJobId[jobId] = requestId;
      randomResultByReqId[requestId] = 3;
  }

  function electVoters(bytes32 jobId) public {
      require(disputeStatus[jobId][0] == 4, 'Dispute not escalated');
      uint[] memory values;
      uint len = elegible.length;
      bytes32 reqId = reqIdByJobId[jobId];
      if (len > 7){ len = 7 ;}
      values = expand(randomResultByReqId[reqId], len);
      uint[2] memory newValues = _modValues(values, len, jobId);
      address[2] memory elected = _electVoters(newValues);
      /* valuesGlobal = newValues;
      electedGlobal =  elected; */
      _distributeVotingRights(elected);
  }

  function _modValues(uint[] memory values, uint len, bytes32 jobId) public returns (uint[2] memory newValues){
      uint index;
      for (uint i=0; i < len; i++) {
         index = values[i] % (len - i);
         newValues[i] = index;
      }
  }

  function _distributeVotingRights(address[2] memory beneficiaries) internal {
    uint amountGov = _calculateFee();
    tennerrVRT.issueMulti(beneficiaries);
  }

  function _calculateFee() internal view returns (uint) {

  }
  function _distributeFee() internal {
  }

  function _electVoters(uint[2] memory values) internal view returns (address[2] memory elected) {
      for(uint i =0; i < values.length; i++){
        address selection = elegible[values[i]];
        elected[i] = selection;
      }
  }

  function sellerDealEvaluation(bytes32 jobId, address buyer, uint proposalId,string memory shortExplanation) public {
      require(msg.sender == _tennerrContractAddress, 'Can only appeal through Tennerr');
      require(block.timestamp < disputeStatus[jobId][1], 'deadline has passed');
      uint proposalData = disputeCurrentDeal[jobId][1];
      disputeStatus[jobId] = [1, (block.timestamp + 2 days)];
      _updateDisputeInfo("buyer", jobId, 0, shortExplanation);
      if (proposalId == 0) {_evaluateResponse(jobId, proposalId, proposalData, 0, 4);}
      else {_evaluateResponse(jobId, 5, proposalData, 0, 4);}
      disputeCurrentDeal[jobId] = [proposalId, 0];
  }

  function _updateDisputeInfo(string memory actor, bytes32 jobId, uint issueId, string memory infoData) internal {
      string memory info2;
      if (issueId != 0) {
        if (issueId == 1) { info2 = " - Job Not Delivered";}
        if (issueId == 2) { info2 = " - Job Not Meeting Expectation";}
        if (issueId == 3) { info2 = " - Other";}
      } else { info2 = infoData;}
      string memory info = TennerrLibrary.append(actor, info2);
      disputeInfo[jobId].push(info);
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

      address staker = disputingPartiesByJobId[disputeId][0];
      address disputer = disputingPartiesByJobId[disputeId][1];
      /* execute decision */
  }


  function includeElegible(address citizen) public {
      require(msg.sender == _tennerrEscrowContractAddress, 'Can only append from Escrow');
      elegible.push(citizen); // welcome my friend
  }

  function getElegibleList() public view returns (address[] memory){
      return elegible;
  }

  function setTennerr(address payable newContract) external {
      // Check that the calling account has the admin role
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrContractAddress = newContract;
      tennerr = Tennerr(_tennerrContractAddress);
  }

  function setTennerrEscrow(address payable newContract) external {
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrEscrowContractAddress = newContract;
      tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
  }

  function setTennerrVRT(address payable newContract) external {
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _tennerrVRTContractAddress = newContract;
      tennerrVRT = TennerrVotingRightsToken(_tennerrVRTContractAddress);
  }

  function _getRandomNumber(bytes32 jobId) internal returns (bytes32 requestId) {
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      requestId = requestRandomness(keyHash, fee);
      reqIdByJobId[jobId] = requestId;
      randomResultByReqId[requestId] = RANDOMNESS_IN_PROGRESS;
      emit RandomnessInProgress(requestId, jobId);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      uint len = elegible.length;
      uint256 value = randomness.mod(len).add(1);
      randomResultByReqId[requestId] = value;
      emit RandomnessIsHere(requestId, value);
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
