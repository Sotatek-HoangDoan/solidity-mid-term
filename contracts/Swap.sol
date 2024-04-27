// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap {
    /**
    * Viet mot contract tạo request swap => struct SwapRequest {requester address, amount, tokenA: address, tokenB: address, tokenAAmount, tokenBAmount, status, claims};
    Tính năng user A create, cancel
    Tính năng user B approve, reject
    Có ví treasury và fee

    A cancel, B approve, reject => cần có một cơ chế lưu để đễ truy xuất vào xác nhận => request là array
    */
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
    mapping(address => uint[]) public ownerToRequests;
    mapping(address => uint[]) public partnerToRequests;
    address public treasury;
    uint constant fee = 500;

    event SwapRequestCreated(address _requester, address _partner, address _payToken, uint _payAmount, address _requestToken, uint _requestAmount);
    event SwapRequestApproved(SwapRequest _request);
    event SwapRequestRejected(SwapRequest _request);
    event SwapRequestCancelled(SwapRequest _request);

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function create(
        address _partner,
        address _payToken,
        address _requestToken,
        uint _payAmount,
        uint _requestAmount
    ) public returns (bool) {
        require(_payAmount > 0, "Payment amount should be grater than 0");
        require(_requestAmount > 0, "Payment amount should be grater than 0");

        _create(_partner, _payToken, _requestToken, _payAmount, _requestAmount);
        emit SwapRequestCreated(msg.sender, _partner, _payToken, _payAmount, _requestToken, _requestAmount);
        return true;
    }

    function approve(uint _index) public returns (bool) {
        require(requests[_index].partner == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _approve(_index);
        emit SwapRequestApproved(requests[_index]);
        return true;
    }

    function reject(uint _index) public returns (bool) {
        require(requests[_index].partner == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _reject(_index);
        emit SwapRequestRejected(requests[_index]);
        return true;
    }

    function cancel(uint _index) public returns (bool) {
        require(requests[_index].requester == msg.sender);
        require(requests[_index].status == SwapRequestStatus.Created);
        _cancel(_index);
        emit SwapRequestCancelled(requests[_index]);
        return true;
    }

    function _create(
        address _partner,
        address _payToken,
        address _requestToken,
        uint _payAmount,
        uint _requestAmount
    ) private {
        IERC20(_payToken).transferFrom(msg.sender, address(this), _payAmount);

        SwapRequest memory request;
        request.requester = msg.sender;
        request.partner = _partner;
        request.payToken = _payToken;
        request.requestToken = _requestToken;
        request.payAmount = _payAmount;
        request.requestAmount = _requestAmount;
        request.status = SwapRequestStatus.Created;

        requests.push(request);

        uint index = requests.length - 1;

        ownerToRequests[msg.sender].push(index);
        partnerToRequests[_partner].push(index);
    }

    function _approve(uint _index) private {
        SwapRequest memory request = requests[_index];
        uint requestFeeAmount = (request.requestAmount * fee) / 10000;
        uint payFeeAmount = (request.payAmount * fee) / 10000;
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

        requests[_index].status = SwapRequestStatus.Approved;
    }

    function _reject(uint _index) private {
        SwapRequest memory request = requests[_index];
        IERC20(request.payToken).transfer(request.requester, request.payAmount);
        requests[_index].status = SwapRequestStatus.Rejected;
    }

    function _cancel(uint _index) private {
        SwapRequest memory request = requests[_index];
        IERC20(request.payToken).transfer(request.requester, request.payAmount);
        requests[_index].status = SwapRequestStatus.Cancelled;
    }
}
