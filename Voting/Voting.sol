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
    /// @dev public to be able to get a proposal by id
    Proposal[] public proposals;

    /// @notice Current Status for voting
    /// @dev public to be able to get the current status
    WorkflowStatus public status;

    /// @notice Id for winnning proposal
    /// @dev Used to avoid to loop each time on proposals array to find the hisghest count for a proposal
    uint256 winningProposalId;

    /// @notice Event emitted when a voter is registered
    /// @param voterAddress Address registered to the withelist
    event VoterRegistered(address voterAddress);

    /// @notice Event emitted when the workflow status change
    /// @param previousStatus Previous status of the workflow
    /// @param newStatus New status of the workflow
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    /// @notice Event emitted when a new proposal is registered
    /// @param proposalId Proposal id for the new proposal registered
    event ProposalRegistered(uint256 proposalId);

    /// @notice Event emitted when a voter do a vote
    /// @param voter Address for the voter
    /// @param proposalId Proposal id choosen by the voter
    event Voted(address voter, uint256 proposalId);

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

    /// @notice Modifier to ensure the status is `VotingSessionEnded`
    modifier isVotingSessionEnded() {
        _isVotingSessionEnded();
        _;
    }
    /// @notice Modifier to ensure the status is `VotingSessionEnded`
    modifier isVotesTallied() {
        _isVotesTallied();
        _;
    }

    /// @notice Modifier to ensure the transition between old status and new status is consistant
    /// @param _status New status to be set
    modifier isConsistantStatus(WorkflowStatus _status) {
        _isConsistantStatus(_status);
        _;
    }

    /// @notice Modifier to check that the user is whitelisted
    modifier isWhitelisted() {
        _isWhitelisted();
        _;
    }

    /// @notice Throws if status different of `RegisteringVoters`.
    function _isRegisteringVotersStatus() internal view {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "Registration period for voter is closed."
        );
    }

    /// @notice Throws if user is not whitelisted.
    function _isWhitelisted() internal view {
        require(
            whitelist[msg.sender].isRegistered == true || owner() == msg.sender,
            "Only whitelisted voters are authorized to do this action."
        );
    }

    /// @notice Throws if status different of `ProposalsRegistrationStarted`.
    function _isProposalsRegistrationStarted() internal view {
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration is closed."
        );
    }

    /// @notice Throws if status different of `VotingSessionStarted`.
    function _isVotingSessionStarted() internal view {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Voting session is closed."
        );
    }

    /// @notice Throws if status different of `VotingSessionEnded`.
    function _isVotingSessionEnded() internal view {
        require(
            status == WorkflowStatus.VotingSessionEnded,
            "Voting is not closed or votes count is already done"
        );
    }

    /// @notice Throws if status different of `VotesTallied`.
    function _isVotesTallied() internal view {
        require(
            status == WorkflowStatus.VotesTallied,
            "Votes count is not yet done"
        );
    }

    /// @notice Throws if status the workflow is not followed .
    function _isConsistantStatus(WorkflowStatus _status) internal view {
        if (_status == WorkflowStatus.RegisteringVoters) {
            require(
                status == WorkflowStatus.RegisteringVoters ||
                    status == WorkflowStatus.ProposalsRegistrationStarted,
                "Actual status is not compatible with 'RegisteringVoters' (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.ProposalsRegistrationStarted) {
            require(
                status == WorkflowStatus.RegisteringVoters ||
                    status == WorkflowStatus.ProposalsRegistrationEnded,
                "Actual status is not compatible with 'ProposalsRegistrationStarted' (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.ProposalsRegistrationEnded) {
            require(
                status == WorkflowStatus.ProposalsRegistrationStarted ||
                    status == WorkflowStatus.VotingSessionStarted,
                "Actual status is not compatible with 'ProposalsRegistrationEnded' (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotingSessionStarted) {
            require(
                status == WorkflowStatus.ProposalsRegistrationEnded ||
                    status == WorkflowStatus.VotingSessionEnded,
                "Actual status is not compatible with 'VotingSessionStarted' (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotingSessionEnded) {
            require(
                status == WorkflowStatus.VotingSessionStarted ||
                    status == WorkflowStatus.VotesTallied,
                "Actual status is not compatible with 'VotingSessionEnded' (choose previous one or next one)"
            );
        } else if (_status == WorkflowStatus.VotesTallied) {
            require(
                status == WorkflowStatus.VotingSessionEnded,
                "Actual status is not compatible with 'VotesTallied' (choose previous one or next one)"
            );
        }
    }

    /// @notice Set RegisteringVoters status.
    function StartRegisteringVoters() external {
        setStatus(WorkflowStatus.RegisteringVoters);
    }

    /// @notice Set ProposalsRegistrationStarted status.
    function StartProposalsRegistration() external {
        setStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Set ProposalsRegistrationEnded status.
    function StopProposalsRegistration() external {
        setStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Set VotingSessionStarted status.
    function StartVotingSession() external {
        setStatus(WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Set VotingSessionEnded status.
    function StopVotingSession() external {
        setStatus(WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Register an new address to the whitelist.
    /// @param _voterAddress Address to add to the whitelist
    function registerVoter(address _voterAddress)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        require(
            whitelist[_voterAddress].isRegistered == false,
            "Voter is already whitelisted"
        );
        whitelist[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }

    /// @notice Register several new addresses to the whitelist.
    /// @param _votersAdresses Addresses to add to the whitelist
    /// @dev Already registered addresses are ignored
    function registerVoters(address[] memory _votersAdresses)
        external
        onlyOwner
        isRegisteringVotersStatus
    {
        for (uint256 i = 0; i < _votersAdresses.length; i++) {
            // ignore already registered addresses
            if (!whitelist[_votersAdresses[i]].isRegistered) {
                whitelist[_votersAdresses[i]].isRegistered = true;
                emit VoterRegistered(_votersAdresses[i]);
            }
        }
    }

    /// @notice Register a new proposal.
    /// @param _description Proposal description
    function registerProposal(string memory _description)
        external
        isWhitelisted
        isProposalsRegistrationStarted
    {
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    /// @notice set the current status.
    /// @param _status Status to set
    /// @dev include check status concistancy before setting the new status
    function setStatus(WorkflowStatus _status)
        internal
        onlyOwner
        isConsistantStatus(_status)
    {
        WorkflowStatus oldStatus = status;
        status = _status;
        emit WorkflowStatusChange(oldStatus, _status);
    }

    /// @notice Get all proposals
    /// @return Proposals array
    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    /// @notice execute a vote
    /// @param _proposalId Proposal id choosen by the voter
    function voting(uint256 _proposalId)
        external
        isVotingSessionStarted
        isWhitelisted
    {
        //check if Voter has already voted
        require(
            !whitelist[msg.sender].hasVoted,
            "You have already voted. Only one vote is allowed"
        );
        //check validity of proposal id
        require(
            _proposalId < proposals.length,
            "Proposal Id doesn't exist. Please select a valid proposal Id"
        );
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].votedProposalId = _proposalId;
        whitelist[msg.sender].hasVoted = true;
        emit Voted(msg.sender, _proposalId);
    }

    /// @notice Store the winning proposal id
    /// @dev Stored inside a contract variable to avoid to loop on the array many times during voters results consultation
    function discoverWinningProposal() external onlyOwner isVotingSessionEnded {
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

    /// @notice Get details of winning proposal
    /// @return proposal details
    function getWinningProposalDetails()
        external
        view
        isVotesTallied
        returns (Proposal memory)
    {
        return proposals[winningProposalId];
    }

    /// @notice Get details of winning proposal
    /// @param _address Address of a Voter
    /// @return description of the proposal chosen by the voter
    function getProposalVotedForUser(address _address)
        external
        view
        isWhitelisted
        returns (string memory)
    {
        require(whitelist[_address].hasVoted, "This user didn't vote");
        return proposals[whitelist[_address].votedProposalId].description;
    }
}
