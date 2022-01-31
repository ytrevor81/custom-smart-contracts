// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeanDAOExecutorTimeLock  {

    function submitProposal(uint256 _proposalID, uint256 _deadline) external;

    function checkProposalForDecision(uint256 _proposalID, uint256 _votesFor, uint256 _votesAgainst, uint256 _numberOfVotes, uint256 _quorum) external;
}
