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

    mapping(address => Voter) public whitelist;

    Proposal[] public proposals;

    // Status for voting
    WorkflowStatus public status;

    uint winningProposalId;

    event VoterRegistered(address voterAddress);

    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    event ProposalRegistered(uint256 proposalId);

    event Voted(address voter, uint256 proposalId);

    modifier isRegisteringVotersStatus() {
        _isRegisteringVotersStatus();
        _;
    }

    modifier isProposalsRegistrationStarted() {
        _isProposalsRegistrationStarted();
        _;
    }

    modifier isVotingSessionStarted() {
        _isVotingSessionStarted();
        _;
    }

    modifier isConsistantStatus(WorkflowStatus _status) {
        _isConsistantStatus(_status);
        _;
    }

    modifier isWhitelisted() {
        _isWhitelisted();
        _;
    }

    modifier isVotingSessionEnded(){
        _isVotingSessionEnded();
        _;
    }

    modifier isVotesTallied(){
        _isVotesTallied();
        _;
    }

    // Throws if status different of RegisteringVoters.
    function _isRegisteringVotersStatus() internal view {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "Registration period for voter is closed."
        );
    }

    // Throws if user is not whitelisted.
    function _isWhitelisted() internal view {
        require(
            whitelist[msg.sender].isRegistered == true,
            "Only whitelisted voters are authorized to do this action."
        );
    }

    // Throws if status different of RegisteringVoters.
    function _isProposalsRegistrationStarted() internal view {
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration is closed."
        );
    }

    // Throws if status different of RegisteringVoters.
    function _isVotingSessionStarted() internal view {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Voting session is closed."
        );
    }

    function _isVotingSessionEnded() internal view {
        require(
            status == WorkflowStatus.VotingSessionEnded,
            "Voting is not closed."
        );
    }

    function _isVotesTallied() internal view {
        require(
            status == WorkflowStatus.VotesTallied,
            "Votes count is not yet done"
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
    function registerVoter(address _voterAdress)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        require(whitelist[_voterAdress].isRegistered == false, "Voter is already whitelisted");
        whitelist[_voterAdress].isRegistered = true;
        emit VoterRegistered(_voterAdress);
    }

    // function to register a several voters
    function registerVoters(address[] memory _votersAdresses)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        for (uint256 i = 0; i < _votersAdresses.length; i++) {
            if ( whitelist[_votersAdresses[i]].isRegistered = true){
                whitelist[_votersAdresses[i]].isRegistered = true;
                emit VoterRegistered(_votersAdresses[i]);
            }
        }
    }

    // function to register a proposal
    function registerProposal(string memory description)
        external
        isWhitelisted
        isProposalsRegistrationStarted
    {
        proposals.push(Proposal(description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    // function to register a whitelist
    function setStatus(WorkflowStatus _status)
        internal
        onlyOwner
        isConsistantStatus(_status)
    {
        WorkflowStatus oldStatus = status;
        status = _status;
        emit WorkflowStatusChange(oldStatus, _status);
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    function voting(uint256 proposalId)
        external
        isVotingSessionStarted
        isWhitelisted
    {
        require(
            !whitelist[msg.sender].hasVoted,
            "You have already voted. Only one vote is allowed"
        );
        require(
            proposalId < proposals.length,
            "Proposal Id doesn't exist. Please select a valid proposal Id"
        );
        proposals[proposalId].voteCount++;
        whitelist[msg.sender].votedProposalId = proposalId;
        whitelist[msg.sender].hasVoted = true;
        emit Voted(msg.sender, proposalId);
    }

    function computeWinningProposal() 
        external 
        onlyOwner 
        isVotingSessionEnded
    {
        uint256 maxVotes = 0;
        uint256 tempWinningProposalId;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                tempWinningProposalId = i;
            }
        }
        winningProposalId = tempWinningProposalId;
        setStatus(WorkflowStatus.VotesTallied);
    }

    function getWinningProposalDetails() 
        external 
        view
        isVotesTallied
        returns (Proposal memory)
    {
       return proposals[winningProposalId];
    }  

 
}
