// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDeanDAOExecutorTimeLock.sol";
import "./IDeanDAO.sol";

contract DeanDAOExecutorTimeLock is IDeanDAOExecutorTimeLock {

  address private governor;
  address private deanDAOAddress;

  struct ProposalWithDeadLine {
    uint256 proposalID;
    uint256 deadline;
  }

  ProposalWithDeadLine[] proposalsWithADealine;

  event AssignedDAOAddress (address indexed _daoAddress);
  event AssignedGovernorAddress (address indexed _newGovernor);
  event NewProposalSubmitted (uint256 proposalID, uint256 deadline);

  constructor() {
    governor = msg.sender;
  }

  modifier onlyDeanDAO() {
    require(msg.sender == deanDAOAddress, "Only the DeanDAO contract can call this function");
    _;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor, "Only the governor contract can call this function");
    _;
  }

  function checkProposalForDecision(uint256 _proposalID, uint256 _votesFor, uint256 _votesAgainst, uint256 _numberOfVotes, uint256 _quorum) external onlyDeanDAO override {
    ProposalWithDeadLine memory proposal = proposalsWithADealine[_proposalID];

    if (proposal.deadline >= block.timestamp) {
      if (_numberOfVotes >= _quorum) {
        if (_votesFor <= _votesAgainst) {
          IDeanDAO(deanDAOAddress).proposalDefeated(proposal.proposalID);
        }
        else if (_votesFor > _votesAgainst) {
          IDeanDAO(deanDAOAddress).proposalExpired(proposal.proposalID);
        }
      }
      else {
        IDeanDAO(deanDAOAddress).proposalExpired(proposal.proposalID);
      }
    }
  }

  function submitProposal(uint256 _proposalID, uint256 _deadline) external override onlyDeanDAO {
    ProposalWithDeadLine memory proposal = ProposalWithDeadLine(_proposalID, _deadline);
    proposalsWithADealine.push(proposal);

    emit NewProposalSubmitted(proposal.proposalID, proposal.deadline);
  }

  function setGovernor(address _newGovernor) external onlyGovernor {
    governor = _newGovernor;
    emit AssignedGovernorAddress(_newGovernor);
  }

  function setDAOAddress(address _dao) external onlyGovernor {
    deanDAOAddress = _dao;
    emit AssignedDAOAddress(_dao);
  }
}
