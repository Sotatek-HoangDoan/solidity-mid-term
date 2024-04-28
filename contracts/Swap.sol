// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Swap is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum SwapRequestStatus {
        Created,
        Approved,
        Rejected,
        Cancelled
    }

    struct SwapRequest {
        address requester;
        address partner;
        address payToken;
        address requestToken;
        uint payAmount;
        uint requestAmount;
        SwapRequestStatus status;
    }

    SwapRequest[] public requests;
    address public treasury;
    uint public fee; // fee * DESCRIMINATOR
    uint constant DESCRIMINATOR = 10000;

    event SwapRequestCreated(SwapRequest _request, uint _index);
    event SwapRequestApproved(SwapRequest _request);
    event SwapRequestRejected(SwapRequest _request);
    event SwapRequestCancelled(SwapRequest _request);

    function initialize (address _owner, address _treasury, uint _fee) public initializer {
        require(_treasury != address(0), "Treasury must be a valid address");
        treasury = _treasury;
        fee = _fee;
        __Ownable_init(_owner);
    }

    function updateFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function updateTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Treasury must be a valid address");
        treasury = _treasury;
    }

    function create(
        address _partner,
        address _payToken,
        address _requestToken,
        uint _payAmount,
        uint _requestAmount
    ) public {
        require(_payAmount > 0, "Payment amount should be grater than 0");
        require(_requestAmount > 0, "Payment amount should be grater than 0");

        uint index = _create(_partner, _payToken, _requestToken, _payAmount, _requestAmount);
        emit SwapRequestCreated(requests[index], index);
    }

    function approve(uint _index) public {
        require(requests[_index].partner == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _approve(_index);
        emit SwapRequestApproved(requests[_index]);
    }

    function reject(uint _index) public {
        require(requests[_index].partner == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _reject(_index);
        emit SwapRequestRejected(requests[_index]);
    }

    function cancel(uint _index) public {
        require(requests[_index].requester == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _cancel(_index);
        emit SwapRequestCancelled(requests[_index]);
    }

    function _create(
        address _partner,
        address _payToken,
        address _requestToken,
        uint _payAmount,
        uint _requestAmount
    ) private returns (uint) {

        SwapRequest memory request;
        request.requester = msg.sender;
        request.partner = _partner;
        request.payToken = _payToken;
        request.requestToken = _requestToken;
        request.payAmount = _payAmount;
        request.requestAmount = _requestAmount;
        request.status = SwapRequestStatus.Created;
        requests.push(request);

        IERC20(_payToken).transferFrom(msg.sender, address(this), _payAmount);

        return requests.length - 1;
    }

    function _approve(uint _index) private {
        SwapRequest memory request = requests[_index];
        requests[_index].status = SwapRequestStatus.Approved;
        uint requestFeeAmount = request.requestAmount * fee / DESCRIMINATOR;
        uint payFeeAmount = request.payAmount * fee / DESCRIMINATOR;
        IERC20(request.requestToken).transferFrom(
            request.partner,
            treasury,
            requestFeeAmount
        );
        IERC20(request.payToken).transfer(treasury, payFeeAmount);
        IERC20(request.requestToken).transferFrom(
            request.partner,
            request.requester,
            request.requestAmount - requestFeeAmount
        );
        IERC20(request.payToken).transfer(
            request.partner,
            request.payAmount - payFeeAmount
        );

    }

    function _reject(uint _index) private {
        SwapRequest memory request = requests[_index];
        requests[_index].status = SwapRequestStatus.Rejected;
        IERC20(request.payToken).transfer(request.requester, request.payAmount);
    }

    function _cancel(uint _index) private {
        SwapRequest memory request = requests[_index];
        requests[_index].status = SwapRequestStatus.Cancelled;
        IERC20(request.payToken).transfer(request.requester, request.payAmount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
