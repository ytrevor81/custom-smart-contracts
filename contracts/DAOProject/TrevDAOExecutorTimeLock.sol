// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITrevDAOExecutorTimeLock.sol";
import "./ITrevDAO.sol";

contract TrevDAOExecutorTimeLock is ITrevDAOExecutorTimeLock {

  address private governor;
  address immutable trevDAOAddress;

  struct PendingProposal {
    uint256 proposalID;
    uint256 deadline;
  }

  PendingProposal[] private pendingProposals;

  event AssignedDAOAddress (address indexed _daoAddress);
  event AssignedGovernorAddress (address indexed _newGovernor);
  event NewProposalSubmitted (uint256 proposalID, uint256 deadline);

  constructor(address _trevDAOAddress) {
    trevDAOAddress = _trevDAOAddress;
    governor = msg.sender;
  }

  modifier onlyTrevDAO() {
    require(msg.sender == trevDAOAddress, "Only the TrevDAO contract can call this function");
    _;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor, "Only the governor contract can call this function");
    _;
  }

  function checkProposalForDecision(uint256 _proposalID, uint256 _votesFor, uint256 _votesAgainst, uint256 _numberOfVotes, uint256 _quorum) external onlyTrevDAO override {
    PendingProposal memory proposal = pendingProposals[_proposalID]; //proposal id works as the index of the array

    if (proposal.deadline >= block.timestamp) {
      if (_numberOfVotes >= _quorum) {
        if (_votesFor <= _votesAgainst) {
          ITrevDAO(trevDAOAddress).proposalDefeated(proposal.proposalID);
        }
        else if (_votesFor > _votesAgainst) {
          ITrevDAO(trevDAOAddress).proposalExpired(proposal.proposalID);
        }
      }
      else {
        ITrevDAO(trevDAOAddress).proposalExpired(proposal.proposalID);
      }
    }
  }

  function submitProposal(uint256 _proposalID, uint256 _deadline) external override onlyTrevDAO {
    PendingProposal memory proposal = PendingProposal(_proposalID, _deadline);
    pendingProposals.push(proposal);

    emit NewProposalSubmitted(proposal.proposalID, proposal.deadline);
  }

  function seePendingProposals() external view returns (PendingProposal[] memory) {
    return pendingProposals;
  }

  function setGovernor(address _newGovernor) external onlyGovernor {
    governor = _newGovernor;
    emit AssignedGovernorAddress(_newGovernor);
  }
}
