// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
                @dev Md. Sayem Abedin


*/
import {Ownable, ReentrancyGuard, Polling } from "./Polling.sol";

contract Factory is Ownable, ReentrancyGuard{

    // store the polls owner => polls
    mapping(address => address[]) public polls;
    uint public poll_price; // price/poll

    constructor(uint _poll_price){
        poll_price = _poll_price;
    }

    // create a new poll

    function createPoll(address _token, uint _amount_Of_polls) public payable nonReentrant returns(address poll_address){
        require(msg.value >= poll_price* _amount_Of_polls, "Insufficient payment amount");
        Polling _poll = new Polling(_token, address(this));
        polls[msg.sender].push(address(_poll));
        _poll.setAvailablePolls(_amount_Of_polls);
        return address(_poll);

    }

    function addPollCredits(address _poll, uint _amount_Of_polls) public payable nonReentrant returns(bool){
        require(msg.value >= poll_price* _amount_Of_polls, "Insufficient payment amount");
        Polling _polling = Polling(_poll);
        _polling.setAvailablePolls(_amount_Of_polls);
        return true;
    }

    function setPollPrice(uint _poll_price) public {
        poll_price = _poll_price;
    }

}