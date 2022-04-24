// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrevToken.sol";
import "./ITrevDAO.sol";
import "./ITrevDAOExecutorTimeLock.sol";

contract TrevDAO is ITrevDAO {

  address public trevTokenAddress;
  address public governor;
  address public executor;
  uint256 public votingPeriod;

  uint256 private immutable valueOfEachVote;
  uint256 private proposalIDCounter;
  uint256 private quorum;
  bool private executorContractSet; //switched only once in contract lifetime

  enum ProposalState { Active, Defeated, Suceeded }

  struct Proposal {
    uint256 proposalID;
    string description; //change to bytes32 eventually
    address proposer;
    address[] voters;
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

  //staker address mapped to a mapping of the amount invested mapped to the block time the investment was made
  mapping (address => mapping(uint256 => uint256)) public stakingTime;

  //staker address mapped to a uint256
  mapping (address => uint256) public stakingAmount;

  //proposal ID mapped to whether it has met the minimum amount of votes to be considered for execution
  mapping (uint256 => bool) private proposalMetQuorum;

  //returns how many votes in total a proposal has received
  mapping (uint256 => uint256) private numberOfVotesForProposal;

  constructor (address _trevTokenAddress) {
    trevTokenAddress = _trevTokenAddress;
    governor = msg.sender;
    proposalIDCounter = 0;
    quorum = 3;
    votingPeriod = 1 minutes;
    valueOfEachVote = 1 * 10 **18; //1 token is 1 vote
    executorContractSet = false;
  }

  event ProposalSubmitted (
    uint256 proposalID,
    string description,
    address proposer,
    uint256 deadline);

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

  event Staking (
    address staker,
    uint256 amount,
    uint256 timeStamp
    );

  event Withdraw (
    address staker,
    uint256 amount
    );

  event VoteSubmitted (
    address indexed voter,
    uint256 proposalID,
    bool support
    );

  event ExecutorRoleAssigned (address indexed _executor);
  event GovernorRoleAssigned (address indexed _governor);

  event VotingPeriodChanged (uint256 newVotingPeriod);
  event QuorumChanged (uint256 newQuorum);

  /**
    * Modifiers
  **/

  //only allows TTK holders
  modifier onlyTTKHolder() {
   require(TrevToken(trevTokenAddress).balanceOf(msg.sender) > 0, "Only TrevToken holders can participate");
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
    * Viewing states of the TrevDAO Protocal
  **/

  //Returns the name of the DAO protocal
  function name() external pure returns (string memory) {
    return "TrevDAO";
  }

  //Returns the version number of the DAO protocal
  function version() external pure returns (string memory) {
    return "1";
  }

  //Returns the state of a proposal
  function viewProposal(uint256 _proposalID) external view returns (Proposal memory) {
    Proposal memory proposal = proposals[_proposalID];
    return proposal;
  }

  //Returns a specific vote from a voter
  function viewVote(address _user) external view returns (Vote memory) {
    Vote memory vote = submittedVotes[_user];
    return vote;
  }

  function seeBalenceOfContract() external view returns (uint256) {
    uint256 currentBalence = TrevToken(trevTokenAddress).balanceOf(address(this));
    return currentBalence;
  }

  /**
    * Voting functions:
  **/

  function determineVoteForOrAgainst(Vote memory _vote) internal pure returns(bool) {
    return _vote.support;
  }

  function voterAlreadyVotedOnProposal(address _user) internal view returns (bool) {
    if (submittedVotes[_user].proposalID != 0) {
      return true;
    }

    return false;
  }

  function voteAssignedToProposal(Vote memory _vote) internal {
    Proposal memory proposal = proposals[_vote.proposalID];
    uint256 lengthOfPreviousVotersArray = proposal.voters.length;
    address[] memory updatedVotersArray = new address[](lengthOfPreviousVotersArray++);

    for (uint i=0; i < updatedVotersArray.length; i++) {
      if (i < lengthOfPreviousVotersArray) {
        updatedVotersArray[i] = proposal.voters[i];
      }
      else {
        updatedVotersArray[i] = _vote.voter;
      }
    }
    proposals[_vote.proposalID].voters = updatedVotersArray;

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

  function castVote(uint256 _proposalID, bool _support) external returns (bool) {
    address _sender = msg.sender;
    TrevToken token = TrevToken(trevTokenAddress);

    require(submittedVotes[_sender].voter != _sender, "User has already voted on this proposal");
    require(token.balanceOf(_sender) > 0, "Only TrevToken holders can participate");

    token.transferFrom(_sender, address(this), valueOfEachVote);

    Vote memory newVote = Vote(_sender, _proposalID, _support);
    submittedVotes[_sender] = newVote;
    voteAssignedToProposal(newVote);

    emit VoteSubmitted(newVote.voter, newVote.proposalID, newVote.support);
    return true;
  }

  /**
    * Proposal functions:
  **/

  function submitProposal(string calldata _description) external returns (bool success) {
    address proposer = msg.sender;
    require(TrevToken(trevTokenAddress).balanceOf(proposer) > 0, "Only TrevToken holders can participate");

    uint256 _deadline = block.timestamp + votingPeriod;
    uint256 dateProposed = block.timestamp;
    uint256 deadline = block.timestamp + _deadline;
    ProposalState state = ProposalState.Active;

    address[] memory _voters;

    Proposal memory newProposal = Proposal(proposalIDCounter, _description, proposer, _voters, 0, 0, 0, dateProposed, deadline, state);
    proposals.push(newProposal);

    proposalIDCounter++;

    ITrevDAOExecutorTimeLock(executor).submitProposal(newProposal.proposalID, newProposal.deadline);

    emit ProposalSubmitted(newProposal.proposalID, newProposal.description, newProposal.proposer, newProposal.deadline);

    return true;
  }

  function withdraw() external returns (bool) {
    address sender = msg.sender;
    uint256 depositAmount = stakingAmount[sender];
    require(depositAmount > 0, "Not staking");

    uint256 depositTime = block.timestamp - stakingTime[sender][depositAmount];

    // uint256 interestPerSecond = 100000000000000 * (stakingAmount[sender] / 1e16);
    // uint256 interest = interestPerSecond * depositTime;
    uint256 interest = depositAmount * depositTime;

    uint256 totalAmount = depositAmount + interest;
    TrevToken token = TrevToken(trevTokenAddress);

    token.mint(interest);
    token.transfer(msg.sender, totalAmount);

    stakingAmount[sender] = 0;
    emit Withdraw(sender, totalAmount);

    return true;

    }

  function stake(uint256 amount) public returns (bool) {
    address staker = msg.sender;
    require(stakingAmount[staker] == 0, "Just for the purpose of this demo, you can't add to your current stake");

    TrevToken token = TrevToken(trevTokenAddress);
    uint256 currentTime = block.timestamp;

    token.transferFrom(staker, address(this), amount);
    stakingAmount[staker] = amount;
    stakingTime[staker][amount] = currentTime;

    emit Staking(staker, amount, currentTime);
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

  function checkProposalForExecution(uint256 _proposalID) external onlyGovernor {
    Proposal memory proposal = proposals[_proposalID];
    require (proposal.state == ProposalState.Active, "Proposal is not active.");
    ITrevDAOExecutorTimeLock(executor).checkProposalForDecision(_proposalID, proposal.votesFor, proposal.votesAgainst, proposal.numberOfVotes, quorum);
  }

  /**
    * Role assigning functions:
    * the governor of this DAO protocal can assign the executor role via setExecutor() and transfer
    * the governor role to another address via assignNewGoverner().
  **/

  //the executor of proposals is a time-lock contract that will execute decisions based on if a proposal has met the required quorum, votes for/against
  function setExecutor (address _executor) external onlyGovernor {
    require(executorContractSet == false, "This can only be called once"); //this function can only be called one time in this contract's lifetime
    executorContractSet = true; //cannot call this function again
    executor = _executor; //time lock smart contract
    emit ExecutorRoleAssigned(_executor);
  }

  function assignNewGovernor (address _governor) external onlyGovernor {
    governor = _governor;
    emit GovernorRoleAssigned(_governor);
  }

  function changeVotingPeriod (uint256 _votingPeriod) external onlyGovernor {
    votingPeriod = _votingPeriod; //time lock smart contract
    emit VotingPeriodChanged(_votingPeriod);
  }

  function changeQuorum (uint256 _quorum) external onlyGovernor {
    quorum = _quorum; //time lock smart contract
    emit QuorumChanged(_quorum);
  }
}
