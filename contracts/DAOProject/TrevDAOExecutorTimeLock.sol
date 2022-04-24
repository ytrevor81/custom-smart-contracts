// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITrevDAOExecutorTimeLock.sol";
import "./ITrevDAO.sol";

contract TrevDAOExecutorTimeLock is ITrevDAOExecutorTimeLock {

  address private governor;
  address immutable trevDAOAddress;

  mapping (uint256 => uint256) private storedProposalDeadline; //proposal id mapped to block.timestamp deadline
  mapping (uint256 => bool) private approvedProposals;
  mapping (uint256 => bool)  private activeProposals;

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
    uint256 proposalDeadline = storedProposalDeadline[_proposalID];

    if (block.timestamp >= proposalDeadline) {
      if (_numberOfVotes >= _quorum) {
        if (_votesFor <= _votesAgainst) {
          activeProposals[_proposalID] = false;
          ITrevDAO(trevDAOAddress).proposalDefeated(_proposalID);
        }
        else if (_votesFor > _votesAgainst) {
          approvedProposals[_proposalID] = true;
          activeProposals[_proposalID] = false;
          ITrevDAO(trevDAOAddress).proposalSucceeded(_proposalID);
        }
      }
      else {
        activeProposals[_proposalID] = false;
        ITrevDAO(trevDAOAddress).proposalDefeated(_proposalID);
      }
    }
  }

  function submitProposal(uint256 _proposalID, uint256 _deadline) external override onlyTrevDAO {
    storedProposalDeadline[_proposalID] = _deadline;
    activeProposals[_proposalID] = true;

    emit NewProposalSubmitted(_proposalID, _deadline);
  }

  function isProposalActive(uint256 proposalID) external view returns (bool) {
    return activeProposals[proposalID];
  }

  function isProposalApproved(uint256 proposalID) external view returns (bool) {
    return approvedProposals[proposalID];
  }

  function setGovernor(address _newGovernor) external onlyGovernor {
    governor = _newGovernor;
    emit AssignedGovernorAddress(_newGovernor);
  }
}
