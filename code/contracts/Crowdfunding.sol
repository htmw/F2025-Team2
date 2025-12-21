// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Crowdfunding {
    mapping(address => uint256) public contributors;
    address public manager;
    uint256 public minContribution;
    uint256 public target;
    uint256 public deadline;
    uint256 public raisedAmount;
    uint256 public totcontributors;

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 totVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public request;
    uint256 public numRequestes;

    constructor(uint256 _target, uint256 _seconds) {
        manager = msg.sender;
        target = _target;
        deadline = block.timestamp + _seconds;
        minContribution = 100 wei;
    }

    /* ---------------- ETH RECEIVE ---------------- */

    receive() external payable {
        _contribute();
    }

    function sendEth() public payable {
        _contribute();
    }

    function _contribute() internal {
        require(block.timestamp < deadline, "Deadline passed");
        require(msg.value >= minContribution, "Minimum 100 wei required");

        if (contributors[msg.sender] == 0) {
            totcontributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    /* ---------------- VIEW ---------------- */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /* ---------------- MODIFIERS ---------------- */

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager");
        _;
    }

    modifier onlyContributor() {
        require(contributors[msg.sender] > 0, "Not contributor");
        _;
    }

    modifier refundAllowed() {
        require(block.timestamp > deadline && raisedAmount < target, "Refund not allowed");
        _;
    }

    modifier paymentAllowed() {
        require(block.timestamp > deadline && raisedAmount >= target, "Target not met");
        _;
    }

    /* ---------------- REFUND ---------------- */

    function refund() public refundAllowed onlyContributor {
        uint amount = contributors[msg.sender];
        contributors[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* ---------------- REQUESTS ---------------- */

    function createRequests(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyManager {
        Request storage r = request[numRequestes++];
        r.description = _description;
        r.recipient = _recipient;
        r.value = _value;
        r.completed = false;
        r.totVoters = 0;
    }

    function voteRequest(uint256 _requestNo) public onlyContributor {
        Request storage r = request[_requestNo];
        require(!r.voters[msg.sender], "Already voted");

        r.voters[msg.sender] = true;
        r.totVoters++;
    }

    function makePay(uint256 _requestNo) public onlyManager paymentAllowed {
        Request storage r = request[_requestNo];

        require(!r.completed, "Already completed");
        require(r.totVoters > totcontributors / 2, "Majority not reached");

        r.completed = true;
        r.recipient.transfer(r.value);
    }
}
