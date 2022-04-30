// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrevToken.sol";

contract TrevDAO {

  address public trevTokenAddress;
  address public governor;
  uint256 public votingPeriod;

  uint256 private immutable valueOfEachVote;
  uint256 private proposalIDCounter;
  uint256 private quorum;

  enum ProposalState { Active, Defeated, Suceeded }

  struct Proposal {
    uint256 proposalID;
    string description; //change to bytes32 eventually
    address proposer;
    uint256 dateProposed;
    uint256 deadline;
  }

  Proposal[] proposals; //stored list of all proposals

  //voter address mapped to a mapping of proposal ID mapped to boolean
  mapping (address => mapping(uint256 => bool)) private voterAlreadyVoted;

  //proposal ID => state
  mapping (uint256 => ProposalState) public stateOfProposal;

  //proposal ID => numVotesFor
  mapping (uint256 => uint256) public votesForProposal;

  //proposal ID => numVotesAgainst
  mapping (uint256 => uint256) public votesAgainstProposal;

  //staker address mapped to a mapping of the amount invested mapped to the block time the investment was made
  mapping (address => mapping(uint256 => uint256)) public stakingTime;

  //staker address mapped to a uint256
  mapping (address => uint256) public stakingAmount;

  constructor (address _trevTokenAddress) {
    trevTokenAddress = _trevTokenAddress;
    governor = msg.sender;
    proposalIDCounter = 0;
    quorum = 2;
    votingPeriod = 2 minutes;
    valueOfEachVote = 1 * 10 ** 18; //1 token is 1 vote
  }

  event ProposalSubmitted (
    uint256 proposalID,
    string description,
    address proposer,
    uint256 deadline
    );

  event ProposalDefeated (
    uint256 proposalID,
    ProposalState state,
    string explanation
    );

  event ProposalSucceeded (
    uint256 proposalID,
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

  event GovernorRoleAssigned (address indexed _governor);
  event VotingPeriodChanged (uint256 newVotingPeriod);
  event QuorumChanged (uint256 newQuorum);

  /**
    * Modifiers
  **/

  //only allows the governor address
  modifier onlyGovernor() {
    require(msg.sender == governor, "Only the governor can call this function");
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

  function seeBalenceOfContract() external view returns (uint256) {
    uint256 currentBalence = TrevToken(trevTokenAddress).balanceOf(address(this));
    return currentBalence;
  }

  function alreadyVoted(uint256 proposalID) external view returns (bool) {
    address sender = msg.sender;
    return voterAlreadyVoted[sender][proposalID];
  }

  function proposalReachedDeadline(uint256 _proposalID) public view returns (bool) {
    Proposal memory proposal = proposals[_proposalID];

    if (block.timestamp > proposal.deadline) {
      return true;
    }

    return false;
  }

  /**
    * Voting functions:
  **/

  function voteAssignedToProposal(address voter, uint256 proposalID, bool support) internal {
    voterAlreadyVoted[voter][proposalID] = true; //cannot vote again

    if (support) {
      uint256 totalVotesForProposal = votesForProposal[proposalID];
      votesForProposal[proposalID] = totalVotesForProposal + 1;
    }
    else {
      uint256 totalVotesAgainstProposal = votesAgainstProposal[proposalID];
      votesAgainstProposal[proposalID] = totalVotesAgainstProposal + 1;
    }
  }

  function castVote(uint256 _proposalID, bool _support) external returns (bool) {
    address _sender = msg.sender;
    TrevToken token = TrevToken(trevTokenAddress);
    require(token.getBlackListStatus(_sender) == false, "User is blacklisted from TTK");
    require(proposalReachedDeadline(_proposalID) == false, "Proposal voting period has expired");
    require(voterAlreadyVoted[_sender][_proposalID] == false, "User has already voted on this proposal");
    require(token.balanceOf(_sender) > 0, "Only TrevToken holders can participate");

    token.transferFrom(_sender, address(this), valueOfEachVote);
    voteAssignedToProposal(_sender, _proposalID, _support);
    emit VoteSubmitted(_sender, _proposalID, _support);

    return true;
  }

  /**
    * Proposal functions:
  **/

  function submitProposal(string calldata _description) external returns (bool success) {
    address proposer = msg.sender;

    require(TrevToken(trevTokenAddress).getBlackListStatus(proposer) == false, "User is blacklisted from TTK");
    require(TrevToken(trevTokenAddress).balanceOf(proposer) > 0, "Only TrevToken holders can participate");

    uint256 deadline = block.timestamp + votingPeriod;
    uint256 dateProposed = block.timestamp;

    stateOfProposal[proposalIDCounter] = ProposalState.Active;

    Proposal memory newProposal = Proposal(proposalIDCounter, _description, proposer, dateProposed, deadline);
    proposals.push(newProposal);

    proposalIDCounter++;

    emit ProposalSubmitted(newProposal.proposalID, newProposal.description, newProposal.proposer, newProposal.deadline);

    return true;
  }

  function checkProposalForDecision(uint256 _proposalID) external onlyGovernor {
    require (stateOfProposal[_proposalID] == ProposalState.Active, "Proposal is not active.");
    require (proposalReachedDeadline(_proposalID) == true, "Proposal is still pending."); //time lock

    uint256 votesFor = votesForProposal[_proposalID];
    uint256 votesAgainst = votesAgainstProposal[_proposalID];
    uint256 totalNumOfVotes = votesFor + votesAgainst;

    if (totalNumOfVotes >= quorum) {
        if (votesFor <= votesAgainst) {
          stateOfProposal[_proposalID] = ProposalState.Defeated;
          emit ProposalDefeated(_proposalID, ProposalState.Defeated, "More votes against than for proposal.");
          return;
        }
        else if (votesFor > votesAgainst) {
          stateOfProposal[_proposalID] = ProposalState.Suceeded;
          emit ProposalSucceeded(_proposalID, ProposalState.Suceeded);
          return;
        }
    }
    else {
        stateOfProposal[_proposalID] = ProposalState.Defeated;
         emit ProposalDefeated(_proposalID, ProposalState.Defeated, "Proposal did not meet quorum.");
         return;
    }
  }

  /**
    * Staking functions
  **/

  function unstake() external returns (bool) {
    address sender = msg.sender;
    uint256 depositAmount = stakingAmount[sender];
    require(depositAmount > 0, "Not staking");

    uint256 depositTime = block.timestamp - stakingTime[sender][depositAmount];
    uint256 interest = depositAmount + depositTime;

    uint256 totalAmount = depositAmount + interest;
    TrevToken token = TrevToken(trevTokenAddress);

    token.mint(interest);
    token.transfer(msg.sender, totalAmount);

    stakingAmount[sender] = 0;
    emit Withdraw(sender, totalAmount);

    return true;
    }

  function stake(uint256 amount) external returns (bool) {
    address staker = msg.sender;
    require(stakingAmount[staker] == 0, "Just for the purpose of this demo, you can't add to your current stake");
    uint256 realAmount = amount * (10 ** 18);
    TrevToken token = TrevToken(trevTokenAddress);
    uint256 currentTime = block.timestamp;

    token.transferFrom(staker, address(this), realAmount);
    stakingAmount[staker] = realAmount;
    stakingTime[staker][realAmount] = currentTime;

    emit Staking(staker, realAmount, currentTime);
    return true;
  }

  /**
    * Role assigning functions:
    * the governor of this DAO protocal can assign the executor role via setExecutor() and transfer
    * the governor role to another address via assignNewGoverner().
  **/

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
