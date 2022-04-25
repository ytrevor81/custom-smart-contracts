// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrevDAOExecutorTimeLock  {

    function submitProposal(uint256 _proposalID, uint256 _deadline) external;

    function checkProposalForDecision(uint256 _proposalID, uint256 _votesFor, uint256 _votesAgainst, bool _quorum) external;
}
