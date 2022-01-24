// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeanToken.sol"
import "@openzeppelin/contracts/utils/Timers.sol";
//need a quorum

contract DeanDAO {

  DeanToken public acceptedTokenAddress;
  address private governor;
  address private executor;

  enum ProposalState { Active, Cancelled, Defeated, Suceeded, Expired }

  struct Proposal {
    uint256 proposalID,
    string description,
  }

  constructor(DeanToken address _deanToken) {
    acceptedTokenAddress = _deanToken;
    governor = msg.sender;
  }

  mapping ()
  //event ProposalSubmitted
  //event ProposalCancelled
  //event ReturnVoteTokens
  //event ProposalExecuted
  //event ProposalExpired
  //event VoteSubmitted
  event ExecutorRoleAssigned (address indexed executor);



  modifier onlyDTKHolder() {
    require(DeanToken.balanceOf(msg.sender) > 0, "Only DeanToken holders can participate");
  }

  modifier onlyGovernor() {
    require(msg.send == governor, "Only the governor can call this function");
  }

  modifier onlyExecutor() {
    require(msg.send == executor, "Only the governor can call this function");
  }
  //Returns the governor address of the DAO
  function governor() public view returns (string memory) {
    return _governor;
  }

  //Returns the version number of the DAO protocal
  function version() external view returns (string memory) {
    return "1";
  }

  function castVote(uint256 _proposalID, bool _support, string callback _reason) external onlyDTKHolder return (uint256 balance) {
    //
  }

  function submitProposal(uint256 _proposalID, string calldata _description, uint256 deadline) {
    //
  }

  function cancelProposal(uint256 _proposalID) external onlyGovernor {
    //cancel proposal
    //return DTK tokens to voters -- multisend
    //emit ProposalCancelled
    //emit ReturnVoteTokens
  }

  function setExecutor (address _executor) external onlyGovernor {
    //the executor of proposals is a time-lock contract that will execute decisions based on if a proposal has met the required quorum, votes for/against
    executor = _executor;
    emit ExecutorRoleAssigned(_executor);
  }

  function assignNewGovernor (address _governor) external onlyGovernor {
    executor = _executor;
    emit ExecutorRoleAssigned(_executor);
  }



  function proposalDefeated() external onlyExecutor returns (bool) {

  }







}
