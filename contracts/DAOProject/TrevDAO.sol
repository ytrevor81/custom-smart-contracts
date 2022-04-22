// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrevToken.sol";
import "./ITrevDAO.sol";
import "./ITrevDAOExecutorTimeLock.sol";

contract TrevDAO is ITrevDAO {

  address public trevTokenAddress;
  string public _name = "TrevDAO";
  address public governor;
  address public executor;


  uint256 public votingPeriod;
  uint256 private immutable valueOfEachVote;
  uint256 private _amountOfTTK;
  uint256 private proposalIDCounter;
  uint256 private quorum;

  bool private executorContractSet;

  enum ProposalState { Active, Cancelled, Defeated, Suceeded }

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

  struct Stake {
    address voter;
    uint256 amount;
    bool currentlyStaking;
  }

  Vote[] votes;
  Proposal[] proposals;
  Stake[] staking;

  //address mapped to specific vote
  mapping (address => Vote) private submittedVotes;

  //staking mapped to specific address
  mapping (address => bool) private currentlyStaking;

  //proposal ID mapped to whether it has met the minimum amount of votes to be considered for execution
  mapping (uint256 => bool) private proposalMetQuorum;

  //returns how many votes in total a proposal has received
  mapping (uint256 => uint256) private numberOfVotesForProposal;

  constructor (address _trevTokenAddress) {
    trevTokenAddress = _trevTokenAddress;
    governor = msg.sender;
    proposalIDCounter = 0;
    quorum = 3;
    votingPeriod = 3 minutes;
    valueOfEachVote = 1 * 10 **18; //1 token is 1 vote
    executorContractSet = false;
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

  event Staking (
    address staker,
    uint256 amount
    );

  event VoteSubmitted (
    address indexed voter,
    uint256 proposalID,
    bool support
    );

  event ReturnVoteTokens (address[] indexed tokenHolderAddresses);

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

  //Returns the amount of TTK tokens held by the contract
  function amountOfTTK() external view onlyGovernor returns (uint256) {
    return _amountOfTTK;
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

  function receiveVotingToken(address _sender) internal {
    IERC20(trevTokenAddress).transferFrom(_sender, address(this), valueOfEachVote);
    _amountOfTTK += valueOfEachVote;
  }

  function castVote(address tokenAddress, uint256 _proposalID, bool _support) external returns (bool) {
    address _sender = msg.sender;
    //require(tokenAddress == trevTokenAddress, "We only except Trev Tokens (TTK) for voting");
    //require(msg.value == valueOfEachVote, "Only 1 TrevToken is excepted as a vote for or against a proposal");
    require(submittedVotes[_sender].voter != _sender, "User has already voted on this proposal");
    require(IERC20(trevTokenAddress).balanceOf(_sender) > 0, "Only TrevToken holders can participate");

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

  function submitProposal(string calldata _description) external returns (bool success) {
    require(IERC20(trevTokenAddress).balanceOf(msg.sender) > 0, "Only TrevToken holders can participate");
    uint256 _deadline = block.timestamp + votingPeriod;
    address proposer = msg.sender;
    uint256 dateProposed = block.timestamp;
    uint256 deadline = block.timestamp + _deadline;
    ProposalState state = ProposalState.Active;

    address[] memory _voters;

    Proposal memory newProposal = Proposal(proposalIDCounter, _description, proposer, _voters, 0, 0, 0, dateProposed, deadline, state);
    proposals.push(newProposal);

    proposalIDCounter = proposalIDCounter + 1;

    ITrevDAOExecutorTimeLock(executor).submitProposal(newProposal.proposalID, newProposal.deadline);

    emit ProposalSubmitted(newProposal.proposalID, newProposal.description, newProposal.proposer, newProposal.deadline);

    return true;
  }

  // function withdraw(uint256 amount) external {
  //   require(currentlyStaking[msg.sender] == true, "Not staking");
  //   uint256 totalAmount = amount + 100;

  //   TrevToken token = TrevToken(trevTokenAddress);
  //   token.mint(address(this), 100);
  //   token.transfer(msg.sender, totalAmount);
  //   // token.transfer(address(this), amount);
  //   // currentlyStaking[_sender] = true;
  //   // _amountOfTTK += amount;
  //   //token.increaseAllowance(address(this), amount);
  //   }

  function stakeNow(uint256 amount) public {
    address staker = msg.sender;
    TrevToken token = TrevToken(trevTokenAddress);
    token.transferFrom(staker, address(this), amount);
    currentlyStaking[staker] = true;
    emit Staking(staker, amount);
  }

  function seeBalenceOfContract() external view returns (uint256) {
    uint256 currentBalence = TrevToken(trevTokenAddress).balanceOf(address(this));
    return currentBalence;
  }

  function cancelProposal(uint256 _proposalID) external onlyGovernor returns (bool success) {
    Proposal memory proposal = proposals[_proposalID];
    require (proposal.state == ProposalState.Active, "Proposal is not active.");
    proposals[_proposalID].state = ProposalState.Cancelled;

    emit ProposalCancelled (proposal.proposalID, proposal.description, ProposalState.Cancelled);
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
