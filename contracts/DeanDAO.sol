// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeanToken.sol";
//need a quorum

contract DeanDAO {

  DeanToken public immutable acceptedTokenAddress;
  address private governor;
  address private executor;

  uint256 private proposalIDCounter;

  enum ProposalState { Active, Cancelled, Defeated, Suceeded, Expired }

  struct Proposal {
    uint256 proposalID,
    string description,
    address proposer,
    uint256 dateProposed,
    uint256 deadline,
    ProposalState state
  };

  struct Vote {
    address voter,
    uint256 proposalID,
    bool forOrAgainst,
  };

  Vote votes[];
  Proposal proposals[];

  constructor(DeanToken address _deanToken) {
    acceptedTokenAddress = _deanToken;
    governor = msg.sender;
    proposalIDCounter = 0;
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


  event ReturnVoteTokens (
    address[] indexed tokenHolderAddresses,
    uint256[] amountReturnedEach);

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
    bool forOrAgainst,
    string reason
    );

  event ExecutorRoleAssigned (address indexed _executor);
  event GovernorRoleAssigned (address indexed _governor);

  modifier onlyDTKHolder() {
    require(DeanToken.balanceOf(msg.sender) > 0, "Only DeanToken holders can participate");
  }

  modifier onlyGovernor() {
    require(msg.send == governor, "Only the governor can call this function");
  }

  modifier onlyExecutor() {
    require(msg.send == executor, "Only the executor can call this function");
  }

  //Returns the governor address of the DAO
  function governor() external view returns (string memory) {
    return _governor;
  }

  //Returns the version number of the DAO protocal
  function version() external pure returns (string memory) {
    return "1";
  }

  function castVote(uint256 _proposalID, bool _support, string calldata _reason) external onlyDTKHolder returns (uint256 balance) {
    //
    returns 0;
  }

  function submitProposal(string calldata _description, uint256 _deadline) external onlyDTKHolder returns (bool success) {
    address proposer = msg.sender;
    uint256 dateProposed = block.timestamp;
    uint256 deadline = block.timestamp + _deadline;
    ProposalState state = ProposalState.Active;

    Proposal newProposal = Proposal(proposalIDCounter, description, proposer, dateProposed, deadline, state);
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

  function proposalDefeated(uint256 _proposalID) external onlyExecutor {
    Proposal defeatedProposal = proposals[_proposalID];
    defeatedProposal.state = ProposalState.Defeated;

    emit ProposalDefeated(defeatedProposal.proposalID, defeatedProposal.description, defeatedProposal.state);
  }

  function proposalSucceeded() external onlyExecutor {
    Proposal succeededProposal = proposals[_proposalID];
    succeededProposal.state = ProposalState.;

    emit ProposalSucceeded(succeededProposal.proposalID, succeededProposal.description, succeededProposal.state);
  }

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
