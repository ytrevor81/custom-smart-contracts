// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDeanDAO.sol";

contract DeanDAO is IDeanDAO {

  address public acceptedTokenAddress;
  string public _name = "DeanDAO";
  address public governor;
  address public executor;

  uint256 private immutable valueOfEachVote;
  uint256 private _amountOfDTK;
  uint256 private proposalIDCounter;
  uint256 private quorum;

  enum ProposalState { Active, Cancelled, Defeated, Suceeded, Expired }

  struct Proposal {
    uint256 proposalID;
    string description;
    address proposer;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 numberOfVotes;
    uint256 dateProposed;
    uint256 deadline;
    ProposalState state;
  }

  struct Vote {
    address voter;
    uint256 proposalID;
    bool support;
  }

  Vote[] votes;
  Proposal[] proposals;

  //address mapped to specific vote
  mapping (address => Vote) private submittedVotes;

  //proposal ID mapped to whether it has met the minimum amount of votes to be considered for execution
  mapping (uint256 => bool) private proposalMetQuorum;

  //returns how many votes in total a proposal has received
  mapping (uint256 => uint256) private numberOfVotesForProposal;

  constructor(address _deanTokenAddress, uint256 _quorum) {
    acceptedTokenAddress = _deanTokenAddress;
    governor = msg.sender;
    proposalIDCounter = 0;
    quorum = _quorum;
    valueOfEachVote = 1 * 10 **18; //1 token is 1 vote
  }

  event ProposalSubmitted (
    uint256 proposalID,
    string description,
    address proposer,
    uint256 deadline);

  event ProposalCancelled (
    uint256 proposalID,
    string description,
    ProposalState state
    );

  event ProposalDefeated (
    uint256 proposalID,
    string description,
    ProposalState state
    );

  event ProposalExecuted (
    uint256 proposalID,
    string description,
    ProposalState state
    );

  event ProposalExpired (
    uint256 proposalID,
    string description,
    ProposalState state
    );

  event VoteSubmitted (
    address indexed voter,
    uint256 proposalID,
    bool support,
    );

  event ReturnVoteTokens (
    address[] indexed tokenHolderAddresses,
    uint256[] amountOfDTKReturnedEach);

  event ExecutorRoleAssigned (address indexed _executor);
  event GovernorRoleAssigned (address indexed _governor);

  /**
    * Modifiers
  **/

  //only allows DTK holders
  modifier onlyDTKHolder() {
    require(IERC20(acceptedTokenAddress).balanceOf(msg.sender) > 0, "Only DeanToken holders can participate");
    _;
  }
  //only allows the governor address
  modifier onlyGovernor() {
    require(msg.sender == governor, "Only the governor can call this function");
    _;
  }

  //only allows the proposal executor address
  modifier onlyExecutor() {
    require(msg.sender == executor, "Only the executor can call this function");
    _;
  }

  /**
    * Viewing states of the DeanDAO Protocal
  **/

  //Returns the governor address of the DAO
  function name() public view returns (string memory) {
    return _name;
  }

  //Returns the amount of DTK tokens held by the contract
  function amountOfDTK() external view onlyGovernor returns (uint256) {
    return _amountOfDTK;
  }

  //Returns the version number of the DAO protocal
  function version() external pure returns (string memory) {
    return "1";
  }

  //Returns the state of a proposal
  function viewProposal(uint256 _proposalID) external view onlyDTKHolder returns (Proposal memory) {
    Proposal memory proposal = proposals[_proposalID];
    return proposal;
  }

  //Returns a specific vote from a voter
  function viewVote(address _user) external view onlyDTKHolder returns (Vote memory) {
    Vote memory vote = submittedVotes[_user];
    return vote;
  }

  /**
    * Voting functions:
  **/

  function determineVoteForOrAgainst(Vote memory _vote) internal pure returns(bool) {
    return _vote.support;
  }

  function voterAlreadyVotedOnProposal(address _user) internal returns (bool) {
    if (submittedVotes[_user].proposalID != 0) {
      return true;
    }
    return false;
  }

  function voteAssignedToProposal(Vote memory _vote) internal {
    proposals[_vote.proposalID].numberOfVotes = proposals[_vote.proposalID].numberOfVotes + 1;

    if (proposals[_vote.proposalID].numberOfVotes >= quorum) {
      proposalMetQuorum[proposals[_vote.proposalID].proposalID] = true;
    }

    if (_vote.support) {
      proposals[_vote.proposalID].votesFor = proposals[_vote.proposalID].votesFor + 1;
    }
    else {
      proposals[_vote.proposalID].votesAgainst = proposals[_vote.proposalID].votesAgainst + 1;
    }
  }

  function receiveVotingToken(address _sender) internal {
    IERC20(acceptedTokenAddress).transferFrom(_sender, address(this), valueOfEachVote);
    _amountOfDTK += valueOfEachVote;
  }

  function castVote(address tokenAddress, uint256 _proposalID, bool _support) external payable onlyDTKHolder returns (bool) {
    address _sender = msg.sender;
    require(tokenAddress == acceptedTokenAddress, "We only except Dean Tokens (DTK) for voting");
    require(msg.value == valueOfEachVote, "Only 1 DeanToken is excepted as a vote for or against a proposal");
    require(submittedVotes[_sender].voter != _sender, "User has already voted on this proposal");

    receiveVotingToken(_sender);

    Vote memory newVote = Vote(_sender, _proposalID, _support);
    submittedVotes[_sender] = newVote;
    voteAssignedToProposal(newVote);

    emit VoteSubmitted(newVote.voter, newVote.proposalID, newVote.support);
    return true;
  }

  /**
    * Proposal functions:
  **/

  function proposalHasMetQuorum(uint256 _proposalID) external view override returns (bool) {
    bool proposalCanConsidered = proposalMetQuorum[_proposalID];
    return proposalCanConsidered;
  }

  function submitProposal(string calldata _description, uint256 _deadline) external onlyDTKHolder returns (bool success) {
    address proposer = msg.sender;
    uint256 dateProposed = block.timestamp;
    uint256 deadline = block.timestamp + _deadline;
    ProposalState state = ProposalState.Active;

    Proposal memory newProposal = Proposal(proposalIDCounter, _description, proposer, dateProposed, deadline, state);
    proposals.push(newProposal);

    proposalIDCounter = proposalIDCounter + 1;
    emit ProposalSubmitted(newProposal.proposalID, newProposal.description, newProposal.proposer, newProposal.deadline);
    return true;
  }

  function cancelProposal(uint256 _proposalID) external onlyGovernor returns (bool success) {
    //cancel proposal
    //return DTK tokens to voters -- multisend
    //emit ProposalCancelled
    //emit ReturnVoteTokens
    return true;
  }

  function proposalDefeated(uint256 _proposalID) external onlyExecutor override returns (bool) {
    Proposal memory defeatedProposal = proposals[_proposalID];
    defeatedProposal.state = ProposalState.Defeated;

    emit ProposalDefeated(defeatedProposal.proposalID, defeatedProposal.description, defeatedProposal.state);
    return true;
  }

  function proposalSucceeded(uint256 _proposalID) external onlyExecutor override returns (bool) {
    Proposal memory succeededProposal = proposals[_proposalID];
    succeededProposal.state = ProposalState.Suceeded;

    emit ProposalExecuted(succeededProposal.proposalID, succeededProposal.description, succeededProposal.state);
    return true;
  }

  /**
    * Role assigning functions:
    * the governor of this DAO protocal can assign the executor role via setExecutor() and transfer
    * the governor role to another address via assignNewGoverner().
  **/

  //the executor of proposals is a time-lock contract that will execute decisions based on if a proposal has met the required quorum, votes for/against
  function setExecutor (address _executor) external onlyGovernor {
    executor = _executor; //time lock smart contract
    emit ExecutorRoleAssigned(_executor);
  }

  function assignNewGovernor (address _governor) external onlyGovernor {
    governor = _governor;
    emit GovernorRoleAssigned(_governor);
  }
}
