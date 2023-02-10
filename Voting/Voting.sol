// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    // Enumeration to manage differents sates of voting
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Voter object definition
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    // Proposal object definition
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    // Status for voting
    WorkflowStatus public status;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    mapping(address => Voter) whitelist;

    modifier isRegisteringVotersStatus() {
        _isRegisteringVotersStatus();
        _;
    }

    modifier isConsistantStatus(WorkflowStatus _status) {
        _isConsistantStatus(_status);
        _;
    }

    // Throws if status different of RegisteringVoters .
    function _isRegisteringVotersStatus() internal view {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "registration period for voter is closed."
        );
    }

    // Throws if status the workflow is not followed .
    function _isConsistantStatus(WorkflowStatus _status) internal view {
        if (_status == WorkflowStatus.RegisteringVoters) {
            require(
                status == WorkflowStatus.RegisteringVoters ||
                    status == WorkflowStatus.ProposalsRegistrationStarted,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.ProposalsRegistrationStarted) {
            require(
                status == WorkflowStatus.RegisteringVoters ||
                    status == WorkflowStatus.ProposalsRegistrationEnded,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.ProposalsRegistrationEnded) {
            require(
                status == WorkflowStatus.ProposalsRegistrationStarted ||
                    status == WorkflowStatus.VotingSessionStarted,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotingSessionStarted) {
            require(
                status == WorkflowStatus.ProposalsRegistrationEnded ||
                    status == WorkflowStatus.VotingSessionEnded,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotingSessionEnded) {
            require(
                status == WorkflowStatus.VotingSessionStarted ||
                    status == WorkflowStatus.VotesTallied,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotesTallied) {
            require(
                status == WorkflowStatus.VotingSessionEnded,
                "Actual status is not compatible with your choice (choose previous one or next one)"
            );
        }
    }

    // function to register a voter
    function registerVoter(address _voter)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        whitelist[_voter].isRegistered = true;
        emit VoterRegistered(_voter);
    }

    // function to register a whitelist
    function registerVoters(address[] memory _voters)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        for (uint256 i = 0; i < _voters.length; i++) {
            whitelist[_voters[i]].isRegistered = true;
            emit VoterRegistered(_voters[i]);
        }
    }

       // function to register a whitelist
    function setStatus(WorkflowStatus _status)
        external
        onlyOwner
        isConsistantStatus(_status)
    {
        status = _status;
    }


    // fonction getWinner to implement (best in term of costing than store an attribute like winningProposalId)
}
