// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

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
        target = _target;
        deadline = block.timestamp + _seconds;
        minContribution = 100 wei;
        manager = msg.sender;
    }
/*
Check the total balance this contract has by calling this function
*/
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier checkTime() {
        require(block.timestamp < deadline, "You have missed the time");
        _;
    }
    modifier checkVal() {
        require(
            msg.value >= minContribution,
            "Minimum contribution is not met"
        );
        _;
    }
    modifier timeToRefund() {
        require(
            block.timestamp > deadline && raisedAmount < target,
            "You are not able take refund"
        );
        _;
    }
    modifier timeToPay() {
        require(
            block.timestamp > deadline && raisedAmount >= target,
            "Funds are still coming.."
        );
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
    modifier checkCont() {
        require(contributors[msg.sender] > 0, "You are not contributor..");
        _;
    }
/* 
First connect your account which has balance and keep in mind that you 
need to transfer minimum ammount of 1000 wei to be a contributor...
*/
    function sendEth() public payable checkTime checkVal {
        if (contributors[msg.sender] == 0) {
            totcontributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }
/*
Only Contributors can ask for refund and 
only when the target is not acheived after the deadline..
*/
    function refund() public timeToRefund checkCont {
        address payable user = payable(msg.sender);
        uint a = contributors[msg.sender];
        contributors[msg.sender] = 0;
        user.transfer(a);
    }
/*
Manager will create request for different recepients...
*/
    function createRequests(
        string memory _description,
        address payable _recipients,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = request[numRequestes];
        numRequestes++;
        newRequest.description = _description;
        newRequest.recipient = _recipients;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.totVoters = 0;
    }
/*
Only contributor can vote to the request and
only one time contributor can vote...
*/
    function voteRequest(uint256 _requestNo) public checkCont {
        Request storage thisRequest = request[_requestNo];
        require(
            thisRequest.value > 0,
            "This Request does not exist"
        );
        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted.."
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.totVoters++;
    }
/*
Manager will fulfill the request only after deadline
if the target is achieved otherwise no request would be completed....
*/
    function makePay(uint256 _requestNo) public onlyManager timeToPay {
        Request storage thisRequest = request[_requestNo];

        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            thisRequest.totVoters > totcontributors / 2,
            "Majority does not support"
        );
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}