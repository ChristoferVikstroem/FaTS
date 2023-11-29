// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8;

contract FaTS {
    mapping(address => bool) proposers;

    event Proposal(
        address rootOwner;
        address indexed proposer,
        address indexed repondent,
        uint proposedAmount
    );

    constructor() {
        rootOwner = msg.sender;
        proposer[rootOwner] = true;
    }

    modifier onlyProposer() {
        require(proposers[msg.sender], "Not a proposer.");
    }

    function setProposer(
        address proposer,
        bool canPropose
    ) onlyProposer returns () {
        require(proposer != rootOwner);
        proposers[proposer] = canPropose;
    }

    // todo think about structure of proposing and confirming, where does this happen?

    function propose(address employee, uint salary) onlyProposer returns () {
        // todo
        // save proposal somewhere
        require(true); // some condition
        emit Proposal(msg.sender, employee, salary);
    }

    function respond(bool accepts) {
        require(!signed[msg.sender]);
        // todo stuff
    }

