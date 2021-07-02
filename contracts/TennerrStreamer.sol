// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";//"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {
    SuperAppBase
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TennerrEscrow.sol";
import "./TennerrFactory.sol";

contract TennerrStreamer is SuperAppBase, AccessControl {
    using SafeMath for uint;

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token
    address private _receiver; // escrow

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // initiialize escrow
    TennerrEscrow public tennerrEscrow;
    address payable private _tennerrEscrowContractAddress;

    // address of the tennerr factory
    address payable private _tennerrFactoryContractAddress;
    // tennerr contract
    TennerrFactory public tennerrFactory;

    mapping(bytes32 => uint[]) public streamByJobId;

    struct Order {
        uint orderId;
        uint sellerId;
        address buyer;
        address seller;
        bytes32 jobId;
        uint orderPrice;
        uint absDeadline;
    }


    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        address receiver) {
        require(address(host) != address(0), "host is zero address");
        require(address(cfa) != address(0), "cfa is zero address");
        require(address(acceptedToken) != address(0), "acceptedToken is zero address");
        require(address(receiver) != address(0), "receiver is zero address");
        require(!host.isApp(ISuperApp(receiver)), "receiver is an app");

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _receiver = receiver;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        /* _host.registerAppWithKey(configWord, "0x756f6154ee853e3dfb570b618e185b3ba4652ccfd78df06eb57e16cf1f0656fc"); */
        _host.registerApp(configWord);

    }


    /**************************************************************************
     * Redirect Logic
     *************************************************************************/

    function currentReceiver()
        external view
        returns (
            uint256 startTime,
            address receiver,
            int96 flowRate
        )
    {
        if (_receiver != address(0)) {
            (startTime, flowRate,,) = _cfa.getFlow(_acceptedToken, address(this), _receiver);
            receiver = _receiver;
        }
    }

    event ReceiverChanged(address receiver);

    /// @dev If a new stream is opened, or an existing one is opened
    function _updateOutflow(bytes calldata ctx, bytes memory userData)
        private
        returns (bytes memory newCtx)
    {

      newCtx = ctx;
      // @dev This will give me the new flowRate, as it is called in after callbacks
      int96 netFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
      (,int96 outFlowRate,,) = _cfa.getFlow(_acceptedToken, address(this), _receiver); // CHECK: unclear what happens if flow doesn't exist.
      int96 inFlowRate = netFlowRate + outFlowRate;

      /* use userData to update internal accounting */
      _accountingCache(userData);

      // @dev If inFlowRate === 0, then delete existing flow.
      if (inFlowRate == int96(0)) {
        // @dev if inFlowRate is zero, delete outflow.
          (newCtx, ) = _host.callAgreementWithContext(
              _cfa,
              abi.encodeWithSelector(
                  _cfa.deleteFlow.selector,
                  _acceptedToken,
                  address(this),
                  _receiver,
                  new bytes(0) // placeholder
              ),
              "0x",
              newCtx
          );
        } else if (outFlowRate != int96(0)){
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeWithSelector(
                _cfa.updateFlow.selector,
                _acceptedToken,
                _receiver,
                inFlowRate,
                new bytes(0) // placeholder
            ),
            "0x",
            newCtx
        );
      } else {
      // @dev If there is no existing outflow, then create new flow to equal inflow
          (newCtx, ) = _host.callAgreementWithContext(
              _cfa,
              abi.encodeWithSelector(
                  _cfa.createFlow.selector,
                  _acceptedToken,
                  _receiver,
                  inFlowRate,
                  new bytes(0) // placeholder
              ),
              "0x",
              newCtx
          );
      }
    }

    function _accountingCache(bytes memory userData) internal {
        bytes32 jobId = bytesToBytes32(userData,0);
        TennerrEscrow.Order memory order = tennerrEscrow.getQuoteData(jobId);
        address buyer = order.buyer;
        address seller = order.seller;
        uint amount = order.orderPrice;
        uint streamStart = block.timestamp;
        uint deadline = order.absDeadline;
        _updateStreamData(jobId,buyer, seller, amount, streamStart, deadline);
    }

    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
      bytes32 out;

      for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }

    function _updateStreamData(
      bytes32 jobId,
      address buyer,
      address seller,
      uint amount,
      uint streamStart,
      uint deadline) internal {
        // @dev This will give me the new flowRate, as it is called in after callbacks
        int96 netFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
        (,int96 outFlowRate,,) = _cfa.getFlow(_acceptedToken, address(this), _receiver); // CHECK: unclear what happens if flow doesn't exist.
        uint inFlowRate = uint(netFlowRate + outFlowRate);
        uint timeLeft = deadline.sub(block.timestamp);
        uint timePassed = (block.timestamp).sub(streamStart);
        uint streamedToDate = inFlowRate * timePassed;

        /* token streaming, streamedToDate, totalToStream, timeLeft */
        streamByJobId[jobId] = [inFlowRate, streamedToDate, amount, streamStart, timeLeft, deadline];
    }

    function getStreamData(
      bytes32 jobId)
      public view returns  (uint[5] memory) {
        uint totalToStream = streamByJobId[jobId][2];
        uint deadline = streamByJobId[jobId][5];
        uint streamStart = streamByJobId[jobId][3];
        // @dev This will give me the new flowRate, as it is called in after callbacks
        int96 netFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
        (,int96 outFlowRate,,) = _cfa.getFlow(_acceptedToken, address(this), _receiver); // CHECK: unclear what happens if flow doesn't exist.
        uint inFlowRate = uint(netFlowRate + outFlowRate);
        uint timeLeft = deadline.sub(block.timestamp);

        /* streamByJobId[jobId].timeLeft = timeLeft; */
        uint timePassed = (block.timestamp).sub(streamStart);
        uint streamedToDate = inFlowRate * timePassed;
        /* streamByJobId[jobId].streamedToDate = streamedToDate; */
        /* token streaming, streamedToDate, totalToStream, timeLeft */
        return [inFlowRate, streamedToDate, totalToStream, timeLeft, deadline];
    }

    // @dev Change the Receiver of the total flow
    function _changeReceiver( address newReceiver ) internal {
        require(newReceiver != address(0), "New receiver is zero address");
        // @dev because our app is registered as final, we can't take downstream apps
        require(!_host.isApp(ISuperApp(newReceiver)), "New receiver can not be a superApp");
        if (newReceiver == _receiver) return ;
        // @dev delete flow to old receiver
        (,int96 outFlowRate,,) = _cfa.getFlow(_acceptedToken, address(this), _receiver); //CHECK: unclear what happens if flow doesn't exist.
        if(outFlowRate > 0){
          _host.callAgreement(
              _cfa,
              abi.encodeWithSelector(
                  _cfa.deleteFlow.selector,
                  _acceptedToken,
                  address(this),
                  _receiver,
                  new bytes(0)
              ),
              "0x"
          );
          // @dev create flow to new receiver
          _host.callAgreement(
              _cfa,
              abi.encodeWithSelector(
                  _cfa.createFlow.selector,
                  _acceptedToken,
                  newReceiver,
                  _cfa.getNetFlow(_acceptedToken, address(this)),
                  new bytes(0)
              ),
              "0x"
          );
        }
        // @dev set global receiver to new receiver
        _receiver = newReceiver;

        emit ReceiverChanged(_receiver);
    }

    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata /*_agreementData*/,
        bytes calldata ,// _cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        bytes memory userData = abi.decode(_host.decodeCtx(_ctx).userData, (bytes));
        return _updateOutflow(_ctx, userData);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 ,//_agreementId,
        bytes calldata agreementData,
        bytes calldata ,//_cbdata,
        bytes calldata _ctx
    )
        external override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        bytes memory userData = abi.decode(_host.decodeCtx(_ctx).userData, (bytes));
        return _updateOutflow(_ctx, userData );
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32 ,//_agreementId,
        bytes calldata /*_agreementData*/,
        bytes calldata ,//_cbdata,
        bytes calldata _ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        // According to the app basic law, we should never revert in a termination callback
        bytes memory userData = abi.decode(_host.decodeCtx(_ctx).userData, (bytes));
        if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass)) return _ctx;
        return _updateOutflow(_ctx, userData);
    }

    function createFlow(address newReceiver, uint flowRate, bytes memory jobId) external {
        _host.callAgreement(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    _acceptedToken,
                    newReceiver,
                    flowRate,
                    new bytes(0)
                ),
                jobId //userData: bytes
        );
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType()
            == keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }

    function setTennerrEscrow(address payable newContract) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _tennerrEscrowContractAddress = newContract;
        tennerrEscrow = TennerrEscrow(_tennerrEscrowContractAddress);
    }

    modifier onlyHost() {
        require(msg.sender == address(_host), "RedirectAll: support only one host");
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "RedirectAll: not accepted token");
        require(_isCFAv1(agreementClass), "RedirectAll: only CFAv1 supported");
        _;
    }

    receive() external payable {}

}
