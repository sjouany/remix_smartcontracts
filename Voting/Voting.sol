// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A contract named Voting
/// @author Sylvain JOUANY
/// @notice Provide a voting contract
contract Voting is Ownable {

    /// @notice Enumeration to manage differents sates of voting
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice Voter object definition
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    /// @notice Proposal object definition
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    /// @notice Mapping to link an address to a Voter
    mapping(address => Voter) whitelist;

    /// @notice Proposal array
    Proposal[] public proposals;

    /// @notice Current Status for voting
    WorkflowStatus public status;

    /// @notice Id for winnning proposal
    /// @dev Used to avoid to loop each time on proposals array to find the hisghest count for a proposal
    uint winningProposalId;

    /// @notice Event emitted when a voter is registered
    /// @param voterAddress address registered to the withelist
    event VoterRegistered(address voterAddress);

    /// @notice Event emitted when the workflow status change
    /// @param previousStatus previous status of the workflow
    /// @param newStatus new status of the workflow
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    /// @notice Event emitted when a new proposal is registered
    /// @param proposalId proposal id for the new proposal registered
    event ProposalRegistered(uint proposalId);

    /// @notice Event emitted when a voter do a vote
    /// @param voter adress for the voter
    /// @param proposalId proposal id choosen by the voter
    event Voted(address voter, uint proposalId);

    /// @notice Modifier to ensure the status is `RegisteringVoters`
    modifier isRegisteringVotersStatus() {
        _isRegisteringVotersStatus();
        _;
    }

    /// @notice Modifier to ensure the status is `ProposalsRegistrationStarted`
    modifier isProposalsRegistrationStarted() {
        _isProposalsRegistrationStarted();
        _;
    }

    /// @notice Modifier to ensure the status is `VotingSessionStarted`
    modifier isVotingSessionStarted() {
        _isVotingSessionStarted();
        _;
    }

    /// @notice Modifier to ensure the status is `VotingSessionStarted`
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
            whitelist[msg.sender].isRegistered == true || owner() == msg.sender,
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
            "Voting is not closed or votes count is already done"
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

    function StartRegisteringVoters() external 
    {
        setStatus(WorkflowStatus.RegisteringVoters);
    }

    function StartProposalsRegistration() external 
    {
        setStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }

    function StopProposalsRegistration() external 
    {
        setStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    function StartVotingSession() external 
    {
        setStatus(WorkflowStatus.VotingSessionStarted);
    }

    function StopVotingSession() external 
    {
        setStatus(WorkflowStatus.VotingSessionEnded);
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
    function registerProposal(string memory _description)
        external
        isWhitelisted
        isProposalsRegistrationStarted
    {
        proposals.push(Proposal(_description, 0));
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

    function voting(uint _proposalId)
        external
        isVotingSessionStarted
        isWhitelisted
    {
        require(
            !whitelist[msg.sender].hasVoted,
            "You have already voted. Only one vote is allowed"
        );
        require(
            _proposalId < proposals.length,
            "Proposal Id doesn't exist. Please select a valid proposal Id"
        );
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].votedProposalId = _proposalId;
        whitelist[msg.sender].hasVoted = true;
        emit Voted(msg.sender, _proposalId);
    }

    function discoverWinningProposal() 
        external 
        onlyOwner 
        isVotingSessionEnded
    {
        uint maxVotes = 0;
        uint tempWinningProposalId;
        for (uint i = 0; i < proposals.length; i++) {
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

    function getProposalVotedForUser(address _address)
        external 
        view 
        isWhitelisted
        returns (string memory)
    {
        require(
            whitelist[_address].hasVoted,
            "This user didn't vote"
        );
        return proposals[whitelist[_address].votedProposalId].description;
    }
}
